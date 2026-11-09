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
      title: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_circle_rounded, color: Color(0xFF16A34A), size: 84),
          const SizedBox(height: 12),
          Text(title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w800)),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 26),
          ),
          if (guestCode != null && guestCode.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Text('Guest ID', style: TextStyle(fontSize: 22, color: Colors.black54)),
            Text(
              // G-20261109-001 -> 001: guests only see their number for the day; staff see the full ID in AJOps.
              guestCode.split('-').last,
              style: const TextStyle(fontSize: 72, fontWeight: FontWeight.w800, color: Color(0xFF4338CA), letterSpacing: 2),
            ),
          ],
        ],
      ),
      actionsAlignment: MainAxisAlignment.center,
      actions: [
        SizedBox(
          width: 240,
          height: 64,
          child: FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Done', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700)),
          ),
        ),
      ],
    ),
  );
}
