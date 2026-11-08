import 'package:flutter/material.dart';

class ActionTile extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onPressed;

  const ActionTile({
    super.key,
    required this.title,
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    // Phones get a tighter tile so titles never wrap mid-word; iPads keep the large touch targets.
    final compact = MediaQuery.sizeOf(context).width < 600;
    return Container(
      margin: EdgeInsets.only(bottom: compact ? 14 : 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: onPressed,
          child: Padding(
            padding: EdgeInsets.all(compact ? 26 : 48.0),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(compact ? 16 : 28),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.primaryContainer.withValues(alpha: 0.5),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    size: compact ? 36 : 56,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                SizedBox(width: compact ? 14 : 32),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: compact ? 28 : 44,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: Colors.grey[400], size: compact ? 32 : 52),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
