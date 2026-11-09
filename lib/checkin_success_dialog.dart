import 'package:flutter/material.dart';

Future<void> showCheckInSuccessDialog(
  BuildContext context, {
  required String title,
  required String message,
  String? guestCode,
}) {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (context) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Text(title, textAlign: TextAlign.center),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 18),
          ),
          if (guestCode != null && guestCode.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Text('Guest ID', style: TextStyle(fontSize: 14, color: Colors.black54)),
            Text(
              guestCode,
              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w700, letterSpacing: 1),
            ),
          ],
        ],
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
