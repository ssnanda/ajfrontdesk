import 'package:flutter/material.dart';
import 'app_config.dart';
import 'setup_screen.dart';
import 'returning_visitor_screen.dart';
import 'checkin_form_screen.dart';
import 'action_tile.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  Future<void> _openSettings(BuildContext context) async {
    final ctrl = TextEditingController();
    final pin = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Staff PIN'),
        content: TextField(controller: ctrl, autofocus: true, obscureText: true, keyboardType: TextInputType.number),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, ctrl.text.trim()), child: const Text('OK')),
        ],
      ),
    );
    if (pin == null || !context.mounted) return;
    if (pin != AppConfig.pin) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Wrong PIN.')));
      return;
    }
    final reset = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset this iPad?'),
        content: const Text('It will forget the site and device key and return to setup.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Reset')),
        ],
      ),
    );
    if (reset != true || !context.mounted) return;
    await AppConfig.clear();
    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const SetupScreen()), (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 700),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          GestureDetector(
                            // Staff only: long-press, then the PIN, to change or reset this iPad's setup.
                            onLongPress: () => _openSettings(context),
                            child: Text(
                              AppConfig.siteName.isEmpty
                                  ? 'Welcome — Check In'
                                  : 'Welcome to ${AppConfig.siteName}',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 42,
                                fontWeight: FontWeight.w400,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Please select how you would like to proceed today.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 20,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 64),
                          ActionTile(
                            title: 'Appointment',
                            subtitle: 'I already have a scheduled visit',
                            icon: Icons.calendar_today_rounded,
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const CheckInFormScreen(
                                  title: 'Appointment',
                                  visitType: 'appointment',
                                ),
                              ),
                            ),
                          ),
                          ActionTile(
                            title: 'Walk-In',
                            subtitle: 'I’m here without an appointment',
                            icon: Icons.directions_walk_rounded,
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const CheckInFormScreen(
                                  title: 'Walk-In',
                                  visitType: 'walk_in',
                                ),
                              ),
                            ),
                          ),
                          ActionTile(
                            title: 'Returning Visitor',
                            subtitle: 'Use phone number for faster check-in',
                            icon: Icons.person_search_rounded,
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const ReturningVisitorScreen(),
                              ),
                            ),
                          ),
                        ],
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
