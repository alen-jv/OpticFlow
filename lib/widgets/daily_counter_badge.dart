import 'package:flutter/material.dart';
import '../models/session_type.dart';
import '../utils/app_theme.dart';

/// Pill badge showing today''s completed eye breaks.
class DailyCounterBadge extends StatelessWidget {
  final int count;
  final SessionType session;

  const DailyCounterBadge({
    super.key,
    required this.count,
    required this.session,
  });

  @override
  Widget build(BuildContext context) {
    final accent = AppTheme.accentColor(session);
    final ring   = AppTheme.ringColor(session);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.cardColor(session),
        borderRadius: BorderRadius.circular(40),
        border: Border.all(color: ring.withOpacity(0.25), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.visibility_outlined, color: accent, size: 16),
          const SizedBox(width: 8),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: '$count',
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: accent,
                  ),
                ),
                const TextSpan(
                  text: '  breaks today',
                  style: AppTheme.counterText,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
