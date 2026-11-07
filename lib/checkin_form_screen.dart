import 'package:flutter/material.dart';

import 'checkin_request.dart';
import 'checkin_success_dialog.dart';
import 'host_search_field.dart';
import 'reception_api_service.dart';
import 'reception_host.dart';

class CheckInFormScreen extends StatefulWidget {
  const CheckInFormScreen({
    super.key,
    required this.title,
    required this.visitType,
    this.initialPhone,
  });

  final String title;
  final String visitType;
  final String? initialPhone;

  @override
  State<CheckInFormScreen> createState() => _CheckInFormScreenState();
}

class _CheckInFormScreenState extends State<CheckInFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _apiService = ReceptionApiService();

  ReceptionHost? _selectedHost;
  bool _isSubmitting = false;
  String? _hostValidationError;

  @override
  void initState() {
    super.initState();
    _phoneController.text = widget.initialPhone ?? '';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final formIsValid = _formKey.currentState!.validate();
    final host = _selectedHost;
    setState(() {
      _hostValidationError = host == null ? 'Please select a host' : null;
    });
    if (!formIsValid || host == null) {
      return;
    }

    setState(() => _isSubmitting = true);
    final response = await _apiService.checkIn(
      CheckInRequest(
        visitType: widget.visitType,
        fullName: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        hostType: host.hostType,
        hostId: host.id,
      ),
    );

    if (!mounted) {
      return;
    }

    setState(() => _isSubmitting = false);

    if (response.success) {
      final guestName = response.guestName ?? _nameController.text.trim();
      await showCheckInSuccessDialog(
        context,
        title: 'Check-In Complete',
        message: '$guestName is checked in for ${widget.title.toLowerCase()}.',
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
    final inputDecoration = InputDecoration(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      filled: true,
      fillColor: Colors.grey[100],
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
    );

    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 640),
                    child: Card(
                      elevation: 0,
                      color: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      margin: const EdgeInsets.all(32),
                      child: Padding(
                        padding: const EdgeInsets.all(48),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                widget.title == 'Appointment'
                                    ? 'Confirm Your Scheduled Visit'
                                    : 'Tell Us Who You\'re Here To See',
                                style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w600,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 40),
                              TextFormField(
                                controller: _nameController,
                                decoration: inputDecoration.copyWith(
                                  labelText: 'Full Name',
                                  prefixIcon: const Icon(Icons.person_outline),
                                ),
                                style: const TextStyle(fontSize: 20),
                                validator: (value) =>
                                    value == null || value.trim().isEmpty
                                    ? 'Name is required'
                                    : null,
                              ),
                              const SizedBox(height: 24),
                              TextFormField(
                                controller: _phoneController,
                                keyboardType: TextInputType.phone,
                                decoration: inputDecoration.copyWith(
                                  labelText: 'Phone Number',
                                  prefixIcon: const Icon(Icons.phone_outlined),
                                ),
                                style: const TextStyle(fontSize: 20),
                                validator: (value) =>
                                    value == null || value.trim().isEmpty
                                    ? 'Phone is required'
                                    : null,
                              ),
                              const SizedBox(height: 24),
                              HostSearchField(
                                searchHosts: _apiService.searchHosts,
                                selectedHost: _selectedHost,
                                errorText: _hostValidationError,
                                fillColor: Colors.grey[100],
                                onSelected: (host) {
                                  setState(() {
                                    _selectedHost = host;
                                    _hostValidationError = null;
                                  });
                                },
                              ),
                              const SizedBox(height: 48),
                              SizedBox(
                                height: 64,
                                child: ElevatedButton(
                                  onPressed: _isSubmitting ? null : _submit,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                    foregroundColor: Theme.of(
                                      context,
                                    ).colorScheme.onPrimary,
                                  ),
                                  child: _isSubmitting
                                      ? const CircularProgressIndicator(
                                          color: Colors.white,
                                        )
                                      : const Text(
                                          'Complete Check-In',
                                          style: TextStyle(
                                            fontSize: 22,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
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
            );
          },
        ),
      ),
    );
  }
}
