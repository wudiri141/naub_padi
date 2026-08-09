import 'package:flutter/material.dart';

Future<T> runDownloadWithProgress<T>({
  required BuildContext context,
  required String title,
  required Future<T> Function(void Function(double progress)) action,
}) async {
  final navigator = Navigator.of(context, rootNavigator: true);
  double? progress;
  StateSetter? setDialogState;

  final dialogFuture = showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) {
      return StatefulBuilder(
        builder: (context, setState) {
          setDialogState = setState;
          final showDeterminateProgress = progress != null && progress! > 0 && progress! <= 1;

          return AlertDialog(
            title: Text(title),
            content: PopScope(
              canPop: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  LinearProgressIndicator(value: showDeterminateProgress ? progress : null),
                  const SizedBox(height: 16),
                  Text(
                    showDeterminateProgress
                        ? '${(progress! * 100).toStringAsFixed(0)}%'
                        : 'Preparing download...',
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );

  try {
    final result = await action((value) {
      progress = value.clamp(0.0, 1.0).toDouble();
      if (setDialogState != null) {
        setDialogState!(() {});
      }
    });

    if (navigator.canPop()) {
      navigator.pop();
    }
    await dialogFuture;
    return result;
  } catch (_) {
    if (navigator.canPop()) {
      navigator.pop();
    }
    await dialogFuture.catchError((_) {});
    rethrow;
  }
}
