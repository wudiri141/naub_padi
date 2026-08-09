import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/routes/app_routes.dart';
import '../../core/services/app_settings_controller.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/user_facing_message.dart';
import '../../models/bootstrap_data.dart';
import '../../models/question_paper_model.dart';
import '../../services/api_service.dart';
import '../../widgets/browse/faculty_card.dart';
import '../../widgets/common/app_card.dart';
import '../../widgets/common/app_empty_state.dart';
import '../../widgets/common/app_snackbar.dart';
import '../../widgets/home/home_header.dart';
import '../../widgets/home/home_search_bar.dart';
import '../../widgets/home/recent_paper_card.dart';
import '../../widgets/profile/profile_menu_item.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.onBrowseTap,
    required this.onUploadTap,
    required this.onSavedTap,
    required this.onProfileTap,
    required this.onSearchTap,
    required this.onSignInTap,
    required this.onSignUpTap,
  });

  final VoidCallback onBrowseTap;
  final VoidCallback onUploadTap;
  final VoidCallback onSavedTap;
  final VoidCallback onProfileTap;
  final VoidCallback onSearchTap;
  final VoidCallback onSignInTap;
  final VoidCallback onSignUpTap;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final Future<BootstrapData> _bootstrapFuture;
  late final Future<List<QuestionPaperModel>> _recentPapersFuture;

  @override
  void initState() {
    super.initState();
    _bootstrapFuture = ApiService.instance.bootstrap();
    _recentPapersFuture = ApiService.instance.questionPapers();
  }

  String _firstName(String? fullName) {
    final trimmed = fullName?.trim() ?? '';
    if (trimmed.isEmpty) {
      return 'Student';
    }
    return trimmed.split(RegExp(r'\s+')).first;
  }

  Future<void> _openMenu(BuildContext context) async {
    final settings = context.read<AppSettingsController>();
    final isSignedIn = settings.isSignedIn;

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ProfileMenuItem(
                  icon: Icons.brightness_6_outlined,
                  title: settings.themeMode == ThemeMode.dark ? 'Light mode' : 'Dark mode',
                  subtitle: 'Switch the app appearance',
                  trailing: Switch(
                    value: settings.themeMode == ThemeMode.dark,
                    onChanged: (_) => settings.toggleTheme(),
                  ),
                ),
                ProfileMenuItem(
                  icon: Icons.bookmark_border_rounded,
                  title: 'Saved shelf',
                  subtitle: 'Open your bookmarked papers',
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    widget.onSavedTap();
                  },
                ),
                ProfileMenuItem(
                  icon: Icons.person_outline_rounded,
                  title: 'Profile',
                  subtitle: 'Account and app preferences',
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    widget.onProfileTap();
                  },
                ),
                ProfileMenuItem(
                  icon: isSignedIn ? Icons.logout_rounded : Icons.login_rounded,
                  title: isSignedIn ? 'Sign out' : 'Sign in',
                  subtitle: isSignedIn ? 'Clear the current session' : 'Access bookmarks and uploads',
                  onTap: () async {
                    Navigator.of(sheetContext).pop();
                    if (isSignedIn) {
                      await settings.clearSession();
                      if (!context.mounted) {
                        return;
                      }
                      showAppSnackBar(context, 'Signed out.');
                    } else {
                      widget.onSignInTap();
                    }
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _openPaper(BuildContext context, QuestionPaperModel paper) async {
    context.push(AppRoutes.pdfViewer, extra: PdfViewerRouteArgs(paper));
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<AppSettingsController>();
    final isSignedIn = settings.isSignedIn;
    final greeting = isSignedIn ? 'Welcome back, ${_firstName(settings.fullName)}' : 'Welcome to NAUB Padi';
    final subtitle = isSignedIn
        ? 'Search, browse, upload, and save past questions across the university.'
        : 'Find question papers by faculty, department, level, and course.';

    return SafeArea(
      bottom: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            HomeHeader(
              title: greeting,
              subtitle: subtitle,
              onSettingsTap: () => _openMenu(context),
              onProfileTap: widget.onProfileTap,
            ),
            const SizedBox(height: 16),
            HomeSearchBar(onTap: widget.onSearchTap),
            const SizedBox(height: 18),
            if (!isSignedIn) ...[
              AppCard(
                child: Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(Icons.lock_outline_rounded, color: Theme.of(context).colorScheme.primary),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Sync your shelf',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Sign in to save papers, upload resources, and keep your profile in sync.',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
            ],
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Faculty preview',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                ),
                TextButton(
                  onPressed: widget.onBrowseTap,
                  child: const Text('View all'),
                ),
              ],
            ),
            const SizedBox(height: 10),
            FutureBuilder<BootstrapData>(
              future: _bootstrapFuture,
              builder: (context, snapshot) {
                final faculties = snapshot.data?.faculties ?? BootstrapData.fallback().faculties;
                final preview = faculties.take(4).toList();
                if (preview.isEmpty) {
                  return const AppEmptyState(
                    icon: Icons.apartment_outlined,
                    title: 'No faculties available',
                    message: 'Faculty data could not be loaded right now.',
                  );
                }

                return GridView.builder(
                  itemCount: preview.length,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.92,
                  ),
                  itemBuilder: (context, index) {
                    final faculty = preview[index];
                    return FacultyCard(
                      faculty: faculty,
                      onTap: () {
                        context.push(
                          AppRoutes.faculty,
                          extra: FacultyRouteArgs(faculty),
                        );
                      },
                    );
                  },
                );
              },
            ),
            const SizedBox(height: 22),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recent papers',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                ),
                TextButton(
                  onPressed: widget.onSearchTap,
                  child: const Text('Search more'),
                ),
              ],
            ),
            const SizedBox(height: 10),
            FutureBuilder<List<QuestionPaperModel>>(
              future: _recentPapersFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 36),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                if (snapshot.hasError) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: AppEmptyState(
                      icon: Icons.error_outline_rounded,
                      title: 'Could not load recent papers',
                      message: friendlyErrorMessage(snapshot.error, fallback: 'Unable to load recent papers. Please try again later.'),
                    ),
                  );
                }

                final papers = snapshot.data ?? const <QuestionPaperModel>[];
                if (papers.isEmpty) {
                  return const AppEmptyState(
                    icon: Icons.description_outlined,
                    title: 'No papers yet',
                    message: 'Recent question papers will appear here once they are uploaded.',
                  );
                }

                return Column(
                  children: [
                    for (final paper in papers.take(3))
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: RecentPaperCard(
                          paper: paper,
                          onTap: () => _openPaper(context, paper),
                        ),
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
