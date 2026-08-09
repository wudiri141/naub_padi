import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/routes/app_routes.dart';
import '../../core/utils/user_facing_message.dart';
import '../../models/bootstrap_data.dart';
import '../../models/faculty_model.dart';
import '../../services/api_service.dart';
import '../../widgets/browse/faculty_card.dart';
import '../../widgets/common/app_empty_state.dart';
import '../../widgets/common/app_loading.dart';
import '../../widgets/common/app_page_scaffold.dart';

class BrowseScreen extends StatelessWidget {
  const BrowseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppPageScaffold(
      title: 'Browse by faculty',
      subtitle: 'Follow the hierarchy from faculty to course and question papers.',
      heroColor: Theme.of(context).colorScheme.secondary,
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Icon(Icons.apartment_rounded, color: Colors.white, size: 20),
      ),
      child: FutureBuilder<BootstrapData>(
        future: ApiService.instance.bootstrap(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const AppLoading(label: 'Loading faculties...');
          }

          if (snapshot.hasError) {
            return AppEmptyState(
              icon: Icons.error_outline_rounded,
              title: 'Unable to load faculties',
              message: friendlyErrorMessage(snapshot.error, fallback: 'Unable to load faculties. Please try again later.'),
            );
          }

          final faculties = snapshot.data?.faculties ?? const <FacultyModel>[];
          if (faculties.isEmpty) {
            return const AppEmptyState(
              icon: Icons.apartment_outlined,
              title: 'No faculties available',
              message: 'Faculty data could not be loaded.',
            );
          }

          return GridView.builder(
            itemCount: faculties.length,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 240,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.95,
            ),
            itemBuilder: (context, index) {
              final faculty = faculties[index];
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
    );
  }
}
