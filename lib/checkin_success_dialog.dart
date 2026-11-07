import 'package:flutter/material.dart';

Future<void> showCheckInSuccessDialog(
  BuildContext context, {
  required String title,
  required String message,
}) {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (context) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Text(title, textAlign: TextAlign.center),
      content: Text(
        message,
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 18),
      ),
      actionsAlignment: MainAxisAlignment.center,
      actions: [
        SizedBox(
          width: 180,
          child: FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Done'),
          ),
        ),
      ],
    ),
  );
}
