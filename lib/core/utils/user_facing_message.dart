import 'package:dio/dio.dart';

import '../../services/api_service.dart';

String loginErrorMessage(Object? error) {
  if (error is DioException && _isNetworkError(error)) {
    return 'Network error. Please check your internet connection and try again.';
  }

  final message = _extractMessage(error);
  final normalized = message.toLowerCase();

  if (normalized.contains('please enter your email')) {
    return 'Please enter your email.';
  }
  if (normalized.contains('please enter your password')) {
    return 'Please enter your password.';
  }
  if (normalized.contains('invalid email format')) {
    return 'Invalid email format.';
  }
  if (normalized.contains('no account found with this email')) {
    return 'Email does not exist.';
  }
  if (normalized.contains('incorrect password')) {
    return 'Incorrect email or password.';
  }
  if (normalized.contains('invalid login credentials') || normalized.contains('invalid credentials')) {
    return 'Invalid login credentials. Please try again.';
  }
  if (normalized.contains('incorrect email address')) {
    return 'Incorrect email address.';
  }

  if (message.isNotEmpty && !_looksTechnical(message)) {
    return message;
  }

  return 'Unable to log in. Please try again later.';
}

String saveSuccessMessage() => 'Changes saved successfully.';

String profileUpdateSuccessMessage() => 'Profile updated successfully.';

String friendlyErrorMessage(
  Object? error, {
  String fallback = 'Something went wrong. Please try again.',
}) {
  if (error is DioException && _isNetworkError(error)) {
    return 'Network error. Please check your internet connection and try again.';
  }

  final message = _extractMessage(error);
  if (message.isEmpty) {
    return fallback;
  }

  if (_looksTechnical(message)) {
    return fallback;
  }

  return message;
}

String updateErrorMessage(Object? error) {
  return friendlyErrorMessage(
    error,
    fallback: 'Unable to save changes. Please try again later.',
  );
}

String uploadErrorMessage(Object? error) {
  return friendlyErrorMessage(
    error,
    fallback: 'Upload failed. Please try again later.',
  );
}

String _extractMessage(Object? error) {
  if (error == null) {
    return '';
  }

  if (error is ApiException) {
    return error.message;
  }

  if (error is DioException) {
    final responseData = error.response?.data;
    if (responseData is Map) {
      final mapped = Map<String, dynamic>.from(responseData);
      final message = mapped['message']?.toString().trim() ?? '';
      if (message.isNotEmpty) {
        return message;
      }
    }

    final message = error.message?.trim() ?? '';
    if (message.isNotEmpty && !_looksTechnical(message)) {
      return message;
    }
  }

  final text = error.toString().replaceFirst(RegExp(r'^[^:]+:\s*'), '').trim();
  return text;
}

bool _isNetworkError(DioException error) {
  return error.type == DioExceptionType.connectionError ||
      error.type == DioExceptionType.connectionTimeout ||
      error.type == DioExceptionType.receiveTimeout ||
      error.type == DioExceptionType.sendTimeout ||
      error.type == DioExceptionType.cancel;
}

bool _looksTechnical(String message) {
  final lower = message.toLowerCase();
  return lower.contains('exception') ||
      lower.contains('stack trace') ||
      lower.contains('traceback') ||
      lower.contains('formatexception') ||
      lower.contains('dioexception') ||
      lower.contains('socket') ||
      lower.contains('pdo') ||
      lower.contains('sql') ||
      lower.contains('typeerror') ||
      lower.contains('null') ||
      lower.contains('failed assertion');
}
