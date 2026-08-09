import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/routes/app_routes.dart';
import '../../core/services/app_settings_controller.dart';
import '../../core/utils/user_facing_message.dart';
import '../../models/question_paper_model.dart';
import '../../services/api_service.dart';
import '../../services/pdf_service.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/app_empty_state.dart';
import '../../widgets/common/app_error_state.dart';
import '../../widgets/common/app_loading.dart';
import '../../widgets/common/app_page_scaffold.dart';
import '../../widgets/common/download_progress_dialog.dart';
import '../../widgets/question_papers/question_paper_card.dart';

class SavedScreen extends StatefulWidget {
  const SavedScreen({
    super.key,
    required this.onBrowseTap,
    required this.onSignInTap,
  });

  final VoidCallback onBrowseTap;
  final VoidCallback onSignInTap;

  @override
  State<SavedScreen> createState() => _SavedScreenState();
}

class _SavedScreenState extends State<SavedScreen> {
  Future<List<QuestionPaperModel>>? _future;
  int? _loadedUserId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final settings = context.watch<AppSettingsController>();
    if (settings.isSignedIn && settings.userId != null && _loadedUserId != settings.userId) {
      _loadedUserId = settings.userId;
      _future = ApiService.instance.savedPapers(userId: settings.userId!);
    }
  }

  Future<void> _refresh() async {
    final settings = context.read<AppSettingsController>();
    if (!settings.isSignedIn || settings.userId == null) {
      setState(() => _future = null);
      _loadedUserId = null;
      return;
    }

    setState(() {
      _future = ApiService.instance.savedPapers(userId: settings.userId!);
      _loadedUserId = settings.userId;
    });
  }

  Future<void> _removeBookmark(QuestionPaperModel paper) async {
    final settings = context.read<AppSettingsController>();
    if (!settings.isSignedIn || settings.userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sign in to manage saved papers.')),
      );
      return;
    }

    try {
      await ApiService.instance.bookmark(userId: settings.userId!, paperId: paper.id, remove: true);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${paper.displayCourseCode} removed from your shelf.')),
      );
      await _refresh();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(friendlyErrorMessage(error, fallback: 'Unable to remove this paper right now.'))),
      );
    }
  }

  Future<void> _downloadPaper(QuestionPaperModel paper) async {
    try {
      final result = await runDownloadWithProgress(
        context: context,
        title: 'Downloading paper',
        action: (updateProgress) => PdfService.instance.downloadPaper(
          paper,
          onReceiveProgress: (received, total) {
            if (total > 0) {
              updateProgress(received / total);
            }
          },
        ),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.alreadyExists ? 'File already downloaded.' : 'Downloaded successfully.'),
          action: SnackBarAction(
            label: 'Open',
            onPressed: () {
              context.push(AppRoutes.pdfViewer, extra: PdfViewerRouteArgs(paper, localPath: result.path));
            },
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(friendlyErrorMessage(error, fallback: 'Unable to download this paper. Please try again later.'))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<AppSettingsController>();

    return AppPageScaffold(
      title: 'Saved',
      subtitle: 'Your bookmarked question papers',
      heroColor: Theme.of(context).colorScheme.secondary,
      child: !settings.isSignedIn
          ? AppEmptyState(
              icon: Icons.bookmark_border_rounded,
              title: 'Sign in to view saved papers',
              message: 'Bookmarks are tied to your account so they can sync across devices.',
              actionLabel: 'Sign in',
              onAction: widget.onSignInTap,
            )
          : FutureBuilder<List<QuestionPaperModel>>(
              future: _future ?? ApiService.instance.savedPapers(userId: settings.userId!),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const AppLoading(label: 'Loading saved papers...');
                }

                if (snapshot.hasError) {
                  return AppErrorState(
                    title: 'Could not load saved papers',
                    message: friendlyErrorMessage(snapshot.error, fallback: 'Unable to load saved papers. Please try again later.'),
                    onRetry: _refresh,
                  );
                }

                final papers = snapshot.data ?? const <QuestionPaperModel>[];
                if (papers.isEmpty) {
                  return AppEmptyState(
                    icon: Icons.bookmark_border_rounded,
                    title: 'Your shelf is empty',
                    message: 'Save papers while browsing, then return here to open or download them.',
                    actionLabel: 'Browse papers',
                    onAction: widget.onBrowseTap,
                  );
                }

                return Column(
                  children: [
                    for (final paper in papers)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: QuestionPaperCard(
                          paper: paper,
                          onOpen: () => context.push(AppRoutes.pdfViewer, extra: PdfViewerRouteArgs(paper)),
                          onDownload: () => _downloadPaper(paper),
                          onBookmark: () => _removeBookmark(paper),
                          onShare: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Share ${paper.displayCourseCode}')),
                            );
                          },
                        ),
                      ),
                    const SizedBox(height: 4),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: AppButton(
                        label: 'Refresh shelf',
                        icon: Icons.refresh_rounded,
                        variant: AppButtonVariant.outlined,
                        width: 150,
                        onPressed: _refresh,
                      ),
                    ),
                  ],
                );
              },
            ),
    );
  }
}
