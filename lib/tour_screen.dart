import 'package:flutter/material.dart';

import 'checkin_request.dart';
import 'checkin_success_dialog.dart';
import 'phone_keypad.dart';
import 'reception_api_service.dart';

/// Tour: a prospect here to look at suites. No host to pick; the point is capturing their details.
class TourScreen extends StatefulWidget {
  const TourScreen({super.key});

  @override
  State<TourScreen> createState() => _TourScreenState();
}

class _TourScreenState extends State<TourScreen> {
  static const _interests = [
    'Private office',
    'Coworking / desk',
    'Virtual office / mailing address',
    'Meeting room',
    'Not sure yet',
  ];

  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _company = TextEditingController();
  final _teamSize = TextEditingController();
  final _notes = TextEditingController();
  final _apiService = ReceptionApiService();

  final Set<String> _selected = {};
  bool _isSubmitting = false;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _email.dispose();
    _company.dispose();
    _teamSize.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _openKeypad() async {
    FocusScope.of(context).unfocus();
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFFEEF2FF),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ValueListenableBuilder<TextEditingValue>(
                valueListenable: _phone,
                builder: (_, value, _) => Text(
                  value.text.isEmpty ? 'Phone Number' : value.text,
                  style: TextStyle(fontSize: 44, fontWeight: FontWeight.w800, letterSpacing: 2, color: value.text.isEmpty ? Colors.black38 : const Color(0xFF115E59)),
                ),
              ),
              const SizedBox(height: 12),
              PhoneKeypad(controller: _phone),
              const SizedBox(height: 8),
              SizedBox(
                width: 520,
                height: 72,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0D9488)),
                  onPressed: () => Navigator.of(sheetContext).pop(),
                  child: const Text('Done', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (mounted) {
      _formKey.currentState?.validate();
    }
  }

  /// Keyboard-free typing aid: "@gmail.com" replaces whatever follows an "@" (or is added after the name), ".com" is appended.
  void _addEmailShortcut(String shortcut) {
    var text = _email.text.trim();
    if (shortcut.startsWith('@')) {
      final at = text.indexOf('@');
      if (at >= 0) {
        text = text.substring(0, at);
      }
      if (text.isEmpty) {
        return; // type the name first
      }
      text += shortcut;
    } else {
      if (text.isEmpty || text.endsWith(shortcut)) {
        return;
      }
      text += shortcut;
    }
    _email.value = TextEditingValue(text: text, selection: TextSelection.collapsed(offset: text.length));
  }

  /// Everything the visit record has no column for goes into its note, one labelled line each.
  String _composeNotes() {
    final lines = <String>[
      if (_company.text.trim().isNotEmpty) 'Company: ${_company.text.trim()}',
      if (_selected.isNotEmpty) 'Interested in: ${_selected.join(', ')}',
      if (_teamSize.text.trim().isNotEmpty) 'Team size: ${_teamSize.text.trim()}',
      if (_notes.text.trim().isNotEmpty) 'Notes: ${_notes.text.trim()}',
    ];
    return lines.join('\n');
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() => _isSubmitting = true);
    final response = await _apiService.checkIn(
      CheckInRequest(
        visitType: 'tour',
        fullName: _name.text.trim(),
        phone: _phone.text.trim(),
        hostType: 'tour',
        hostId: '',
        email: _email.text.trim().isEmpty ? null : _email.text.trim(),
        notes: _composeNotes().isEmpty ? null : _composeNotes(),
      ),
    );
    if (!mounted) {
      return;
    }
    setState(() => _isSubmitting = false);

    if (response.success) {
      await showCheckInSuccessDialog(
        context,
        title: 'Thank You!',
        message: '${response.guestName ?? _name.text.trim()}, someone will be with you shortly for your tour.',
        guestCode: response.guestCode,
      );
      if (!mounted) {
        return;
      }
      Navigator.popUntil(context, (route) => route.isFirst);
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(response.message ?? 'Check-in failed.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 600;
    const teal = Color(0xFF0F766E);
    final decoration = InputDecoration(
      labelStyle: const TextStyle(fontSize: 22),
      floatingLabelStyle: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: teal),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: const BorderSide(color: Color(0xFF99F6E4), width: 2)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: const BorderSide(color: Color(0xFF14B8A6), width: 3)),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 26),
    );
    const fieldStyle = TextStyle(fontSize: 26, fontWeight: FontWeight.w600);

    return Scaffold(
      appBar: AppBar(title: const Text('Tour')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: Card(
                elevation: 0,
                color: const Color(0xFFF0FDFA),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
                margin: EdgeInsets.all(compact ? 12 : 32),
                child: Padding(
                  padding: EdgeInsets.all(compact ? 20 : 48),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'Tell Us About Yourself',
                          style: TextStyle(fontSize: 40, fontWeight: FontWeight.w800, color: Color(0xFF115E59)),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 32),
                        TextFormField(
                          controller: _name,
                          textCapitalization: TextCapitalization.words,
                          decoration: decoration.copyWith(labelText: 'Full Name', prefixIcon: const Icon(Icons.person_outline, size: 30, color: teal)),
                          style: fieldStyle,
                          validator: (v) => v == null || v.trim().isEmpty ? 'Name is required' : null,
                        ),
                        const SizedBox(height: 26),
                        TextFormField(
                          controller: _phone,
                          readOnly: true, // tap to open the big keypad
                          showCursor: false,
                          keyboardType: TextInputType.none,
                          onTap: _openKeypad,
                          decoration: decoration.copyWith(labelText: 'Phone Number', prefixIcon: const Icon(Icons.phone_outlined, size: 30, color: teal)),
                          style: fieldStyle,
                          validator: (v) => v == null || v.trim().length < 10 ? 'Enter all 10 digits' : null,
                        ),
                        const SizedBox(height: 26),
                        TextFormField(
                          controller: _email,
                          keyboardType: TextInputType.emailAddress,
                          autocorrect: false,
                          enableSuggestions: false,
                          decoration: decoration.copyWith(labelText: 'Email', prefixIcon: const Icon(Icons.mail_outline, size: 30, color: teal)),
                          style: fieldStyle,
                          validator: (v) {
                            final t = v?.trim() ?? '';
                            if (t.isEmpty) return 'Email is required';
                            return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(t) ? null : 'Enter a valid email';
                          },
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (final shortcut in const ['@gmail.com', '@yahoo.com', '@outlook.com', '@icloud.com', '.com'])
                              ActionChip(
                                label: Text(shortcut, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
                                backgroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
                                onPressed: () => _addEmailShortcut(shortcut),
                              ),
                          ],
                        ),
                        const SizedBox(height: 26),
                        TextFormField(
                          controller: _company,
                          textCapitalization: TextCapitalization.words,
                          decoration: decoration.copyWith(labelText: 'Company (optional)', prefixIcon: const Icon(Icons.business_outlined, size: 30, color: teal)),
                          style: fieldStyle,
                        ),
                        const SizedBox(height: 28),
                        const Text('What are you looking for?', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: Color(0xFF115E59))),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            for (final option in _interests)
                              FilterChip(
                                label: Text(option, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600)),
                                selected: _selected.contains(option),
                                selectedColor: const Color(0xFF5EEAD4),
                                checkmarkColor: const Color(0xFF115E59),
                                backgroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
                                onSelected: (on) => setState(() => on ? _selected.add(option) : _selected.remove(option)),
                              ),
                          ],
                        ),
                        const SizedBox(height: 26),
                        TextFormField(
                          controller: _teamSize,
                          keyboardType: TextInputType.number,
                          decoration: decoration.copyWith(labelText: 'How many people? (optional)', prefixIcon: const Icon(Icons.groups_outlined, size: 30, color: teal)),
                          style: fieldStyle,
                        ),
                        const SizedBox(height: 26),
                        TextFormField(
                          controller: _notes,
                          maxLines: 3,
                          decoration: decoration.copyWith(labelText: 'Anything else we should know? (optional)'),
                          style: fieldStyle,
                        ),
                        const SizedBox(height: 40),
                        SizedBox(
                          height: 84,
                          child: ElevatedButton(
                            onPressed: _isSubmitting ? null : _submit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0D9488),
                              foregroundColor: Colors.white,
                            ),
                            child: _isSubmitting
                                ? const CircularProgressIndicator(color: Colors.white)
                                : const Text('Submit', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
