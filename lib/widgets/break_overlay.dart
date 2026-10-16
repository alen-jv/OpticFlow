import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../timer/timer_provider.dart';
import '../utils/app_theme.dart';

/// Full-screen overlay shown when a break session begins.
/// User can dismiss it early with the "Skip Break" button.
class BreakOverlay extends StatefulWidget {
  const BreakOverlay({super.key});

  @override
  State<BreakOverlay> createState() => _BreakOverlayState();
}

class _BreakOverlayState extends State<BreakOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnim;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _pulseAnim = CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    );

    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: const Interval(0.0, 0.3, curve: Curves.easeOut),
      ),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final timer = context.watch<TimerProvider>();
    final progress = timer.progress;
    final remaining = timer.remainingSeconds;

    return AnimatedBuilder(
      animation: _pulseAnim,
      builder: (context, _) {
        return Material(
          type: MaterialType.transparency,
          child: Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 1.2 + _pulseAnim.value * 0.15,
                colors: const [
                  Color(0xFF0A3D25),
                  Color(0xFF052E1A),
                  Color(0xFF021A0E),
                ],
              ),
            ),
            child: FadeTransition(
              opacity: _fadeAnim,
              child: SafeArea(
                child: Column(
                  children: [
                    // ── Top bar ────────────────────────────────────────────────
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            '20·20·20',
                            style: TextStyle(
                              fontFamily: AppTheme.fontFamily,
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.breakAccent,
                              letterSpacing: 2,
                              decoration: TextDecoration.none,
                            ),
                          ),
                          // Skip/Dismiss button in the top-right
                          _DismissChip(onDismiss: timer.dismissBreak),
                        ],
                      ),
                    ),

                  const Spacer(flex: 2),

                  // ── Pulsing eye icon ───────────────────────────────────────
                  Transform.scale(
                    scale: 1.0 + _pulseAnim.value * 0.12,
                    child: Container(
                      width: 140,
                      height: 140,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.breakRing
                                .withOpacity(0.35 + _pulseAnim.value * 0.25),
                            blurRadius: 60 + _pulseAnim.value * 30,
                            spreadRadius: 10,
                          ),
                        ],
                        border: Border.all(
                          color: AppTheme.breakRing
                              .withOpacity(0.5 + _pulseAnim.value * 0.3),
                          width: 2,
                        ),
                        color: AppTheme.breakCard.withOpacity(0.6),
                      ),
                      child: Icon(
                        Icons.visibility_outlined,
                        size: 64,
                        color: AppTheme.breakAccent
                            .withOpacity(0.8 + _pulseAnim.value * 0.2),
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),

                  // ── Title ──────────────────────────────────────────────────
                  const Text(
                    '🌿  Eye Break',
                    style: TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.breakAccent,
                      letterSpacing: 0.5,
                      decoration: TextDecoration.none,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Look at something 20 feet away',
                    style: AppTheme.labelText.copyWith(
                      fontSize: 15,
                      decoration: TextDecoration.none,
                    ),
                  ),

                  const SizedBox(height: 48),

                  // ── Countdown ring ─────────────────────────────────────────
                  _CountdownRing(progress: progress, remaining: remaining),

                  const Spacer(flex: 2),

                  // ── Big dismiss button ─────────────────────────────────────
                  _BigDismissButton(onDismiss: timer.dismissBreak),

                  const SizedBox(height: 48),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}
}

// ── Dismiss chip (top-right) ─────────────────────────────────────────────────

class _DismissChip extends StatelessWidget {
  final VoidCallback onDismiss;
  const _DismissChip({required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onDismiss,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: AppTheme.breakCard.withOpacity(0.7),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppTheme.breakRing.withOpacity(0.35),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.close_rounded,
                size: 15, color: AppTheme.textSecondary),
            SizedBox(width: 5),
            Text(
              'Skip',
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppTheme.textSecondary,
                decoration: TextDecoration.none,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Countdown ring ───────────────────────────────────────────────────────────

class _CountdownRing extends StatelessWidget {
  final double progress;
  final int remaining;
  const _CountdownRing({required this.progress, required this.remaining});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 120,
      height: 120,
      child: Stack(
        alignment: Alignment.center,
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 1.0, end: progress),
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeOut,
            builder: (_, value, __) => CircularProgressIndicator(
              value: value,
              strokeWidth: 6,
              backgroundColor: AppTheme.breakRingTrack,
              valueColor: const AlwaysStoppedAnimation(AppTheme.breakRing),
              strokeCap: StrokeCap.round,
            ),
          ),
          Text(
            '$remaining',
            style: const TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontSize: 36,
              fontWeight: FontWeight.w200,
              color: AppTheme.textPrimary,
              decoration: TextDecoration.none,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Big dismiss button ───────────────────────────────────────────────────────

class _BigDismissButton extends StatelessWidget {
  final VoidCallback onDismiss;
  const _BigDismissButton({required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onDismiss,
      child: Container(
        width: 220,
        height: 54,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          gradient: const LinearGradient(
            colors: [Color(0xFF1A5C3A), Color(0xFF0A3D25)],
          ),
          border: Border.all(
            color: AppTheme.breakRing.withOpacity(0.4),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.breakRing.withOpacity(0.2),
              blurRadius: 20,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.skip_next_rounded,
                color: AppTheme.breakAccent, size: 20),
            SizedBox(width: 8),
            Text(
              'Dismiss Break',
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppTheme.breakAccent,
                decoration: TextDecoration.none,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
