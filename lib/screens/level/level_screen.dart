import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/routes/app_routes.dart';
import '../../core/utils/user_facing_message.dart';
import '../../models/course_model.dart';
import '../../models/faculty_model.dart';
import '../../services/api_service.dart';
import '../../widgets/browse/course_card.dart';
import '../../widgets/common/app_empty_state.dart';
import '../../widgets/common/app_loading.dart';
import '../../widgets/common/app_page_scaffold.dart';

class LevelScreen extends StatelessWidget {
  const LevelScreen({
    super.key,
    required this.faculty,
    required this.department,
    required this.level,
  });

  final FacultyModel faculty;
  final String department;
  final String level;

  @override
  Widget build(BuildContext context) {
    return AppPageScaffold(
      title: level,
      subtitle: '$department • ${faculty.code}',
      heroColor: Theme.of(context).colorScheme.secondary,
      child: FutureBuilder<List<CourseModel>>(
        future: ApiService.instance.courses(
          facultyCode: faculty.code,
          departmentName: department,
          level: level,
        ),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const AppLoading(label: 'Loading courses...');
          }

          if (snapshot.hasError) {
            return AppEmptyState(
              icon: Icons.error_outline_rounded,
              title: 'Unable to load courses',
              message: friendlyErrorMessage(snapshot.error, fallback: 'Unable to load courses. Please try again later.'),
            );
          }

          final courses = snapshot.data ?? const <CourseModel>[];
          if (courses.isEmpty) {
            return const AppEmptyState(
              icon: Icons.menu_book_outlined,
              title: 'No courses found',
              message: 'No courses with question papers were found for this level yet.',
            );
          }

          return Column(
            children: [
              for (final course in courses)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: CourseCard(
                    course: course,
                    onTap: () {
                      context.push(
                        AppRoutes.course,
                        extra: CourseRouteArgs(
                          faculty: faculty,
                          department: department,
                          level: level,
                          course: course,
                        ),
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
