import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_constants.dart';
import '../../core/routes/app_routes.dart';
import '../../models/faculty_model.dart';
import '../../widgets/browse/level_card.dart';
import '../../widgets/common/app_card.dart';
import '../../widgets/common/app_page_scaffold.dart';

class DepartmentScreen extends StatelessWidget {
  const DepartmentScreen({
    super.key,
    required this.faculty,
    required this.department,
  });

  final FacultyModel faculty;
  final String department;

  @override
  Widget build(BuildContext context) {
    return AppPageScaffold(
      title: department,
      subtitle: '${faculty.code} • ${faculty.name}',
      heroColor: Theme.of(context).colorScheme.secondary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  department,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                Text(
                  'Choose a level to continue to course selection.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'Select level',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          ...AppConstants.defaultLevels.map(
            (level) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: LevelCard(
                label: level,
                onTap: () {
                  context.push(
                    AppRoutes.level,
                    extra: LevelRouteArgs(
                      faculty: faculty,
                      department: department,
                      level: level,
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

