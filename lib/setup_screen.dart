import 'package:flutter/material.dart';
import 'app_config.dart';
import 'home_screen.dart';
import 'reception_api_service.dart';

/// First launch (or after a reset): connect this iPad to a site with a device key and set the staff PIN.
class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key});

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  final _site = TextEditingController(text: AppConfig.siteUrl.isEmpty ? '' : Uri.tryParse(AppConfig.siteUrl)?.host ?? '');
  final _key = TextEditingController();
  final _pin = TextEditingController();
  bool _busy = false;
  String _error = '';

  @override
  void dispose() {
    _site.dispose();
    _key.dispose();
    _pin.dispose();
    super.dispose();
  }

  Future<void> _connect() async {
    setState(() {
      _busy = true;
      _error = '';
    });
    try {
      final url = AppConfig.normalizeSiteUrl(_site.text);
      final key = _key.text.trim();
      if (key.isEmpty) throw const FormatException('Enter the device key.');
      if (_pin.text.trim().length < 4) throw const FormatException('Choose a PIN of at least 4 digits.');
      final info = await ReceptionApiService.ping(url, key);
      await AppConfig.save(siteUrl: url, deviceKey: key, pin: _pin.text.trim(), siteName: info.siteName);
      if (!mounted) return;
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const HomeScreen()));
    } on FormatException catch (e) {
      setState(() => _error = e.message);
    } catch (e) {
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.all(32),
              children: [
                const Icon(Icons.desk_rounded, size: 56),
                const SizedBox(height: 12),
                const Text('AJ Front Desk', textAlign: TextAlign.center, style: TextStyle(fontSize: 30, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                const Text('Staff setup', textAlign: TextAlign.center),
                const SizedBox(height: 28),
                TextField(controller: _site, keyboardType: TextInputType.url, autocorrect: false, decoration: const InputDecoration(labelText: 'Site URL', hintText: 'ncllcagents.com', border: OutlineInputBorder())),
                const SizedBox(height: 14),
                TextField(controller: _key, autocorrect: false, obscureText: true, decoration: const InputDecoration(labelText: 'Device key', border: OutlineInputBorder())),
                const SizedBox(height: 14),
                TextField(controller: _pin, keyboardType: TextInputType.number, obscureText: true, decoration: const InputDecoration(labelText: 'Staff PIN (opens settings later)', border: OutlineInputBorder())),
                if (_error.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 12), child: Text(_error, style: const TextStyle(color: Colors.red))),
                const SizedBox(height: 20),
                FilledButton(
                  style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
                  onPressed: _busy ? null : _connect,
                  child: _busy ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Connect'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
