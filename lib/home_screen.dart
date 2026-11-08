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
      body: Stack(children: [
        SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: EdgeInsets.symmetric(vertical: MediaQuery.sizeOf(context).width < 600 ? 20 : 32),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 700),
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: MediaQuery.sizeOf(context).width < 600 ? 16 : 32.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          ActionTile(
                            title: 'Appointment',
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
        // Staff only: press and hold the top-left corner, then enter the PIN, to reset this device. Invisible on purpose.
        Positioned(
          left: 0,
          top: 0,
          child: SafeArea(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onLongPress: () => _openSettings(context),
              child: const SizedBox(width: 72, height: 72),
            ),
          ),
        ),
      ]),
    );
  }
}
