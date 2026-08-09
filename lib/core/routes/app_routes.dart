import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../models/course_model.dart';
import '../../models/faculty_model.dart';
import '../../models/question_paper_model.dart';
import '../services/app_settings_controller.dart';
import '../../screens/auth/login_screen.dart';
import '../../screens/auth/signup_screen.dart';
import '../../screens/course/course_screen.dart';
import '../../screens/department/department_screen.dart';
import '../../screens/faculty/faculty_screen.dart';
import '../../screens/level/level_screen.dart';
import '../../screens/onboarding/onboarding_screen.dart';
import '../../screens/pdf/pdf_viewer_screen.dart';
import '../../screens/question_papers/question_papers_screen.dart';
import '../../screens/search/search_screen.dart';
import '../../screens/splash/splash_screen.dart';
import '../../widgets/navigation/app_shell.dart';

class AppRoutes {
  const AppRoutes._();

  static const String root = '/';
  static const String home = '/home';
  static const String login = '/login';
  static const String signup = '/signup';
  static const String onboarding = '/onboarding';
  static const String search = '/search';
  static const String faculty = '/faculty';
  static const String department = '/department';
  static const String level = '/level';
  static const String course = '/course';
  static const String questionPapers = '/question-papers';
  static const String pdfViewer = '/pdf';

  static GoRouter createRouter() {
    return GoRouter(
      initialLocation: root,
      routes: [
        GoRoute(
          path: root,
          builder: (context, state) => const SplashScreen(),
        ),
        GoRoute(
          path: onboarding,
          pageBuilder: (context, state) => _fadePage(
            state.pageKey,
            const OnboardingScreen(),
          ),
        ),
        GoRoute(
          path: home,
          builder: (context, state) {
            final settings = context.watch<AppSettingsController>();
            return settings.loaded ? const AppShellScreen() : const SplashScreen();
          },
        ),
        GoRoute(
          path: login,
          pageBuilder: (context, state) => _slidePage(
            state.pageKey,
            const LoginScreen(),
          ),
        ),
        GoRoute(
          path: signup,
          pageBuilder: (context, state) => _slidePage(
            state.pageKey,
            const SignupScreen(),
          ),
        ),
        GoRoute(
          path: search,
          pageBuilder: (context, state) => _fadePage(
            state.pageKey,
            const SearchScreen(),
          ),
        ),
        GoRoute(
          path: faculty,
          pageBuilder: (context, state) {
            final args = state.extra;
            if (args is! FacultyRouteArgs) {
              return _fadePage(state.pageKey, const _RouteErrorScreen(message: 'Faculty data is missing.'));
            }
            return _fadePage(
              state.pageKey,
              FacultyScreen(faculty: args.faculty),
            );
          },
        ),
        GoRoute(
          path: department,
          pageBuilder: (context, state) {
            final args = state.extra;
            if (args is! DepartmentRouteArgs) {
              return _fadePage(state.pageKey, const _RouteErrorScreen(message: 'Department data is missing.'));
            }
            return _fadePage(
              state.pageKey,
              DepartmentScreen(
                faculty: args.faculty,
                department: args.department,
              ),
            );
          },
        ),
        GoRoute(
          path: level,
          pageBuilder: (context, state) {
            final args = state.extra;
            if (args is! LevelRouteArgs) {
              return _fadePage(state.pageKey, const _RouteErrorScreen(message: 'Level data is missing.'));
            }
            return _fadePage(
              state.pageKey,
              LevelScreen(
                faculty: args.faculty,
                department: args.department,
                level: args.level,
              ),
            );
          },
        ),
        GoRoute(
          path: course,
          pageBuilder: (context, state) {
            final args = state.extra;
            if (args is! CourseRouteArgs) {
              return _fadePage(state.pageKey, const _RouteErrorScreen(message: 'Course data is missing.'));
            }
            return _fadePage(
              state.pageKey,
              CourseScreen(
                faculty: args.faculty,
                department: args.department,
                level: args.level,
                course: args.course,
              ),
            );
          },
        ),
        GoRoute(
          path: questionPapers,
          pageBuilder: (context, state) {
            final args = state.extra;
            if (args is! QuestionPapersRouteArgs) {
              return _fadePage(state.pageKey, const _RouteErrorScreen(message: 'Question paper filters are missing.'));
            }
            return _fadePage(
              state.pageKey,
              QuestionPapersScreen(
                faculty: args.faculty,
                department: args.department,
                level: args.level,
                course: args.course,
                query: args.query,
              ),
            );
          },
        ),
        GoRoute(
          path: pdfViewer,
          pageBuilder: (context, state) {
            final args = state.extra;
            if (args is! PdfViewerRouteArgs) {
              return _fadePage(state.pageKey, const _RouteErrorScreen(message: 'Question paper preview is missing.'));
            }
            return _fadePage(
              state.pageKey,
              PdfViewerScreen(
                paper: args.paper,
                localPath: args.localPath,
              ),
            );
          },
        ),
      ],
    );
  }
}

class FacultyRouteArgs {
  const FacultyRouteArgs(this.faculty);

  final FacultyModel faculty;
}

class DepartmentRouteArgs {
  const DepartmentRouteArgs({
    required this.faculty,
    required this.department,
  });

  final FacultyModel faculty;
  final String department;
}

class LevelRouteArgs {
  const LevelRouteArgs({
    required this.faculty,
    required this.department,
    required this.level,
  });

  final FacultyModel faculty;
  final String department;
  final String level;
}

class CourseRouteArgs {
  const CourseRouteArgs({
    required this.faculty,
    required this.department,
    required this.level,
    required this.course,
  });

  final FacultyModel faculty;
  final String department;
  final String level;
  final CourseModel course;
}

class QuestionPapersRouteArgs {
  const QuestionPapersRouteArgs({
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
}

class PdfViewerRouteArgs {
  const PdfViewerRouteArgs(this.paper, {this.localPath});

  final QuestionPaperModel paper;
  final String? localPath;
}

CustomTransitionPage<T> _fadePage<T>(LocalKey key, Widget child) {
  return CustomTransitionPage<T>(
    key: key,
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(
        opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
        child: child,
      );
    },
  );
}

CustomTransitionPage<T> _slidePage<T>(LocalKey key, Widget child) {
  return CustomTransitionPage<T>(
    key: key,
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final offset = Tween<Offset>(
        begin: const Offset(0.08, 0),
        end: Offset.zero,
      ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic));

      return FadeTransition(
        opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
        child: SlideTransition(
          position: offset,
          child: child,
        ),
      );
    },
  );
}

class _RouteErrorScreen extends StatelessWidget {
  const _RouteErrorScreen({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
      ),
    );
  }
}
