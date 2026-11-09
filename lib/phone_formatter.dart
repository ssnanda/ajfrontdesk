import 'package:flutter/services.dart';

/// Digits only, shown as 704-307-2102 while typing (US numbers, 10 digits).
class PhoneDashFormatter extends TextInputFormatter {
  const PhoneDashFormatter();

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    var digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    if (digits.length > 10) {
      digits = digits.substring(0, 10);
    }
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i == 3 || i == 6) {
        buffer.write('-');
      }
      buffer.write(digits[i]);
    }
    final text = buffer.toString();
    return TextEditingValue(text: text, selection: TextSelection.collapsed(offset: text.length));
  }
}
