import 'package:flutter/material.dart';
import '../models/session_type.dart';
import '../utils/app_theme.dart';

/// Start / Pause / Reset control buttons.
class ControlButtons extends StatelessWidget {
  final SessionType session;
  final bool isRunning;
  final VoidCallback onStart;
  final VoidCallback onPause;
  final VoidCallback onReset;

  const ControlButtons({
    super.key,
    required this.session,
    required this.isRunning,
    required this.onStart,
    required this.onPause,
    required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    final accent = AppTheme.accentColor(session);
    final ring   = AppTheme.ringColor(session);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // ── Reset button ──────────────────────────────────────────────────
        _IconBtn(
          icon: Icons.replay_rounded,
          color: AppTheme.textSecondary,
          onTap: onReset,
          tooltip: 'Reset',
        ),
        const SizedBox(width: 28),

        // ── Start / Pause button (primary) ────────────────────────────────
        GestureDetector(
          onTap: isRunning ? onPause : onStart,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutCubic,
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [accent.withOpacity(0.25), Colors.transparent],
                radius: 0.9,
              ),
              border: Border.all(color: ring, width: 2),
              boxShadow: [
                BoxShadow(
                  color: ring.withOpacity(0.35),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Icon(
              isRunning ? Icons.pause_rounded : Icons.play_arrow_rounded,
              color: accent,
              size: 36,
            ),
          ),
        ),

        const SizedBox(width: 28),

        // ── Spacer for symmetry ───────────────────────────────────────────
        const SizedBox(width: 44),
      ],
    );
  }
}

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final String tooltip;

  const _IconBtn({
    required this.icon,
    required this.color,
    required this.onTap,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(50),
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withOpacity(0.06),
          ),
          child: Icon(icon, color: color, size: 22),
        ),
      ),
    );
  }
}
