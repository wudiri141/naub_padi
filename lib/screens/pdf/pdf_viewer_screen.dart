import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:photo_view/photo_view.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

import '../../core/routes/app_routes.dart';
import '../../core/services/app_settings_controller.dart';
import '../../core/utils/user_facing_message.dart';
import '../../models/question_paper_model.dart';
import '../../services/api_service.dart';
import '../../services/pdf_service.dart';
import '../../widgets/common/app_card.dart';
import '../../widgets/common/app_empty_state.dart';
import '../../widgets/common/app_error_state.dart';
import '../../widgets/common/download_progress_dialog.dart';
import '../../widgets/question_papers/question_paper_metadata.dart';

class PdfViewerScreen extends StatefulWidget {
  const PdfViewerScreen({
    super.key,
    required this.paper,
    this.localPath,
  });

  final QuestionPaperModel paper;
  final String? localPath;

  @override
  State<PdfViewerScreen> createState() => _PdfViewerScreenState();
}

class _PdfViewerScreenState extends State<PdfViewerScreen> {
  final PdfViewerController _pdfController = PdfViewerController();
  bool _isDownloading = false;
  double _downloadProgress = 0;
  String? _downloadedPath;
  String? _loadError;
  bool _isLoaded = false;
  int _pageNumber = 1;
  int _pageCount = 0;
  int _reloadToken = 0;

  String get _sourceUrl => PdfService.instance.resolvePaperUrl(widget.paper);

  String? get _localPath => widget.localPath ?? _downloadedPath;

  bool get _isPdf => widget.paper.isPdf;

  bool get _isImage => widget.paper.isImage;

  @override
  void dispose() {
    _pdfController.dispose();
    super.dispose();
  }

  Future<void> _download() async {
    if (_isDownloading) return;

    setState(() {
      _isDownloading = true;
      _downloadProgress = 0;
    });

    try {
      final result = await runDownloadWithProgress(
        context: context,
        title: 'Downloading paper',
        action: (updateProgress) => PdfService.instance.downloadPaper(
          widget.paper,
          onReceiveProgress: (received, total) {
            if (!mounted || total <= 0) return;
            final progress = received / total;
            updateProgress(progress);
            setState(() => _downloadProgress = progress);
          },
        ),
      );

      if (!mounted) return;

      setState(() {
        _isDownloading = false;
        _downloadProgress = 0;
        _downloadedPath = result.path;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.alreadyExists ? 'File already downloaded.' : 'File downloaded successfully.'),
          action: SnackBarAction(
            label: 'Open',
            onPressed: () {
              context.push(
                AppRoutes.pdfViewer,
                extra: PdfViewerRouteArgs(widget.paper, localPath: result.path),
              );
            },
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isDownloading = false;
        _downloadProgress = 0;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(friendlyErrorMessage(error, fallback: 'Unable to download this paper. Please try again later.'))),
      );
    }
  }

  Future<void> _bookmark() async {
    final settings = context.read<AppSettingsController>();
    if (!settings.isSignedIn || settings.userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sign in to save papers.')),
      );
      return;
    }

    try {
      await ApiService.instance.bookmark(userId: settings.userId!, paperId: widget.paper.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${widget.paper.displayCourseCode} saved to your shelf.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(friendlyErrorMessage(error, fallback: 'Unable to save this paper. Please try again later.'))),
      );
    }
  }

  void _zoomIn() {
    if (_isPdf) {
      _pdfController.zoomLevel = ((_pdfController.zoomLevel + 1).clamp(1.0, 5.0)).toDouble();
    }
  }

  void _zoomOut() {
    if (_isPdf) {
      _pdfController.zoomLevel = ((_pdfController.zoomLevel - 1).clamp(1.0, 5.0)).toDouble();
    }
  }

  void _markLoaded({int? pageCount}) {
    setState(() {
      _isLoaded = true;
      _loadError = null;
      _pageCount = pageCount ?? _pageCount;
      _pageNumber = _pdfController.pageNumber <= 0 ? 1 : _pdfController.pageNumber;
    });
  }

  Future<void> _searchPdf() async {
    final queryController = TextEditingController();
    final query = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Search PDF'),
          content: TextField(
            controller: queryController,
            autofocus: true,
            decoration: const InputDecoration(
              hintText: 'Enter text to find',
              prefixIcon: Icon(Icons.search_rounded),
            ),
            textInputAction: TextInputAction.search,
            onSubmitted: (value) => Navigator.of(dialogContext).pop(value.trim()),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(queryController.text.trim()),
              child: const Text('Search'),
            ),
          ],
        );
      },
    );
    queryController.dispose();

    if (query == null || query.isEmpty) {
      return;
    }
    _pdfController.searchText(query);
  }

  void _previousPage() {
    if (_pageNumber > 1) {
      _pdfController.previousPage();
    }
  }

  void _nextPage() {
    if (_pageCount == 0 || _pageNumber < _pageCount) {
      _pdfController.nextPage();
    }
  }

  void _markError(String message) {
    setState(() {
      _loadError = message;
      _isLoaded = false;
    });
  }

  Widget _buildPdfViewer() {
    final localPath = _localPath;
    final theme = Theme.of(context);

    if (_sourceUrl.isEmpty && localPath == null) {
      return const AppEmptyState(
        icon: Icons.picture_as_pdf_rounded,
        title: 'Preview unavailable',
        message: 'This paper does not have a valid file attached.',
      );
    }

    final viewer = localPath != null
        ? SfPdfViewer.file(
            File(localPath),
            controller: _pdfController,
            canShowScrollHead: true,
            onDocumentLoaded: (details) => _markLoaded(pageCount: details.document.pages.count),
            onPageChanged: (details) => setState(() => _pageNumber = details.newPageNumber),
            onDocumentLoadFailed: (details) => _markError(friendlyErrorMessage(details.error, fallback: 'Unable to load PDF. Please try again later.')),
          )
        : SfPdfViewer.network(
            _sourceUrl,
            controller: _pdfController,
            canShowScrollHead: true,
            onDocumentLoaded: (details) => _markLoaded(pageCount: details.document.pages.count),
            onPageChanged: (details) => setState(() => _pageNumber = details.newPageNumber),
            onDocumentLoadFailed: (details) => _markError(friendlyErrorMessage(details.error, fallback: 'Unable to load PDF. Please try again later.')),
          );

    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Container(
            color: theme.colorScheme.surface,
            child: KeyedSubtree(
              key: ValueKey<String>('$_reloadToken-${localPath ?? _sourceUrl}'),
              child: viewer,
            ),
          ),
        ),
        if (!_isLoaded && _loadError == null)
          const Positioned.fill(
            child: Center(
              child: CircularProgressIndicator(),
            ),
          ),
        if (_loadError != null)
          Positioned.fill(
            child: Container(
              color: theme.colorScheme.surface,
              child: AppErrorState(
                title: 'Unable to load PDF',
                message: _loadError!,
                onRetry: () {
                  setState(() {
                    _loadError = null;
                    _isLoaded = false;
                    _reloadToken++;
                  });
                },
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildImageViewer() {
    final localPath = _localPath;
    final url = _sourceUrl;

    if (localPath == null && url.isEmpty) {
      return const AppEmptyState(
        icon: Icons.broken_image_outlined,
        title: 'Preview unavailable',
        message: 'This image does not have a valid file attached.',
      );
    }

    final ImageProvider provider = localPath != null
        ? FileImage(File(localPath))
        : NetworkImage(url);

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Container(
        color: Theme.of(context).colorScheme.surface,
        child: KeyedSubtree(
          key: ValueKey<String>('$_reloadToken-${localPath ?? url}'),
          child: Stack(
            children: [
              Positioned.fill(
                child: PhotoView(
                  imageProvider: provider,
                  backgroundDecoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                  ),
                  minScale: PhotoViewComputedScale.contained,
                  maxScale: PhotoViewComputedScale.covered * 3.0,
                  initialScale: PhotoViewComputedScale.contained,
                  loadingBuilder: (context, event) {
                    if (event == null) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final value = event.expectedTotalBytes == null
                        ? null
                        : event.cumulativeBytesLoaded / event.expectedTotalBytes!;
                    return Center(
                      child: SizedBox(
                        width: 220,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            LinearProgressIndicator(value: value),
                            const SizedBox(height: 12),
                            Text(
                              value == null
                                  ? 'Loading image...'
                                  : 'Loading ${(value * 100).toStringAsFixed(0)}%',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) => AppErrorState(
                    title: 'Unable to load image',
                    message: 'The image could not be retrieved from the server. Please try again.',
                    onRetry: () {
                      setState(() {
                        _reloadToken++;
                      });
                    },
                  ),
                ),
              ),
              Positioned(
                top: 12,
                right: 12,
                child: Material(
                  color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.92),
                  borderRadius: BorderRadius.circular(14),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.touch_app_rounded, size: 16),
                        SizedBox(width: 6),
                        Text('Pinch to zoom'),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.paper.displayCourseCode;
    final subtitle = widget.paper.title;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        titleSpacing: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ],
        ),
        actions: [
          if (_isPdf) ...[
            IconButton(
              tooltip: 'Zoom out',
              onPressed: _zoomOut,
              icon: const Icon(Icons.zoom_out_rounded),
            ),
            IconButton(
              tooltip: 'Zoom in',
              onPressed: _zoomIn,
              icon: const Icon(Icons.zoom_in_rounded),
            ),
            IconButton(
              tooltip: 'Search PDF',
              onPressed: _searchPdf,
              icon: const Icon(Icons.search_rounded),
            ),
          ],
        ],
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            if (_isDownloading)
              LinearProgressIndicator(value: _downloadProgress <= 0 ? null : _downloadProgress),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
              child: AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            widget.paper.displayCourseCode,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        IconButton(
                          tooltip: 'Save',
                          onPressed: _bookmark,
                          icon: const Icon(Icons.bookmark_border_rounded),
                        ),
                        IconButton(
                          tooltip: 'Download',
                          onPressed: _isDownloading ? null : _download,
                          icon: const Icon(Icons.download_rounded),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.paper.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 10),
                    QuestionPaperMetadata(paper: widget.paper),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Icon(
                          _isPdf
                              ? Icons.picture_as_pdf_rounded
                              : Icons.image_outlined,
                          size: 18,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 7),
                        Expanded(
                          child: Text(
                            widget.paper.displayFileName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                        if (_localPath != null)
                          const Text(
                            'Downloaded',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Column(
                  children: [
                    if (_isPdf)
                      Align(
                        alignment: Alignment.centerRight,
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Wrap(
                            spacing: 6,
                            children: [
                              OutlinedButton.icon(
                                onPressed: _zoomOut,
                                icon: const Icon(Icons.remove_rounded, size: 18),
                                label: const Text('Zoom out'),
                              ),
                              OutlinedButton.icon(
                                onPressed: _zoomIn,
                                icon: const Icon(Icons.add_rounded, size: 18),
                                label: const Text('Zoom in'),
                              ),
                              OutlinedButton.icon(
                                onPressed: _searchPdf,
                                icon: const Icon(Icons.search_rounded, size: 18),
                                label: const Text('Search'),
                              ),
                              IconButton(
                                tooltip: 'Previous page',
                                onPressed: _previousPage,
                                icon: const Icon(Icons.chevron_left_rounded),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
                                child: Text(
                                  _pageCount == 0 ? 'Page $_pageNumber' : '$_pageNumber / $_pageCount',
                                  style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800),
                                ),
                              ),
                              IconButton(
                                tooltip: 'Next page',
                                onPressed: _nextPage,
                                icon: const Icon(Icons.chevron_right_rounded),
                              ),
                            ],
                          ),
                        ),
                      ),
                    Expanded(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        child: _isPdf
                            ? _buildPdfViewer()
                            : _isImage
                                ? _buildImageViewer()
                                : const AppEmptyState(
                                    icon: Icons.insert_drive_file_outlined,
                                    title: 'Unsupported file',
                                    message: 'This paper cannot be previewed inline.',
                                  ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
