import 'package:flutter/material.dart';

import 'phone_formatter.dart';

/// Big on-screen number pad (the iPad's own pad is a small floating popup that covers the field).
/// Keys feed [controller] through the dash formatter: 704-307-2102.
class PhoneKeypad extends StatelessWidget {
  const PhoneKeypad({super.key, required this.controller, this.onChanged});

  final TextEditingController controller;
  final VoidCallback? onChanged;

  void _set(String text) {
    controller.value = const PhoneDashFormatter().formatEditUpdate(
      controller.value,
      TextEditingValue(text: text),
    );
    onChanged?.call();
  }

  Widget _key(BuildContext context, {String? label, IconData? icon, required VoidCallback onTap, Color? color}) {
    return Padding(
      padding: const EdgeInsets.all(6),
      child: Material(
        color: color ?? Colors.white,
        borderRadius: BorderRadius.circular(20),
        elevation: 1,
        shadowColor: const Color(0x22000000),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: SizedBox(
            height: 84,
            child: Center(
              child: icon != null
                  ? Icon(icon, size: 36, color: const Color(0xFF4338CA))
                  : Text(label!, style: const TextStyle(fontSize: 40, fontWeight: FontWeight.w700, color: Color(0xFF312E81))),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget digit(String d) => Expanded(child: _key(context, label: d, onTap: () => _set(controller.text + d)));
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 520),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final row in const [['1', '2', '3'], ['4', '5', '6'], ['7', '8', '9']])
            Row(children: [for (final d in row) digit(d)]),
          Row(
            children: [
              Expanded(child: _key(context, icon: Icons.clear_rounded, color: const Color(0xFFE0E7FF), onTap: () => _set(''))),
              digit('0'),
              Expanded(
                child: _key(
                  context,
                  icon: Icons.backspace_outlined,
                  color: const Color(0xFFE0E7FF),
                  onTap: () {
                    final t = controller.text;
                    _set(t.isEmpty ? '' : t.substring(0, t.length - 1));
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
