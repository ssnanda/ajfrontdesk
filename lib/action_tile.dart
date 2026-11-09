import 'package:flutter/material.dart';

/// A big colored button for the home screen. [scale] shrinks a secondary tile (e.g. 0.85).
class ActionTile extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onPressed;
  final List<Color> gradient;
  final double scale;

  const ActionTile({
    super.key,
    required this.title,
    required this.icon,
    required this.onPressed,
    required this.gradient,
    this.scale = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    // Phones get a tighter tile so titles never wrap mid-word; iPads keep the large touch targets.
    final compact = MediaQuery.sizeOf(context).width < 600;
    final s = scale;
    return Container(
      margin: EdgeInsets.only(bottom: compact ? 16 : 28),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: gradient, begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: gradient.last.withValues(alpha: 0.35),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(32),
          onTap: onPressed,
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: (compact ? 28 : 52) * s,
              vertical: (compact ? 34 : 64) * s,
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all((compact ? 18 : 30) * s),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.25),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: (compact ? 40 : 64) * s, color: Colors.white),
                ),
                SizedBox(width: (compact ? 20 : 36) * s),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: (compact ? 34 : 56) * s,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: Colors.white70, size: (compact ? 36 : 58) * s),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
