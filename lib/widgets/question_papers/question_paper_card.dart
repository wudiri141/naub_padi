import 'package:flutter/material.dart';

import '../../models/question_paper_model.dart';
import '../../services/pdf_service.dart';
import '../common/app_card.dart';
import 'question_paper_metadata.dart';

class QuestionPaperCard extends StatelessWidget {
  const QuestionPaperCard({
    super.key,
    required this.paper,
    required this.onOpen,
    this.onBookmark,
    this.onDownload,
    this.onShare,
  });

  final QuestionPaperModel paper;
  final VoidCallback onOpen;
  final VoidCallback? onBookmark;
  final VoidCallback? onDownload;
  final VoidCallback? onShare;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pdfService = PdfService.instance;
    final isImage = paper.isImage;

    return AppCard(
      onTap: onOpen,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _PreviewThumb(
                paper: paper,
                isImage: isImage,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      paper.displayCourseCode,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      paper.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          QuestionPaperMetadata(paper: paper),
          const SizedBox(height: 10),
          Text(
            paper.uploaderName != null && paper.uploaderName!.isNotEmpty ? 'Uploaded by ${paper.uploaderName}' : 'Uploaded via NAUB Padi',
            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              TextButton.icon(
                onPressed: onOpen,
                icon: const Icon(Icons.visibility_outlined, size: 16),
                label: const Text('Open'),
              ),
              TextButton.icon(
                onPressed: onDownload,
                icon: const Icon(Icons.download_outlined, size: 16),
                label: const Text('Download'),
              ),
              TextButton.icon(
                onPressed: onBookmark,
                icon: const Icon(Icons.bookmark_border_outlined, size: 16),
                label: const Text('Save'),
              ),
              TextButton.icon(
                onPressed: onShare,
                icon: const Icon(Icons.share_outlined, size: 16),
                label: const Text('Share'),
              ),
              if (pdfService.canPreviewInline(paper))
                TextButton.icon(
                  onPressed: onOpen,
                  icon: const Icon(Icons.open_in_new_rounded, size: 16),
                  label: const Text('Preview'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PreviewThumb extends StatelessWidget {
  const _PreviewThumb({
    required this.paper,
    required this.isImage,
  });

  final QuestionPaperModel paper;
  final bool isImage;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final url = PdfService.instance.resolvePaperUrl(paper);

    if (isImage && url.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Image.network(
          url,
          width: 54,
          height: 54,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => _fallback(theme),
        ),
      );
    }

    return _fallback(theme);
  }

  Widget _fallback(ThemeData theme) {
    return Container(
      width: 54,
      height: 54,
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: theme.brightness == Brightness.dark ? 0.18 : 0.10),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(
        paper.isPdf ? Icons.picture_as_pdf_rounded : Icons.description_outlined,
        color: theme.colorScheme.primary,
      ),
    );
  }
}
