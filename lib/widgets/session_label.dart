import 'package:flutter/material.dart';
import '../models/session_type.dart';
import '../utils/app_theme.dart';

/// Animated label that switches between "Focus Time" and "Look Away".
class SessionLabel extends StatelessWidget {
  final SessionType session;

  const SessionLabel({super.key, required this.session});

  @override
  Widget build(BuildContext context) {
    final isFocus = session == SessionType.focus;
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      switchInCurve: Curves.easeOutBack,
      switchOutCurve: Curves.easeIn,
      transitionBuilder: (child, anim) => FadeTransition(
        opacity: anim,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.2),
            end: Offset.zero,
          ).animate(anim),
          child: child,
        ),
      ),
      child: Column(
        key: ValueKey(session),
        children: [
          Text(
            isFocus ? '👁  Focus Time' : '🌿  Look Away',
            style: AppTheme.headline(session),
          ),
          const SizedBox(height: 6),
          Text(
            isFocus
                ? 'Work for 20 minutes'
                : 'Focus on something 20 feet away',
            style: AppTheme.labelText,
          ),
        ],
      ),
    );
  }
}
