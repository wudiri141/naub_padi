import 'package:flutter/material.dart';

import '../../models/question_paper_model.dart';

class QuestionPaperMetadata extends StatelessWidget {
  const QuestionPaperMetadata({
    super.key,
    required this.paper,
    this.compact = false,
  });

  final QuestionPaperModel paper;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textStyle = (compact ? theme.textTheme.labelSmall : theme.textTheme.labelMedium)?.copyWith(
      fontWeight: FontWeight.w700,
    );

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _MetaChip(
          label: paper.level,
          color: theme.colorScheme.primaryContainer,
          textColor: theme.colorScheme.onPrimaryContainer,
          style: textStyle,
        ),
        _MetaChip(
          label: paper.examType,
          color: theme.colorScheme.secondaryContainer,
          textColor: theme.colorScheme.onSecondaryContainer,
          style: textStyle,
        ),
        _MetaChip(
          label: paper.sessionLabel,
          color: theme.colorScheme.tertiary.withValues(alpha: theme.brightness == Brightness.dark ? 0.18 : 0.16),
          textColor: theme.colorScheme.tertiary,
          style: textStyle,
        ),
      ],
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({
    required this.label,
    required this.color,
    required this.textColor,
    required this.style,
  });

  final String label;
  final Color color;
  final Color textColor;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(label, style: style?.copyWith(color: textColor)),
    );
  }
}
