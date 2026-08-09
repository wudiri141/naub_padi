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
import '../../widgets/common/app_button.dart';
import '../../widgets/common/app_card.dart';
import '../../widgets/common/app_empty_state.dart';
import '../../widgets/common/app_loading.dart';
import '../../widgets/common/app_page_scaffold.dart';
import '../../widgets/common/download_progress_dialog.dart';
import '../../widgets/question_papers/question_paper_card.dart';

class CourseScreen extends StatelessWidget {
  const CourseScreen({
    super.key,
    required this.faculty,
    required this.department,
    required this.level,
    required this.course,
  });

  final FacultyModel faculty;
  final String department;
  final String level;
  final CourseModel course;

  @override
  Widget build(BuildContext context) {
    return AppPageScaffold(
      title: course.displayCode,
      subtitle: course.courseTitle,
      heroColor: Theme.of(context).colorScheme.secondary,
      child: FutureBuilder<List<QuestionPaperModel>>(
        future: ApiService.instance.questionPapers(
          faculty: faculty.code,
          department: department,
          level: level,
          courseCode: course.lookupKey,
        ),
        builder: (context, snapshot) {
          final papers = snapshot.data ?? const <QuestionPaperModel>[];

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const AppLoading(label: 'Loading question papers...');
          }

          if (snapshot.hasError) {
            return AppEmptyState(
              icon: Icons.error_outline_rounded,
              title: 'Unable to load question papers',
              message: friendlyErrorMessage(snapshot.error, fallback: 'Unable to load question papers. Please try again later.'),
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      course.courseTitle,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _Chip(label: faculty.code),
                        _Chip(label: department),
                        _Chip(label: level),
                        if (course.semesterLabel != null && course.semesterLabel!.isNotEmpty) _Chip(label: course.semesterLabel!),
                      ],
                    ),
                    const SizedBox(height: 14),
                    AppButton(
                      label: 'View question papers',
                      icon: Icons.description_outlined,
                      onPressed: () {
                        context.push(
                          AppRoutes.questionPapers,
                          extra: QuestionPapersRouteArgs(
                            faculty: faculty,
                            department: department,
                            level: level,
                            course: course,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Paper preview',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 10),
              if (papers.isEmpty)
                const AppEmptyState(
                  icon: Icons.description_outlined,
                  title: 'No papers found',
                  message: 'No question papers are uploaded for this course yet.',
                )
              else
                Column(
                  children: [
                    for (final paper in papers.take(2))
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: QuestionPaperCard(
                          paper: paper,
                          onOpen: () => context.push(AppRoutes.pdfViewer, extra: PdfViewerRouteArgs(paper)),
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
                              if (!context.mounted) return;
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
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(friendlyErrorMessage(error, fallback: 'Unable to download this paper. Please try again later.'))),
                              );
                            }
                          },
                          onShare: () {},
                        ),
                      ),
                    if (papers.length > 2)
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton.icon(
                          onPressed: () {
                            context.push(
                              AppRoutes.questionPapers,
                              extra: QuestionPapersRouteArgs(
                                faculty: faculty,
                                department: department,
                                level: level,
                                course: course,
                              ),
                            );
                          },
                          icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                          label: Text('View all ${papers.length} papers'),
                        ),
                      ),
                  ],
                ),
            ],
          );
        },
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(label),
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}
