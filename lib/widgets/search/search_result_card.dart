import 'package:flutter/material.dart';

import '../../models/question_paper_model.dart';
import '../question_papers/question_paper_card.dart';

class SearchResultCard extends StatelessWidget {
  const SearchResultCard({
    super.key,
    required this.paper,
    required this.onTap,
    required this.onDownload,
    required this.onBookmark,
  });

  final QuestionPaperModel paper;
  final VoidCallback onTap;
  final VoidCallback onDownload;
  final VoidCallback onBookmark;

  @override
  Widget build(BuildContext context) {
    return QuestionPaperCard(
      paper: paper,
      onOpen: onTap,
      onDownload: onDownload,
      onBookmark: onBookmark,
      onShare: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Share ${paper.displayCourseCode}')),
        );
      },
    );
  }
}

