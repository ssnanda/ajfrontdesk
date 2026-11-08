import 'dart:async';

import 'package:flutter/material.dart';

import 'reception_host.dart';

class HostSearchField extends StatefulWidget {
  const HostSearchField({
    super.key,
    required this.searchHosts,
    required this.onSelected,
    this.selectedHost,
    this.labelText = 'Who are you here to see?',
    this.hintText = 'Type to search by host name or entity',
    this.fillColor,
    this.enabled = true,
    this.errorText,
  });

  final Future<List<ReceptionHost>> Function(String query) searchHosts;
  final ValueChanged<ReceptionHost?> onSelected;
  final ReceptionHost? selectedHost;
  final String labelText;
  final String hintText;
  final Color? fillColor;
  final bool enabled;
  final String? errorText;

  @override
  State<HostSearchField> createState() => _HostSearchFieldState();
}

class _HostSearchFieldState extends State<HostSearchField> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();

  Timer? _debounce;
  List<ReceptionHost> _results = const [];
  bool _isSearching = false;
  bool _showResults = false;
  String? _searchError;
  String _lastQuery = '';
  int _requestId = 0;

  @override
  void initState() {
    super.initState();
    _controller.text = widget.selectedHost?.label ?? '';
    _focusNode.addListener(_handleFocusChange);
  }

  @override
  void didUpdateWidget(covariant HostSearchField oldWidget) {
    super.didUpdateWidget(oldWidget);
    final selectedHost = widget.selectedHost;
    if (selectedHost?.id != oldWidget.selectedHost?.id ||
        selectedHost?.hostType != oldWidget.selectedHost?.hostType) {
      if (selectedHost != null) {
        _controller.text = selectedHost.label;
        _results = const [];
        _searchError = null;
        _showResults = false;
      } else if (_controller.text == oldWidget.selectedHost?.label) {
        _controller.clear();
      }
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    _focusNode
      ..removeListener(_handleFocusChange)
      ..dispose();
    super.dispose();
  }

  void _handleFocusChange() {
    if (!_focusNode.hasFocus) {
      Future<void>.delayed(const Duration(milliseconds: 120), () {
        if (!mounted || _focusNode.hasFocus) {
          return;
        }
        setState(() => _showResults = false);
      });
      return;
    }
  }

  void _onChanged(String value) {
    if (widget.selectedHost != null &&
        value.trim() != widget.selectedHost!.label) {
      widget.onSelected(null);
    }

    _debounce?.cancel();
    final query = value.trim();
    _lastQuery = query;
    if (query.isEmpty) {
      setState(() {
        _results = const [];
        _isSearching = false;
        _searchError = null;
        _showResults = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _searchError = null;
      _results = const [];
      _showResults = true;
    });

    _debounce = Timer(const Duration(milliseconds: 300), () {
      _performSearch(query);
    });
  }

  Future<void> _performSearch(String query) async {
    final requestId = ++_requestId;
    try {
      final results = await widget.searchHosts(query);
      if (!mounted || requestId != _requestId) {
        return;
      }
      setState(() {
        _results = results;
        _isSearching = false;
        _searchError = null;
        _showResults = _focusNode.hasFocus;
      });
    } catch (error) {
      if (!mounted || requestId != _requestId) {
        return;
      }
      setState(() {
        _results = const [];
        _isSearching = false;
        _searchError = error.toString().replaceFirst('Exception: ', '');
        _showResults = _focusNode.hasFocus;
      });
    }
  }

  void _selectHost(ReceptionHost host) {
    _debounce?.cancel();
    widget.onSelected(host);
    setState(() {
      _controller.text = host.label;
      _results = const [];
      _searchError = null;
      _showResults = false;
    });
    _focusNode.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final fieldFillColor = widget.fillColor ?? Colors.grey[100];
    final showPanel =
        widget.enabled &&
        _showResults &&
        (_results.isNotEmpty ||
            _searchError != null ||
            (!_isSearching && _lastQuery.isNotEmpty));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextFormField(
          controller: _controller,
          focusNode: _focusNode,
          enabled: widget.enabled,
          decoration: InputDecoration(
            labelText: widget.labelText,
            hintText: widget.hintText,
            errorText: widget.errorText,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Theme.of(
                  context,
                ).colorScheme.primary.withValues(alpha: 0.4),
              ),
            ),
            filled: true,
            fillColor: fieldFillColor,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 20,
            ),
            prefixIcon: const Icon(Icons.badge_outlined),
            suffixIcon: _isSearching
                ? const Padding(
                    padding: EdgeInsets.all(14),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2.2),
                    ),
                  )
                : (widget.selectedHost != null && _controller.text.isNotEmpty)
                ? IconButton(
                    onPressed: widget.enabled
                        ? () {
                            _controller.clear();
                            widget.onSelected(null);
                            setState(() {
                              _lastQuery = '';
                              _results = const [];
                              _searchError = null;
                              _showResults = false;
                            });
                          }
                        : null,
                    icon: const Icon(Icons.close_rounded),
                  )
                : null,
          ),
          style: const TextStyle(fontSize: 20),
          onChanged: _onChanged,
        ),
        if (showPanel) ...[
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 14,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: _searchError != null
                ? Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      _searchError!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  )
                : _results.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'No hosts found. Try a different name or company.',
                      style: TextStyle(fontSize: 16),
                    ),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _results.length,
                    separatorBuilder: (_, _) => Divider(
                      height: 1,
                      color: Colors.grey.withValues(alpha: 0.18),
                    ),
                    itemBuilder: (context, index) {
                      final host = _results[index];
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 6,
                        ),
                        title: Text(
                          host.label,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        onTap: () => _selectHost(host),
                      );
                    },
                  ),
          ),
        ],
      ],
    );
  }
}
