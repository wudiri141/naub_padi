import 'package:flutter/material.dart';

class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    required this.controller,
    this.label,
    this.hintText,
    this.prefixIcon,
    this.suffixIcon,
    this.onSuffixPressed,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.maxLines = 1,
    this.minLines,
    this.readOnly = false,
    this.onTap,
    this.onFieldSubmitted,
    this.validator,
  });

  final TextEditingController controller;
  final String? label;
  final String? hintText;
  final IconData? prefixIcon;
  final IconData? suffixIcon;
  final VoidCallback? onSuffixPressed;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final int maxLines;
  final int? minLines;
  final bool readOnly;
  final VoidCallback? onTap;
  final ValueChanged<String>? onFieldSubmitted;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      maxLines: maxLines,
      minLines: minLines,
      readOnly: readOnly,
      onTap: onTap,
      onFieldSubmitted: onFieldSubmitted,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        prefixIcon: prefixIcon == null ? null : Icon(prefixIcon),
        suffixIcon: suffixIcon == null
            ? null
            : IconButton(
                onPressed: onSuffixPressed,
                icon: Icon(suffixIcon),
              ),
      ),
    );
  }
}

class AppSelectField extends StatelessWidget {
  const AppSelectField({
    super.key,
    required this.label,
    required this.value,
    required this.onTap,
    this.placeholder,
    this.trailingIcon = Icons.keyboard_arrow_down_rounded,
    this.isEnabled = true,
    this.error,
  });

  final String label;
  final String value;
  final String? placeholder;
  final VoidCallback onTap;
  final IconData trailingIcon;
  final bool isEnabled;
  final String? error;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final displayValue = value.isNotEmpty ? value : (placeholder ?? 'Select');

    return InkWell(
      onTap: isEnabled ? onTap : null,
      borderRadius: BorderRadius.circular(16),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          errorText: error,
          enabled: isEnabled,
          prefixIcon: const Icon(Icons.tune_rounded),
          suffixIcon: Icon(trailingIcon),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        child: Text(
          displayValue,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: value.isNotEmpty ? theme.colorScheme.onSurface : theme.colorScheme.onSurfaceVariant,
            fontWeight: value.isNotEmpty ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}
