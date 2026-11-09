import 'package:flutter/material.dart';

import 'checkin_form_screen.dart';
import 'checkin_request.dart';
import 'checkin_success_dialog.dart';
import 'host_search_field.dart';
import 'reception_api_service.dart';
import 'reception_host.dart';
import 'visitor.dart';

class ReturningVisitorScreen extends StatefulWidget {
  const ReturningVisitorScreen({super.key});

  @override
  State<ReturningVisitorScreen> createState() => _ReturningVisitorScreenState();
}

class _ReturningVisitorScreenState extends State<ReturningVisitorScreen> {
  final _phoneController = TextEditingController();
  final _apiService = ReceptionApiService();

  bool _isSearching = false;
  bool _isSubmitting = false;
  bool _searched = false;
  ReceptionHost? _selectedHost;
  Visitor? _visitor;
  String? _errorMessage;
  String? _hostValidationError;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _searchVisitor() async {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty) {
      setState(() => _errorMessage = 'Phone number is required');
      return;
    }

    setState(() {
      _isSearching = true;
      _errorMessage = null;
      _visitor = null;
      _selectedHost = null;
      _hostValidationError = null;
      _searched = false;
    });

    try {
      final visitor = await _apiService.lookupByPhone(phone);
      if (!mounted) {
        return;
      }
      setState(() {
        _isSearching = false;
        _searched = true;
        _visitor = visitor;
      });
      if (visitor != null) {
        await _prefillPreviousHost(visitor);
      }
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isSearching = false;
        _searched = true;
        _errorMessage = error.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Future<void> _prefillPreviousHost(Visitor visitor) async {
    final lastHostLabel = visitor.lastHostLabel;
    if (lastHostLabel == null || lastHostLabel.isEmpty) {
      return;
    }

    try {
      final results = await _apiService.searchHosts(lastHostLabel);
      if (!mounted) {
        return;
      }

      ReceptionHost? matchedHost;
      for (final host in results) {
        if (host.hostType == visitor.lastHostType && host.id == visitor.lastHostId) {
          matchedHost = host;
          break;
        }
      }

      if (matchedHost == null) {
        return;
      }

      setState(() {
        _selectedHost = matchedHost;
        _hostValidationError = null;
      });
    } catch (_) {
      // Leave host selection empty if the previous host can no longer be resolved.
    }
  }

  Future<void> _checkIn() async {
    if (_visitor == null) {
      return;
    }

    final host = _selectedHost;
    if (host == null) {
      setState(
        () => _hostValidationError = 'Please select a host before checking in.',
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    final response = await _apiService.checkIn(
      CheckInRequest(
        visitType: 'returning_visitor',
        fullName: _visitor!.name,
        phone: _visitor!.phone,
        email: _visitor!.email,
        hostType: host.hostType,
        hostId: host.id,
      ),
    );

    if (!mounted) {
      return;
    }

    setState(() => _isSubmitting = false);

    if (response.success) {
      await showCheckInSuccessDialog(
        context,
        title: 'Check-In Complete',
        message: '${response.guestName ?? _visitor!.name} is checked in.',
        guestCode: response.guestCode,
      );
      if (!mounted) {
        return;
      }
      Navigator.popUntil(context, (route) => route.isFirst);
      return;
    }

    setState(() => _errorMessage = response.message ?? 'Check-in failed.');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Returning Visitor')),
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
                      margin: EdgeInsets.all(MediaQuery.sizeOf(context).width < 600 ? 12 : 32),
                      child: Padding(
                        padding: EdgeInsets.all(MediaQuery.sizeOf(context).width < 600 ? 20 : 48),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Text(
                              'Find Your Details',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w600,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 32),
                            TextField(
                              controller: _phoneController,
                              keyboardType: TextInputType.phone,
                              decoration: InputDecoration(
                                labelText: 'Phone Number',
                                errorText: _errorMessage,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                filled: true,
                                fillColor: Colors.grey[50],
                                prefixIcon: const Icon(Icons.phone),
                              ),
                              style: const TextStyle(fontSize: 22),
                              onSubmitted: (_) => _searchVisitor(),
                            ),
                            const SizedBox(height: 24),
                            SizedBox(
                              height: 64,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Theme.of(
                                    context,
                                  ).colorScheme.primary,
                                  foregroundColor: Theme.of(
                                    context,
                                  ).colorScheme.onPrimary,
                                ),
                                onPressed: _isSearching ? null : _searchVisitor,
                                child: _isSearching
                                    ? const CircularProgressIndicator(
                                        color: Colors.white,
                                      )
                                    : const Text(
                                        'Search',
                                        style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                              ),
                            ),
                            if (_searched &&
                                _visitor == null &&
                                !_isSearching) ...[
                              const SizedBox(height: 40),
                              const Icon(
                                Icons.person_off_rounded,
                                size: 64,
                                color: Colors.grey,
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'No previous visitor was found for that phone number.',
                                style: TextStyle(fontSize: 20),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 24),
                              SizedBox(
                                height: 64,
                                child: OutlinedButton(
                                  style: OutlinedButton.styleFrom(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                  onPressed: () => Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => CheckInFormScreen(
                                        title: 'Walk-In',
                                        visitType: 'walk_in',
                                        initialPhone: _phoneController.text
                                            .trim(),
                                      ),
                                    ),
                                  ),
                                  child: const Text(
                                    'Continue as New Visitor',
                                    style: TextStyle(fontSize: 18),
                                  ),
                                ),
                              ),
                            ],
                            if (_visitor != null) ...[
                              const SizedBox(height: 40),
                              Container(
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  color: Colors.blueGrey.shade50,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Column(
                                  children: [
                                    Text(
                                      'Welcome back, ${_visitor!.name}!',
                                      style: const TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 8),
                                    if (_visitor!.lastVisited != null)
                                      Text(
                                        'Last visit: ${_formatDateTime(_visitor!.lastVisited!)}',
                                        style: TextStyle(
                                          fontSize: 18,
                                          color: Colors.grey[700],
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    if (_visitor!.lastHostLabel != null) ...[
                                      const SizedBox(height: 8),
                                      Text(
                                        'Previous host: ${_visitor!.lastHostLabel}',
                                        style: TextStyle(
                                          fontSize: 18,
                                          color: Colors.grey[700],
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              const SizedBox(height: 24),
                              HostSearchField(
                                searchHosts: _apiService.searchHosts,
                                selectedHost: _selectedHost,
                                errorText: _hostValidationError,
                                fillColor: Colors.grey[50],
                                onSelected: (host) {
                                  setState(() {
                                    _selectedHost = host;
                                    _hostValidationError = null;
                                  });
                                },
                              ),
                              if (_visitor!.lastHostLabel != null) ...[
                                const SizedBox(height: 12),
                                Text(
                                  'Previous host: ${_visitor!.lastHostLabel}. Search again if you are visiting someone new.',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey[700],
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                              const SizedBox(height: 32),
                              SizedBox(
                                height: 64,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green.shade600,
                                    foregroundColor: Colors.white,
                                  ),
                                  onPressed: _isSubmitting ? null : _checkIn,
                                  child: _isSubmitting
                                      ? const CircularProgressIndicator(
                                          color: Colors.white,
                                        )
                                      : const Text(
                                          'Confirm Check-In',
                                          style: TextStyle(
                                            fontSize: 22,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                ),
                              ),
                            ],
                          ],
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

  String _formatDateTime(String value) {
    final parsed = DateTime.tryParse(value);
    if (parsed == null) {
      return value;
    }

    final hour = parsed.hour == 0
        ? 12
        : (parsed.hour > 12 ? parsed.hour - 12 : parsed.hour);
    final minute = parsed.minute.toString().padLeft(2, '0');
    final suffix = parsed.hour >= 12 ? 'PM' : 'AM';
    return '${parsed.month}/${parsed.day}/${parsed.year} at $hour:$minute $suffix';
  }
}
