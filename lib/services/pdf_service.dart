import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import '../core/constants/app_constants.dart';
import '../models/question_paper_model.dart';

class PaperDownloadResult {
  const PaperDownloadResult({
    required this.path,
    required this.alreadyExists,
  });

  final String path;
  final bool alreadyExists;
}

class PdfService {
  PdfService._({Dio? dio}) : _dio = dio ?? Dio();

  static final PdfService instance = PdfService._();

  final Dio _dio;

  String resolvePaperUrl(QuestionPaperModel paper) {
    final publicUrl = _publicPaperUrl(paper);
    if (publicUrl.isNotEmpty) {
      return publicUrl;
    }

    if (paper.id <= 0) {
      return '';
    }

    final base = const String.fromEnvironment(
      AppConstants.apiBaseUrlEnvironmentKey,
      defaultValue: AppConstants.fallbackApiBaseUrl,
    ).replaceAll(RegExp(r'/$'), '');

    return '$base/file.php?id=${paper.id}';
  }

  bool canPreviewInline(QuestionPaperModel paper) {
    return paper.isPdf || paper.isImage;
  }

  String downloadFileNameFor(QuestionPaperModel paper) => _downloadFileName(paper);

  Future<PaperDownloadResult> downloadPaper(
    QuestionPaperModel paper, {
    void Function(int received, int total)? onReceiveProgress,
  }) async {
    if (kIsWeb) {
      throw Exception('File downloads are not available in the web build.');
    }

    final url = resolvePaperUrl(paper);
    if (url.isEmpty) {
      throw Exception('No file attached to this paper.');
    }

    final directory = await _downloadDirectory();
    await directory.create(recursive: true);

    final baseFileName = _downloadFileName(paper);
    final savePath = await _uniqueSavePath(directory, baseFileName);
    final alreadyExists = savePath != '${directory.path}/$baseFileName';

    await _dio.download(
      url,
      savePath,
      onReceiveProgress: onReceiveProgress,
      options: Options(
        responseType: ResponseType.bytes,
        followRedirects: true,
        validateStatus: (status) => status != null && status >= 200 && status < 400,
      ),
    );
    return PaperDownloadResult(path: savePath, alreadyExists: alreadyExists);
  }

  Future<Directory> _downloadDirectory() async {
    if (!kIsWeb && Platform.isAndroid) {
      final external = await getExternalStorageDirectory();
      if (external != null) {
        return Directory('${external.path}/NAUB Padi');
      }
    }

    final documents = await getApplicationDocumentsDirectory();
    return Directory('${documents.path}/NAUB Padi');
  }

  Future<String> _uniqueSavePath(Directory directory, String fileName) async {
    final target = File('${directory.path}/$fileName');
    if (!await target.exists()) {
      return target.path;
    }

    final extension = _fileExtension(fileName);
    final stem = extension.isEmpty
        ? fileName
        : fileName.substring(0, fileName.length - extension.length);

    var index = 1;
    while (true) {
      final candidate = File('${directory.path}/$stem ($index)$extension');
      if (!await candidate.exists()) {
        return candidate.path;
      }
      index += 1;
    }
  }

  String _downloadFileName(QuestionPaperModel paper) {
    final parts = <String>[
      paper.facultyCode,
      paper.departmentName,
      paper.level,
      if (paper.courseCode != null && paper.courseCode!.trim().isNotEmpty) paper.courseCode!.trim(),
      if (paper.title.trim().isNotEmpty) paper.title.trim(),
      if (paper.sessionLabel.trim().isNotEmpty) paper.sessionLabel.trim(),
    ];

    final stem = parts
        .map(_sanitizeNamePart)
        .where((part) => part.isNotEmpty)
        .join('_');

    final extension = _fileExtensionFor(paper);
    final fallback = _sanitizeNamePart(
      paper.fileName?.trim().isNotEmpty == true ? paper.fileName!.trim() : 'question_paper',
    );

    final candidate = stem.isEmpty ? fallback : stem;
    final truncated = candidate.length > 160 ? candidate.substring(0, 160) : candidate;
    return truncated.endsWith(extension) ? truncated : '$truncated$extension';
  }

  String _fileExtension(String value) {
    final dotIndex = value.lastIndexOf('.');
    if (dotIndex <= 0 || dotIndex == value.length - 1) {
      return '';
    }
    return value.substring(dotIndex);
  }

  String _fileExtensionFor(QuestionPaperModel paper) {
    final source = (paper.fileName ?? paper.filePath ?? '').toLowerCase();
    if (source.endsWith('.pdf') || paper.isPdf) {
      return '.pdf';
    }
    if (source.endsWith('.png')) {
      return '.png';
    }
    if (source.endsWith('.webp')) {
      return '.webp';
    }
    if (source.endsWith('.jpeg') || source.endsWith('.jpg') || paper.fileMime?.contains('jpeg') == true) {
      return '.jpg';
    }
    if (paper.fileMime?.contains('png') == true) {
      return '.png';
    }
    if (paper.isImage) {
      return '.jpg';
    }
    return '.bin';
  }

  String _sanitizeNamePart(String value) {
    final cleaned = value.trim().replaceAll(RegExp(r'[^A-Za-z0-9]+'), '_');
    return cleaned.replaceAll(RegExp(r'_+'), '_').replaceAll(RegExp(r'^_|_$'), '');
  }

  String _publicPaperUrl(QuestionPaperModel paper) {
    final relativePath = _normalizedPaperPath(paper.filePath);
    if (relativePath.isEmpty) {
      return '';
    }

    if (relativePath.startsWith('http://') || relativePath.startsWith('https://')) {
      return relativePath;
    }

    final base = const String.fromEnvironment(
      AppConstants.apiBaseUrlEnvironmentKey,
      defaultValue: AppConstants.fallbackApiBaseUrl,
    ).replaceAll(RegExp(r'/$'), '');
    final siteRoot = base.replaceFirst(RegExp(r'/api/?$'), '');
    if (siteRoot.isEmpty) {
      return '';
    }

    final cleanPath = relativePath.replaceFirst(RegExp(r'^/+'), '');
    if (cleanPath.isEmpty) {
      return '';
    }

    return '$siteRoot/$cleanPath';
  }

  String _normalizedPaperPath(String? path) {
    final value = path?.trim() ?? '';
    if (value.isEmpty) {
      return '';
    }

    final normalized = value.replaceAll('\\', '/').replaceAll(RegExp(r'^/+'), '');
    if (normalized.startsWith('uploads/')) {
      return normalized;
    }
    if (normalized.startsWith('http://') || normalized.startsWith('https://')) {
      return normalized;
    }
    if (_hasFileExtension(normalized)) {
      return 'uploads/$normalized';
    }
    return normalized;
  }

  bool _hasFileExtension(String value) {
    final dotIndex = value.lastIndexOf('.');
    return dotIndex > 0 && dotIndex < value.length - 1;
  }
}
