import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/routes/app_routes.dart';
import '../../core/services/app_settings_controller.dart';
import '../../core/utils/user_facing_message.dart';
import '../../models/bootstrap_data.dart';
import '../../models/faculty_model.dart';
import '../../models/user_model.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/app_card.dart';
import '../../widgets/common/app_empty_state.dart';
import '../../widgets/common/app_page_scaffold.dart';
import '../../widgets/common/app_text_field.dart';
import '../../widgets/profile/profile_header.dart';
import '../../widgets/profile/profile_menu_item.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({
    super.key,
    required this.onSavedTap,
    required this.onSignInTap,
    required this.onSignUpTap,
  });

  final VoidCallback onSavedTap;
  final VoidCallback onSignInTap;
  final VoidCallback onSignUpTap;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _nameController = TextEditingController();
  Future<BootstrapData>? _bootstrapFuture;
  FacultyModel? _selectedFaculty;
  String? _selectedDepartment;
  String? _selectedLevel;
  bool _editing = false;
  bool _saving = false;
  bool _initialized = false;
  int? _loadedUserId;

  @override
  void initState() {
    super.initState();
    _bootstrapFuture = ApiService.instance.bootstrap();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _syncWithSettings(AppSettingsController settings, BootstrapData data) {
    _nameController.text = settings.fullName ?? '';
    _selectedFaculty = data.facultyByCode(settings.facultyCode);
    _selectedDepartment = settings.departmentName;
    _selectedLevel = settings.level;
  }

  Future<T?> _pickValue<T>({
    required String title,
    required List<T> items,
    required String Function(T item) labelBuilder,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                child: Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
              ),
              for (final item in items)
                ListTile(
                  title: Text(labelBuilder(item)),
                  onTap: () => Navigator.of(sheetContext).pop(item),
                ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickFaculty(BootstrapData data) async {
    final selected = await _pickValue<FacultyModel>(
      title: 'Select faculty',
      items: data.faculties,
      labelBuilder: (faculty) => '${faculty.code} - ${faculty.name}',
    );
    if (selected == null) return;
    setState(() {
      _selectedFaculty = selected;
      _selectedDepartment = selected.departments.isNotEmpty ? selected.departments.first : null;
    });
  }

  Future<void> _pickDepartment(BootstrapData data) async {
    final faculty = _selectedFaculty;
    if (faculty == null) return;
    final selected = await _pickValue<String>(
      title: 'Select department',
      items: faculty.departments,
      labelBuilder: (department) => department,
    );
    if (selected == null) return;
    setState(() => _selectedDepartment = selected);
  }

  Future<void> _pickLevel(BootstrapData data) async {
    final selected = await _pickValue<String>(
      title: 'Select level',
      items: data.levels.map((level) => level.value).toList(),
      labelBuilder: (level) => level,
    );
    if (selected == null) return;
    setState(() => _selectedLevel = selected);
  }

  Future<void> _saveProfile() async {
    final settings = context.read<AppSettingsController>();
    final userId = settings.userId;
    if (userId == null || !settings.isSignedIn) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sign in to edit your profile.')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final current = UserModel(
        id: userId,
        fullName: _nameController.text.trim().isEmpty ? (settings.fullName ?? 'Student') : _nameController.text.trim(),
        email: settings.profileEmail ?? '',
        facultyCode: _selectedFaculty?.code ?? settings.facultyCode,
        departmentName: _selectedDepartment ?? settings.departmentName,
        level: _selectedLevel ?? settings.level,
      );
      await AuthService.instance.updateProfile(user: current);
      await settings.refreshSession();
      if (!mounted) return;
      setState(() => _editing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(updateErrorMessage(error))),
      );
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  Future<void> _signOut() async {
    await context.read<AppSettingsController>().clearSession();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Signed out.')),
    );
    context.go(AppRoutes.login);
  }

  Future<void> _showMenu() async {
    final settings = context.read<AppSettingsController>();
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
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
                subtitle: 'Open bookmarked papers',
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  widget.onSavedTap();
                },
              ),
              ProfileMenuItem(
                icon: Icons.logout_rounded,
                title: 'Sign out',
                subtitle: 'Clear the current session',
                onTap: () async {
                  Navigator.of(sheetContext).pop();
                  await _signOut();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<AppSettingsController>();
    final signedIn = settings.isSignedIn;

    return AppPageScaffold(
      title: 'Profile',
      subtitle: 'Account and application preferences',
      heroColor: Theme.of(context).colorScheme.secondary,
      trailing: IconButton(
        onPressed: _showMenu,
        icon: const Icon(Icons.settings_outlined, color: Colors.white),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ProfileHeader(
            user: signedIn
                ? UserModel(
                    id: settings.userId ?? 0,
                    fullName: settings.fullName ?? 'Student',
                    email: settings.profileEmail ?? '',
                    facultyCode: settings.facultyCode,
                    departmentName: settings.departmentName,
                    level: settings.level,
                  )
                : null,
            isSignedIn: signedIn,
            onEditTap: () => setState(() => _editing = true),
            onSignInTap: widget.onSignInTap,
            onSignUpTap: widget.onSignUpTap,
          ),
          const SizedBox(height: 18),
          if (!signedIn)
            const AppEmptyState(
              icon: Icons.person_outline_rounded,
              title: 'Guest mode',
              message: 'Sign in to sync your account, bookmarks, and uploads.',
            )
          else ...[
            FutureBuilder<BootstrapData>(
              future: _bootstrapFuture,
              builder: (context, snapshot) {
                final data = snapshot.data ?? BootstrapData.fallback();
                if (signedIn && (!_initialized || _loadedUserId != settings.userId)) {
                  _syncWithSettings(settings, data);
                  _initialized = true;
                  _loadedUserId = settings.userId;
                }

                return AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Account details', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                      const SizedBox(height: 14),
                      AppTextField(
                        controller: _nameController,
                        label: 'Full name',
                        prefixIcon: Icons.person_outline_rounded,
                        readOnly: !_editing,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: AppSelectField(
                              label: 'Faculty',
                              value: _selectedFaculty?.name ?? settings.facultyCode ?? '',
                              placeholder: 'Select faculty',
                              isEnabled: _editing,
                              onTap: () => _pickFaculty(data),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: AppSelectField(
                              label: 'Department',
                              value: _selectedDepartment ?? '',
                              placeholder: 'Select department',
                              isEnabled: _editing && _selectedFaculty != null,
                              onTap: () => _pickDepartment(data),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      AppSelectField(
                        label: 'Level',
                        value: _selectedLevel ?? '',
                        placeholder: 'Select level',
                        isEnabled: _editing,
                        onTap: () => _pickLevel(data),
                      ),
                      const SizedBox(height: 14),
                      if (_editing)
                        AppButton(
                          label: _saving ? 'Saving...' : 'Save changes',
                          icon: Icons.save_outlined,
                          onPressed: _saving ? null : _saveProfile,
                        )
                      else
                        AppButton(
                          label: 'Edit profile',
                          icon: Icons.edit_outlined,
                          variant: AppButtonVariant.outlined,
                          onPressed: () => setState(() => _editing = true),
                        ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 18),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Preferences', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 12),
                  ProfileMenuItem(
                    icon: Icons.brightness_6_outlined,
                    title: settings.themeMode == ThemeMode.dark ? 'Dark mode' : 'Light mode',
                    subtitle: 'Switch the app appearance',
                    trailing: Switch(
                      value: settings.themeMode == ThemeMode.dark,
                      onChanged: (_) => settings.toggleTheme(),
                    ),
                  ),
                  ProfileMenuItem(
                    icon: Icons.bookmark_border_rounded,
                    title: 'Saved shelf',
                    subtitle: 'View bookmarked papers',
                    onTap: widget.onSavedTap,
                  ),
                  ProfileMenuItem(
                    icon: Icons.logout_rounded,
                    title: 'Sign out',
                    subtitle: 'Clear the current session',
                    onTap: _signOut,
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 18),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('About NAUB Padi', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                Text(
                  AppConstants.appSubtitle,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
