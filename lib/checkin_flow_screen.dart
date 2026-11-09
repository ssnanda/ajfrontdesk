import 'dart:async';

import 'package:flutter/material.dart';

import 'checkin_request.dart';
import 'checkin_success_dialog.dart';
import 'reception_api_service.dart';
import 'reception_host.dart';

/// Check-in as a short conversation: who are you here to see -> your name and number -> do you have an appointment.
/// The search box sits at the top, so the results list gets all the room between it and the keyboard.
class CheckInFlowScreen extends StatefulWidget {
  const CheckInFlowScreen({super.key, this.initialPhone});

  final String? initialPhone;

  @override
  State<CheckInFlowScreen> createState() => _CheckInFlowScreenState();
}

enum _Step { host, details, appointment }

class _CheckInFlowScreenState extends State<CheckInFlowScreen> {
  final _api = ReceptionApiService();
  final _search = TextEditingController();
  final _searchFocus = FocusNode();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _detailsKey = GlobalKey<FormState>();

  _Step _step = _Step.host;
  ReceptionHost? _host;
  Timer? _debounce;
  int _requestId = 0;
  List<ReceptionHost> _results = const [];
  bool _searching = false;
  String? _searchError;
  String _query = '';
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _phone.text = widget.initialPhone ?? '';
  }

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
      _step = _Step.details;
    });
  }

  void _back() {
    switch (_step) {
      case _Step.host:
        Navigator.of(context).maybePop();
      case _Step.details:
        setState(() => _step = _Step.host);
      case _Step.appointment:
        setState(() => _step = _Step.details);
    }
  }

  void _next() {
    if (_detailsKey.currentState!.validate()) {
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
    prefixIcon: Icon(icon),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide.none,
    ),
    filled: true,
    fillColor: Colors.grey[100],
    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
  );

  Widget _question(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 20),
    child: Text(
      text,
      textAlign: TextAlign.center,
      style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w600),
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
            style: const TextStyle(fontSize: 22),
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
                ? Text(_searchError!, style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 16))
                : _results.isEmpty
                ? Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(
                      _query.isEmpty
                          ? 'Start typing to find them.'
                          : (_searching ? '' : 'No one found. Try a different name or company.'),
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 18, color: Colors.grey[600]),
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
                        borderRadius: BorderRadius.circular(16),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () => _pick(host),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                            child: Row(
                              children: [
                                Expanded(child: Text(host.label, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600))),
                                Icon(Icons.chevron_right, color: Colors.grey[400], size: 28),
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

  Widget _detailsStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: Form(
            key: _detailsKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _question('Great, ${_host?.label}. What\'s your name and number?'),
                TextFormField(
                  controller: _name,
                  autofocus: true,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  style: const TextStyle(fontSize: 22),
                  decoration: _decoration('Full Name', Icons.person_outline),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Name is required' : null,
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _phone,
                  keyboardType: TextInputType.phone,
                  style: const TextStyle(fontSize: 22),
                  decoration: _decoration('Phone Number', Icons.phone_outlined),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Phone is required' : null,
                  onFieldSubmitted: (_) => _next(),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  height: 64,
                  child: ElevatedButton(
                    onPressed: _next,
                    child: const Text('Next', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _appointmentStep() {
    Widget choice(String label, IconData icon, bool value) => SizedBox(
      height: 88,
      child: ElevatedButton.icon(
        onPressed: _submitting ? null : () => _submit(value),
        icon: Icon(icon, size: 30),
        label: Text(label, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w600)),
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
                choice('Yes, I have an appointment', Icons.event_available_rounded, true),
                const SizedBox(height: 16),
                choice('No, I just stopped by', Icons.directions_walk_rounded, false),
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
          child: switch (_step) {
            _Step.host => _hostStep(),
            _Step.details => _detailsStep(),
            _Step.appointment => _appointmentStep(),
          },
        ),
      ),
    );
  }
}
