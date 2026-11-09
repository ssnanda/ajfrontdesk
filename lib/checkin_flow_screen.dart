import 'dart:async';

import 'package:flutter/material.dart';

import 'checkin_request.dart';
import 'checkin_success_dialog.dart';
import 'phone_keypad.dart';
import 'reception_api_service.dart';
import 'reception_host.dart';

/// Check-in as a short conversation: who are you here to see -> your phone number (a returning guest's name is filled in
/// from it) -> your name -> do you have an appointment. The search box sits at the top, so the results list gets all the
/// room between it and the keyboard.
class CheckInFlowScreen extends StatefulWidget {
  const CheckInFlowScreen({super.key});

  @override
  State<CheckInFlowScreen> createState() => _CheckInFlowScreenState();
}

enum _Step { host, phone, name, appointment }

class _CheckInFlowScreenState extends State<CheckInFlowScreen> {
  final _api = ReceptionApiService();
  final _search = TextEditingController();
  final _searchFocus = FocusNode();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _phoneKey = GlobalKey<FormState>();
  final _nameKey = GlobalKey<FormState>();

  _Step _step = _Step.host;
  ReceptionHost? _host;
  Timer? _debounce;
  int _requestId = 0;
  List<ReceptionHost> _results = const [];
  bool _searching = false;
  String? _searchError;
  String _query = '';
  bool _submitting = false;
  bool _lookingUp = false;
  bool _returning = false; // the phone number matched a guest we already know

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    _searchFocus.dispose();
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    final query = value.trim();
    setState(() {
      _query = query;
      _searchError = null;
      if (query.isEmpty) {
        _results = const [];
        _searching = false;
      } else {
        _searching = true;
      }
    });
    if (query.isEmpty) {
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 250), () => _runSearch(query));
  }

  Future<void> _runSearch(String query) async {
    final id = ++_requestId;
    try {
      final results = await _api.searchHosts(query);
      if (!mounted || id != _requestId) {
        return;
      }
      setState(() {
        _results = results;
        _searching = false;
      });
    } catch (error) {
      if (!mounted || id != _requestId) {
        return;
      }
      setState(() {
        _results = const [];
        _searching = false;
        _searchError = error.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  void _pick(ReceptionHost host) {
    _searchFocus.unfocus();
    setState(() {
      _host = host;
      _step = _Step.phone;
    });
  }

  void _back() {
    switch (_step) {
      case _Step.host:
        Navigator.of(context).maybePop();
      case _Step.phone:
        setState(() => _step = _Step.host);
      case _Step.name:
        setState(() => _step = _Step.phone);
      case _Step.appointment:
        setState(() => _step = _Step.name);
    }
  }

  /// Looks the number up: a known guest gets their name filled in, anyone else is asked for it.
  Future<void> _phoneNext() async {
    if (!_phoneKey.currentState!.validate() || _lookingUp) {
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() => _lookingUp = true);
    var returning = false;
    try {
      final visitor = await _api.lookupByPhone(_phone.text.trim());
      if (visitor != null && visitor.name.trim().isNotEmpty) {
        _name.text = visitor.name.trim();
        returning = true;
      } else {
        _name.clear();
      }
    } catch (_) {
      // Lookup is a convenience: if it fails, just ask for the name.
      _name.clear();
    }
    if (!mounted) {
      return;
    }
    setState(() {
      _lookingUp = false;
      _returning = returning;
      _step = _Step.name;
    });
  }

  void _nameNext() {
    if (_nameKey.currentState!.validate()) {
      FocusScope.of(context).unfocus();
      setState(() => _step = _Step.appointment);
    }
  }

  Future<void> _submit(bool hasAppointment) async {
    final host = _host;
    if (host == null || _submitting) {
      return;
    }
    setState(() => _submitting = true);
    final response = await _api.checkIn(
      CheckInRequest(
        visitType: hasAppointment ? 'appointment' : 'walk_in',
        fullName: _name.text.trim(),
        phone: _phone.text.trim(),
        hostType: host.hostType,
        hostId: host.id,
      ),
    );
    if (!mounted) {
      return;
    }
    setState(() => _submitting = false);

    if (response.success) {
      await showCheckInSuccessDialog(
        context,
        title: 'Check-In Complete',
        message: '${response.guestName ?? _name.text.trim()} is checked in to see ${host.label}.',
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

  InputDecoration _decoration(String label, IconData icon) => InputDecoration(
    labelText: label,
    labelStyle: const TextStyle(fontSize: 22),
    floatingLabelStyle: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: Color(0xFF4338CA)),
    prefixIcon: Icon(icon, size: 30, color: const Color(0xFF4F46E5)),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide.none),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: const BorderSide(color: Color(0xFFC7D2FE), width: 2)),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: const BorderSide(color: Color(0xFF4F46E5), width: 3)),
    filled: true,
    fillColor: Colors.white,
    contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
  );

  Widget _question(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 20),
    child: Text(
      text,
      textAlign: TextAlign.center,
      style: const TextStyle(fontSize: 40, fontWeight: FontWeight.w800, color: Color(0xFF312E81), height: 1.15),
    ),
  );

  Widget _hostStep() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _question('Who are you here to see?'),
          TextField(
            controller: _search,
            focusNode: _searchFocus,
            autofocus: true,
            textInputAction: TextInputAction.search,
            onChanged: _onSearchChanged,
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w600),
            decoration: _decoration('Type a name or company', Icons.search).copyWith(
              suffixIcon: _searching
                  ? const Padding(
                      padding: EdgeInsets.all(14),
                      child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.2)),
                    )
                  : null,
            ),
          ),
          const SizedBox(height: 12),
          // Everything between the search box and the keyboard belongs to the results.
          Expanded(
            child: _searchError != null
                ? Text(_searchError!, style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 22))
                : _results.isEmpty
                ? Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(
                      _query.isEmpty
                          ? 'Start typing to find them.'
                          : (_searching ? '' : 'No one found. Try a different name or company.'),
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 24, color: Colors.grey[700]),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.only(bottom: 12),
                    itemCount: _results.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final host = _results[index];
                      return Material(
                        color: Colors.white,
                        elevation: 1,
                        shadowColor: const Color(0x22000000),
                        borderRadius: BorderRadius.circular(20),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(20),
                          onTap: () => _pick(host),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 26,
                                  backgroundColor: const Color(0xFFE0E7FF),
                                  child: Text(
                                    host.label.isEmpty ? '?' : host.label.trim()[0].toUpperCase(),
                                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Color(0xFF4338CA)),
                                  ),
                                ),
                                const SizedBox(width: 18),
                                Expanded(child: Text(host.label, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700))),
                                const Icon(Icons.chevron_right_rounded, color: Color(0xFF6366F1), size: 36),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _formStep({required GlobalKey<FormState> formKey, required String question, required Widget field, required VoidCallback onNext, bool busy = false}) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: Form(
            key: formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _question(question),
                field,
                const SizedBox(height: 32),
                SizedBox(
                  height: 80,
                  child: ElevatedButton(
                    onPressed: busy ? null : onNext,
                    child: busy
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Next', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _phoneStep() {
    return _formStep(
      formKey: _phoneKey,
      question: 'What\'s your phone number?',
      busy: _lookingUp,
      onNext: _phoneNext,
      field: Column(
        children: [
          TextFormField(
            controller: _phone,
            readOnly: true, // typed with the big keypad below, so the OS keypad never covers the field
            showCursor: true,
            keyboardType: TextInputType.none,
            style: const TextStyle(fontSize: 40, fontWeight: FontWeight.w800, letterSpacing: 2),
            textAlign: TextAlign.center,
            decoration: _decoration('Phone Number', Icons.phone_outlined),
            validator: (v) => v == null || v.trim().length < 10 ? 'Enter all 10 digits' : null,
          ),
          const SizedBox(height: 16),
          PhoneKeypad(controller: _phone),
        ],
      ),
    );
  }

  Widget _nameStep() {
    final first = _name.text.trim().split(RegExp(r'\s+')).first;
    return _formStep(
      formKey: _nameKey,
      question: _returning ? 'Welcome back, $first! Is this your name?' : 'Nice to meet you! What\'s your name?',
      onNext: _nameNext,
      field: TextFormField(
        controller: _name,
        autofocus: true,
        textCapitalization: TextCapitalization.words,
        style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w600),
        decoration: _decoration('Full Name', Icons.person_outline),
        validator: (v) => v == null || v.trim().isEmpty ? 'Name is required' : null,
        onFieldSubmitted: (_) => _nameNext(),
      ),
    );
  }

  Widget _appointmentStep() {
    Widget choice(String label, IconData icon, bool value, Color color) => SizedBox(
      height: 120,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(backgroundColor: color, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28))),
        onPressed: _submitting ? null : () => _submit(value),
        icon: Icon(icon, size: 42),
        label: Text(label, style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w800)),
      ),
    );
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _question('Do you have an appointment with ${_host?.label}?'),
              if (_submitting)
                const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()))
              else ...[
                choice('Yes, I have an appointment', Icons.event_available_rounded, true, const Color(0xFF16A34A)),
                const SizedBox(height: 20),
                choice('No, I just stopped by', Icons.directions_walk_rounded, false, const Color(0xFFF59E0B)),
              ],
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _step == _Step.host,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          _back();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Check In'),
          leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: _back),
        ),
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 4, 24, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Step ${_step.index + 1} of ${_Step.values.length}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Color(0xFF4338CA))),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: (_step.index + 1) / _Step.values.length,
                        minHeight: 12,
                        backgroundColor: const Color(0xFFC7D2FE),
                        color: const Color(0xFF4F46E5),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: switch (_step) {
                  _Step.host => _hostStep(),
                  _Step.phone => _phoneStep(),
                  _Step.name => _nameStep(),
                  _Step.appointment => _appointmentStep(),
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
