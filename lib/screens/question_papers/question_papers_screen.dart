import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/routes/app_routes.dart';
import '../../core/services/app_settings_controller.dart';
import '../../core/utils/user_facing_message.dart';
import '../../models/course_model.dart';
import '../../models/faculty_model.dart';
import '../../models/question_paper_model.dart';
import '../../services/api_service.dart';
import '../../services/pdf_service.dart';
import '../../widgets/common/app_empty_state.dart';
import '../../widgets/common/app_error_state.dart';
import '../../widgets/common/app_loading.dart';
import '../../widgets/common/app_page_scaffold.dart';
import '../../widgets/common/download_progress_dialog.dart';
import '../../widgets/question_papers/question_paper_card.dart';

class QuestionPapersScreen extends StatelessWidget {
  const QuestionPapersScreen({
    super.key,
    required this.faculty,
    required this.department,
    required this.level,
    this.course,
    this.query,
  });

  final FacultyModel faculty;
  final String department;
  final String level;
  final CourseModel? course;
  final String? query;

  @override
  Widget build(BuildContext context) {
    final title = query != null && query!.trim().isNotEmpty
        ? 'Search results'
        : course?.displayCode ?? 'Question papers';
    final subtitle = query != null && query!.trim().isNotEmpty
        ? 'Searching for "${query!.trim()}"'
        : '${faculty.code} • $department • $level';

    return AppPageScaffold(
      title: title,
      subtitle: subtitle,
      heroColor: Theme.of(context).colorScheme.secondary,
      child: FutureBuilder<List<QuestionPaperModel>>(
        future: ApiService.instance.questionPapers(
          faculty: faculty.code,
          department: department,
          level: level,
          courseCode: course?.lookupKey,
          query: query,
        ),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const AppLoading(label: 'Loading papers...');
          }

          if (snapshot.hasError) {
            return AppErrorState(
              title: 'Could not load question papers',
              message: friendlyErrorMessage(snapshot.error, fallback: 'Unable to load question papers. Please try again later.'),
            );
          }

          final papers = snapshot.data ?? const <QuestionPaperModel>[];
          if (papers.isEmpty) {
            return AppEmptyState(
              icon: Icons.description_outlined,
              title: 'No question papers found',
              message: query != null && query!.trim().isNotEmpty
                  ? 'Try a different search term.'
                  : 'No papers are available for this course yet.',
              actionLabel: 'Upload a paper',
              onAction: () {
                context.go(AppRoutes.home);
              },
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
                    onDownload: () async {
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
                        if (!context.mounted) {
                          return;
                        }
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
                        if (!context.mounted) {
                          return;
                        }
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(friendlyErrorMessage(error, fallback: 'Unable to download this paper. Please try again later.'))),
                        );
                      }
                    },
                    onBookmark: () async {
                      final settings = context.read<AppSettingsController>();
                      if (!settings.isSignedIn || settings.userId == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Sign in to save papers.')),
                        );
                        return;
                      }

                      try {
                        await ApiService.instance.bookmark(userId: settings.userId!, paperId: paper.id);
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('${paper.displayCourseCode} saved to your shelf.')),
                        );
                      } catch (error) {
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(friendlyErrorMessage(error, fallback: 'Unable to save this paper. Please try again later.'))),
                        );
                      }
                    },
                    onShare: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Share ${paper.displayCourseCode}')),
                      );
                    },
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
