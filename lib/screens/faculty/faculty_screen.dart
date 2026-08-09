import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/routes/app_routes.dart';
import '../../models/faculty_model.dart';
import '../../widgets/browse/department_card.dart';
import '../../widgets/common/app_card.dart';
import '../../widgets/common/app_page_scaffold.dart';

class FacultyScreen extends StatelessWidget {
  const FacultyScreen({super.key, required this.faculty});

  final FacultyModel faculty;

  @override
  Widget build(BuildContext context) {
    return AppPageScaffold(
      title: faculty.code,
      subtitle: faculty.description ?? faculty.name,
      heroColor: Theme.of(context).colorScheme.secondary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  faculty.name,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                Text(
                  '${faculty.departmentCount} departments available',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'Departments',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          ...faculty.departments.map(
            (department) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: DepartmentCard(
                title: department,
                subtitle: faculty.code,
                onTap: () {
                  context.push(
                    AppRoutes.department,
                    extra: DepartmentRouteArgs(
                      faculty: faculty,
                      department: department,
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

