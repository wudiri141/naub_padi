import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/routes/app_routes.dart';
import '../../core/services/app_settings_controller.dart';
import '../../core/utils/user_facing_message.dart';
import '../../models/question_paper_model.dart';
import '../../services/api_service.dart';
import '../../services/pdf_service.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/app_card.dart';
import '../../widgets/common/app_empty_state.dart';
import '../../widgets/common/app_error_state.dart';
import '../../widgets/common/app_loading.dart';
import '../../widgets/common/app_page_scaffold.dart';
import '../../widgets/common/app_text_field.dart';
import '../../widgets/common/download_progress_dialog.dart';
import '../../widgets/search/search_result_card.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _queryController = TextEditingController();
  Future<List<QuestionPaperModel>>? _papersFuture;

  @override
  void initState() {
    super.initState();
    _papersFuture = ApiService.instance.questionPapers();
  }

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
  }

  void _runSearch([String? value]) {
    final query = (value ?? _queryController.text).trim();
    setState(() {
      _papersFuture = ApiService.instance.questionPapers(
        query: query.isEmpty ? null : query,
      );
    });
  }

  Future<void> _bookmarkPaper(QuestionPaperModel paper) async {
    final settings = context.read<AppSettingsController>();
    if (!settings.isSignedIn || settings.userId == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sign in to save papers.')),
      );
      return;
    }

    try {
      await ApiService.instance.bookmark(userId: settings.userId!, paperId: paper.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${paper.displayCourseCode} saved to your shelf.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(friendlyErrorMessage(error, fallback: 'Unable to save this paper. Please try again later.'))),
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
    return AppPageScaffold(
      title: 'Search',
      subtitle: 'Find papers, course codes, sessions, or departments.',
      heroColor: Theme.of(context).colorScheme.secondary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppTextField(
                  controller: _queryController,
                  label: 'Search',
                  hintText: 'Course code, title, faculty, department, session, level',
                  prefixIcon: Icons.search_rounded,
                  textInputAction: TextInputAction.search,
                  onFieldSubmitted: _runSearch,
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: AppConstants.defaultSearchShortcuts
                      .map(
                        (shortcut) => ActionChip(
                          label: Text(shortcut),
                          onPressed: () {
                            _queryController.text = shortcut;
                            _runSearch(shortcut);
                          },
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 14),
                AppButton(
                  label: 'Search papers',
                  icon: Icons.search_rounded,
                  onPressed: () => _runSearch(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          FutureBuilder<List<QuestionPaperModel>>(
            future: _papersFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const AppLoading(label: 'Searching papers...');
              }

              if (snapshot.hasError) {
                return AppErrorState(
                  title: 'Could not load results',
                  message: friendlyErrorMessage(snapshot.error, fallback: 'Unable to load search results. Please try again later.'),
                  onRetry: () => _runSearch(),
                );
              }

              final papers = snapshot.data ?? const <QuestionPaperModel>[];
              if (papers.isEmpty) {
                return AppEmptyState(
                  icon: Icons.search_off_rounded,
                  title: 'No results found',
                  message: _queryController.text.trim().isEmpty
                      ? 'Try a course code, faculty code, or session label.'
                      : 'No papers matched "${_queryController.text.trim()}".',
                );
              }

              return Column(
                children: [
                  for (final paper in papers)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: SearchResultCard(
                        paper: paper,
                        onTap: () => context.push(AppRoutes.pdfViewer, extra: PdfViewerRouteArgs(paper)),
                        onDownload: () => _downloadPaper(paper),
                        onBookmark: () => _bookmarkPaper(paper),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
