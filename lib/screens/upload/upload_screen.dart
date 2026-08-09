import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/services/app_settings_controller.dart';
import '../../core/utils/user_facing_message.dart';
import '../../models/bootstrap_data.dart';
import '../../models/course_model.dart';
import '../../models/faculty_model.dart';
import '../../services/api_service.dart';
import '../../services/upload_service.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/app_card.dart';
import '../../widgets/common/app_empty_state.dart';
import '../../widgets/common/app_error_state.dart';
import '../../widgets/common/app_loading.dart';
import '../../widgets/common/app_page_scaffold.dart';
import '../../widgets/common/app_text_field.dart';

class UploadScreen extends StatefulWidget {
  const UploadScreen({
    super.key,
    required this.onBrowseTap,
    required this.onSavedTap,
    required this.onProfileTap,
    required this.onSignInTap,
    required this.onSignUpTap,
  });

  final VoidCallback onBrowseTap;
  final VoidCallback onSavedTap;
  final VoidCallback onProfileTap;
  final VoidCallback onSignInTap;
  final VoidCallback onSignUpTap;

  @override
  State<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen> {
  final _courseCodeController = TextEditingController();
  final _courseTitleController = TextEditingController();
  final _titleController = TextEditingController();
  Future<BootstrapData>? _bootstrapFuture;
  Future<List<CourseModel>>? _coursesFuture;
  FacultyModel? _faculty;
  String? _department;
  String? _level;
  CourseModel? _course;
  String? _examType;
  String? _session;
  final List<PlatformFile> _files = <PlatformFile>[];
  bool _uploading = false;
  double _progress = 0;
  CancelToken? _cancelToken;

  @override
  void initState() {
    super.initState();
    _bootstrapFuture = ApiService.instance.bootstrap();
  }

  @override
  void dispose() {
    _cancelToken?.cancel();
    _courseCodeController.dispose();
    _courseTitleController.dispose();
    _titleController.dispose();
    super.dispose();
  }

  void _refreshCourses() {
    final faculty = _faculty;
    final department = _department;
    final level = _level;

    if (faculty == null || department == null || level == null) {
      setState(() {
        _coursesFuture = null;
        _course = null;
        _courseCodeController.clear();
        _courseTitleController.clear();
      });
      return;
    }

    setState(() {
      _coursesFuture = ApiService.instance.courses(
        facultyCode: faculty.code,
        departmentName: department,
        level: level,
      );
      _course = null;
      _courseCodeController.clear();
      _courseTitleController.clear();
    });
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
      _faculty = selected;
      _department = selected.departments.isNotEmpty ? selected.departments.first : null;
      _level = null;
      _course = null;
      _courseCodeController.clear();
      _courseTitleController.clear();
    });
    _refreshCourses();
  }

  Future<void> _pickDepartment() async {
    final faculty = _faculty;
    if (faculty == null) return;
    final selected = await _pickValue<String>(
      title: 'Select department',
      items: faculty.departments,
      labelBuilder: (department) => department,
    );
    if (selected == null) return;
    setState(() {
      _department = selected;
      _level = null;
      _course = null;
      _courseCodeController.clear();
      _courseTitleController.clear();
    });
    _refreshCourses();
  }

  Future<void> _pickLevel(BootstrapData data) async {
    final selected = await _pickValue<String>(
      title: 'Select level',
      items: data.levels.map((level) => level.value).toList(),
      labelBuilder: (level) => level,
    );
    if (selected == null) return;
    setState(() {
      _level = selected;
      _course = null;
      _courseCodeController.clear();
      _courseTitleController.clear();
    });
    _refreshCourses();
  }

  Future<void> _pickCourse(List<CourseModel> courses) async {
    final selected = await _pickValue<CourseModel>(
      title: 'Select course',
      items: courses,
      labelBuilder: (course) => '${course.displayCode} - ${course.courseTitle}',
    );
    if (selected == null) return;
    setState(() {
      _course = selected;
      _courseCodeController.text = selected.lookupKey;
      _courseTitleController.text = selected.courseTitle;
    });
  }

  Future<void> _pickExamType(BootstrapData data) async {
    final selected = await _pickValue<String>(
      title: 'Select exam type',
      items: data.examTypes,
      labelBuilder: (item) => item,
    );
    if (selected == null) return;
    setState(() => _examType = selected);
  }

  Future<void> _pickSession(BootstrapData data) async {
    final selected = await _pickValue<String>(
      title: 'Select session',
      items: data.sessions,
      labelBuilder: (item) => item,
    );
    if (selected == null) return;
    setState(() => _session = selected);
  }

  Future<void> _pickFiles() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: AppConstants.allowedUploadExtensions,
      withData: false,
    );

    if (result == null || result.files.isEmpty) return;

    final selectedFiles = result.files.take(AppConstants.maxUploadFiles).toList();
    PlatformFile? unsupportedFile;
    for (final file in selectedFiles) {
      if (file.path == null || file.path!.isEmpty) {
        unsupportedFile = file;
        break;
      }
    }
    if (!mounted) return;
    if (unsupportedFile != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${unsupportedFile.name} could not be prepared for upload. Please choose another file.')),
      );
      return;
    }

    setState(() {
      _files
        ..clear()
        ..addAll(selectedFiles);
    });
  }

  Future<void> _upload() async {
    final settings = context.read<AppSettingsController>();
    final faculty = _faculty;
    if (!settings.isSignedIn || settings.userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sign in to upload papers.')),
      );
      return;
    }

    final courseKey = _courseCodeController.text.trim();
    final courseTitle = _courseTitleController.text.trim();
    if (faculty == null || _department == null || _level == null || _examType == null || _session == null || courseKey.isEmpty || _files.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select faculty, department, level, course, exam type, session, and files first.')),
      );
      return;
    }

    final maxBytes = AppConstants.maxUploadFileSizeMb * 1024 * 1024;
    PlatformFile? oversizedFile;
    for (final file in _files) {
      if (file.path == null || file.path!.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${file.name} could not be prepared for upload. Please choose it again.')),
        );
        return;
      }
      if (file.size > maxBytes) {
        oversizedFile = file;
        break;
      }
    }
    if (oversizedFile != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${oversizedFile.name} is larger than ${AppConstants.maxUploadFileSizeMb} MB.')),
      );
      return;
    }

    setState(() {
      _uploading = true;
      _progress = 0;
      _cancelToken = CancelToken();
    });

    try {
      await UploadService.instance.uploadQuestionPaper(
        facultyCode: faculty.code,
        department: _department!,
        level: _level!,
        examType: _examType!,
        session: _session!,
        courseCode: courseKey,
        courseTitle: courseTitle.isEmpty ? null : courseTitle,
        title: _titleController.text.trim().isEmpty ? null : _titleController.text.trim(),
        userId: settings.userId,
        files: _files,
        cancelToken: _cancelToken,
        onSendProgress: (sent, total) {
          if (!mounted || total <= 0) return;
          setState(() => _progress = sent / total);
        },
      );

      if (!mounted) return;
      setState(() {
        _files.clear();
        _courseCodeController.clear();
        _courseTitleController.clear();
        _titleController.clear();
        _progress = 0;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Question paper uploaded successfully.')),
      );
    } on DioException catch (error) {
      if (!mounted) return;
      final cancelled = CancelToken.isCancel(error) || error.type == DioExceptionType.cancel;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(cancelled ? 'Upload cancelled.' : uploadErrorMessage(error))),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(uploadErrorMessage(error))),
      );
    } finally {
      if (mounted) {
        setState(() {
          _uploading = false;
          _cancelToken = null;
          _progress = 0;
        });
      }
    }
  }

  void _cancelUpload() {
    _cancelToken?.cancel('Cancelled by user');
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<AppSettingsController>();

    return AppPageScaffold(
      title: 'Upload',
      subtitle: 'Share question papers and keep the repository current.',
      heroColor: Theme.of(context).colorScheme.secondary,
      child: FutureBuilder<BootstrapData>(
        future: _bootstrapFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const AppLoading(label: 'Loading upload options...');
          }

          if (snapshot.hasError) {
            return AppErrorState(
              title: 'Could not load upload options',
              message: friendlyErrorMessage(snapshot.error, fallback: 'Unable to load upload options. Please try again later.'),
              onRetry: () => setState(() {
                _bootstrapFuture = ApiService.instance.bootstrap();
              }),
            );
          }

          final data = snapshot.data ?? BootstrapData.fallback();
          final signedIn = settings.isSignedIn;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!signedIn)
                AppEmptyState(
                  icon: Icons.lock_outline_rounded,
                  title: 'Sign in to upload',
                  message: 'Create or sign in to an account before uploading question papers.',
                  actionLabel: 'Sign in',
                  onAction: widget.onSignInTap,
                )
              else ...[
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: AppSelectField(
                              label: 'Faculty',
                              value: _faculty?.code ?? '',
                              placeholder: 'Select faculty',
                              onTap: () => _pickFaculty(data),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: AppSelectField(
                              label: 'Department',
                              value: _department ?? '',
                              placeholder: 'Select department',
                              onTap: _faculty == null ? () => _pickFaculty(data) : _pickDepartment,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: AppSelectField(
                              label: 'Level',
                              value: _level ?? '',
                              placeholder: 'Select level',
                              onTap: () => _pickLevel(data),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: AppSelectField(
                              label: 'Exam type',
                              value: _examType ?? '',
                              placeholder: 'Select type',
                              onTap: () => _pickExamType(data),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      AppSelectField(
                        label: 'Session',
                        value: _session ?? '',
                        placeholder: 'Select session',
                        onTap: () => _pickSession(data),
                      ),
                      const SizedBox(height: 12),
                      FutureBuilder<List<CourseModel>>(
                        future: _coursesFuture,
                        builder: (context, courseSnapshot) {
                          final canLoadCourses = _faculty != null && _department != null && _level != null;

                          if (!canLoadCourses) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                AppEmptyState(
                                  icon: Icons.menu_book_outlined,
                                  title: 'Select a course',
                                  message: 'Pick faculty, department, and level to load the matching course list.',
                                ),
                                const SizedBox(height: 12),
                                AppTextField(
                                  controller: _courseCodeController,
                                  label: 'Course key',
                                  hintText: 'Course code or unique key',
                                  prefixIcon: Icons.code_rounded,
                                ),
                                const SizedBox(height: 12),
                                AppTextField(
                                  controller: _courseTitleController,
                                  label: 'Course title',
                                  hintText: 'Display name for the course',
                                  prefixIcon: Icons.menu_book_rounded,
                                ),
                                const SizedBox(height: 12),
                                AppTextField(
                                  controller: _titleController,
                                  label: 'Paper title',
                                  hintText: 'Optional display title',
                                  prefixIcon: Icons.title_rounded,
                                ),
                              ],
                            );
                          }

                          if (courseSnapshot.connectionState == ConnectionState.waiting) {
                            return const AppLoading(label: 'Loading courses...');
                          }

                          if (courseSnapshot.hasError) {
                            return AppErrorState(
                              title: 'Could not load courses',
                              message: friendlyErrorMessage(courseSnapshot.error, fallback: 'Unable to load courses. Please try again later.'),
                              onRetry: _refreshCourses,
                            );
                          }

                          final courses = courseSnapshot.data ?? const <CourseModel>[];
                          if (courses.isEmpty) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                AppEmptyState(
                                  icon: Icons.menu_book_outlined,
                                  title: 'No courses found',
                                  message: 'No course entries are available for this faculty, department, and level yet. Enter the course details below to create one.',
                                  actionLabel: 'Retry',
                                  onAction: _refreshCourses,
                                ),
                                const SizedBox(height: 12),
                                AppTextField(
                                  controller: _courseCodeController,
                                  label: 'Course key',
                                  hintText: 'Course code or unique key',
                                  prefixIcon: Icons.code_rounded,
                                ),
                                const SizedBox(height: 12),
                                AppTextField(
                                  controller: _courseTitleController,
                                  label: 'Course title',
                                  hintText: 'Display name for the course',
                                  prefixIcon: Icons.menu_book_rounded,
                                ),
                                const SizedBox(height: 12),
                                AppTextField(
                                  controller: _titleController,
                                  label: 'Paper title',
                                  hintText: 'Optional display title',
                                  prefixIcon: Icons.title_rounded,
                                ),
                              ],
                            );
                          }

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              AppSelectField(
                                label: 'Course',
                                value: _course?.displayCode ?? _courseCodeController.text.trim(),
                                placeholder: 'Select course',
                                onTap: () => _pickCourse(courses),
                              ),
                              const SizedBox(height: 12),
                              AppTextField(
                                controller: _courseCodeController,
                                label: 'Course key',
                                hintText: 'Course code or unique key',
                                prefixIcon: Icons.code_rounded,
                              ),
                              const SizedBox(height: 12),
                              AppTextField(
                                controller: _courseTitleController,
                                label: 'Course title',
                                hintText: 'Display name for the course',
                                prefixIcon: Icons.menu_book_rounded,
                              ),
                              const SizedBox(height: 12),
                              AppTextField(
                                controller: _titleController,
                                label: 'Paper title',
                                hintText: 'Optional display title',
                                prefixIcon: Icons.title_rounded,
                              ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 14),
                      AppButton(
                        label: _files.isEmpty ? 'Choose files' : '${_files.length} file(s) selected',
                        icon: Icons.upload_file_rounded,
                        variant: AppButtonVariant.outlined,
                        onPressed: _uploading ? null : _pickFiles,
                      ),
                      if (_files.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (final file in _files.take(6))
                              ConstrainedBox(
                                constraints: const BoxConstraints(maxWidth: 220),
                                child: Chip(label: Text(file.name, overflow: TextOverflow.ellipsis)),
                              ),
                          ],
                        ),
                        if (_files.length > 6)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              '+${_files.length - 6} more selected',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                                  ),
                            ),
                          ),
                      ],
                      if (_uploading) ...[
                        const SizedBox(height: 16),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(999),
                          child: LinearProgressIndicator(value: _progress <= 0 ? null : _progress),
                        ),
                      ],
                      const SizedBox(height: 16),
                      AppButton(
                        label: _uploading ? 'Cancel upload' : 'Upload paper',
                        icon: _uploading ? Icons.close_rounded : Icons.cloud_upload_outlined,
                        onPressed: _uploading ? _cancelUpload : (_files.isEmpty ? null : _upload),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Tips', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                      const SizedBox(height: 10),
                      const Text('• Use clear course codes when available.'),
                      const SizedBox(height: 6),
                      const Text('• PDFs and images are supported.'),
                      const SizedBox(height: 6),
                      const Text('• Maximum file size is 50 MB.'),
                      const SizedBox(height: 6),
                      const Text('• Keep uploads under 10 files per submission.'),
                    ],
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}
