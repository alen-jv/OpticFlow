import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../timer/timer_provider.dart';
import '../models/session_type.dart';
import '../utils/app_theme.dart';
import '../utils/format_time.dart';
import '../widgets/circular_timer_painter.dart';
import '../widgets/control_buttons.dart';
import '../widgets/daily_counter_badge.dart';
import '../widgets/session_label.dart';
import '../widgets/break_overlay.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _glowController;
  late final Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _glowAnimation = CurvedAnimation(
      parent: _glowController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  void _openSettings(BuildContext context) {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (_, animation, __) => const SettingsScreen(),
        transitionsBuilder: (_, animation, __, child) => SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1, 0),
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          )),
          child: child,
        ),
        transitionDuration: const Duration(milliseconds: 350),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TimerProvider>(
      builder: (context, timer, _) {
        final session = timer.session;
        final isBreak = session == SessionType.breakTime;
        final bg = AppTheme.bgColor(session);
        final accent = AppTheme.accentColor(session);

        return AnimatedContainer(
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeInOutCubic,
          color: bg,
          child: Stack(
            children: [
              // ── Main focus screen ─────────────────────────────────────────
              Scaffold(
                backgroundColor: Colors.transparent,
                body: SafeArea(
                  child: Column(
                    children: [
                      // ── App Bar ──────────────────────────────────────────
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '20·20·20',
                              style: TextStyle(
                                fontFamily: AppTheme.fontFamily,
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: accent,
                                letterSpacing: 2,
                              ),
                            ),
                            Row(
                              children: [
                                // Settings button
                                Tooltip(
                                  message: 'Settings',
                                  child: InkWell(
                                    onTap: () => _openSettings(context),
                                    borderRadius: BorderRadius.circular(50),
                                    child: Container(
                                      width: 36,
                                      height: 36,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Colors.white.withOpacity(0.06),
                                      ),
                                      child: Icon(
                                        Icons.tune_rounded,
                                        color: AppTheme.textSecondary,
                                        size: 18,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                // Info tip
                                Tooltip(
                                  message:
                                      'Every 20 min, look 20 ft away for 20 seconds',
                                  child: Icon(
                                    Icons.info_outline_rounded,
                                    color: AppTheme.textMuted,
                                    size: 20,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const Spacer(flex: 1),

                      // ── Background Tracking Status Pill ──────────────────
                      _BackgroundStatusPill(
                        enabled: timer.backgroundServiceEnabled,
                        isRunning: timer.isRunning,
                        isScreenOn: timer.isScreenOn,
                        onTap: () => _openSettings(context),
                      ),

                      const Spacer(flex: 1),

                      // ── Session Label ────────────────────────────────────
                      SessionLabel(session: session),

                      const Spacer(flex: 1),

                      // ── Circular Timer ───────────────────────────────────
                      SizedBox(
                        width: 280,
                        height: 280,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Outer ambient glow
                            AnimatedBuilder(
                              animation: _glowAnimation,
                              builder: (_, __) => Container(
                                width: 280,
                                height: 280,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppTheme.ringColor(session)
                                          .withOpacity(
                                              0.10 * _glowAnimation.value),
                                      blurRadius: 60,
                                      spreadRadius: 20,
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            // Custom painter ring
                            CustomPaint(
                              size: const Size(280, 280),
                              painter: CircularTimerPainter(
                                progress: timer.progress,
                                session: session,
                                glowAnimation: _glowAnimation,
                              ),
                            ),

                            // Time text
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                AnimatedDefaultTextStyle(
                                  duration: const Duration(milliseconds: 400),
                                  style: AppTheme.timerText(session),
                                  child: Text(
                                    formatTime(timer.remainingSeconds),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  session == SessionType.focus
                                      ? 'REMAINING'
                                      : 'SECONDS',
                                  style: AppTheme.labelText
                                      .copyWith(fontSize: 11),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const Spacer(flex: 1),

                      // ── Controls ─────────────────────────────────────────
                      ControlButtons(
                        session: session,
                        isRunning: timer.isRunning,
                        onStart: timer.start,
                        onPause: timer.pause,
                        onReset: timer.reset,
                      ),

                      const Spacer(flex: 2),

                      // ── Daily Counter ────────────────────────────────────
                      DailyCounterBadge(
                        count: timer.breaksCompletedToday,
                        session: session,
                      ),

                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),

              // ── Break overlay (slides in when break starts) ───────────────
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 500),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                transitionBuilder: (child, anim) => FadeTransition(
                  opacity: anim,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 0.05),
                      end: Offset.zero,
                    ).animate(anim),
                    child: child,
                  ),
                ),
                child: isBreak
                    ? const BreakOverlay(key: ValueKey('break'))
                    : const SizedBox.shrink(key: ValueKey('focus')),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ── Background status pill ──────────────────────────────────────────────────

class _BackgroundStatusPill extends StatelessWidget {
  final bool enabled;
  final bool isRunning;
  final bool isScreenOn;
  final VoidCallback onTap;

  const _BackgroundStatusPill({
    required this.enabled,
    required this.isRunning,
    required this.isScreenOn,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color border;
    Color dotColor;
    String text;

    if (!enabled) {
      bg = Colors.white.withOpacity(0.04);
      border = Colors.white.withOpacity(0.08);
      dotColor = AppTheme.textMuted;
      text = 'Auto-Tracking: Off (Tap to configure)';
    } else if (isScreenOn && isRunning) {
      bg = const Color(0xFF10B981).withOpacity(0.12);
      border = const Color(0xFF10B981).withOpacity(0.3);
      dotColor = const Color(0xFF10B981);
      text = 'Screen On • Tracking Active';
    } else {
      bg = Colors.amber.withOpacity(0.12);
      border = Colors.amber.withOpacity(0.3);
      dotColor = Colors.amber;
      text = 'Screen Off • Timer Paused';
    }

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: border, width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: dotColor,
                boxShadow: enabled && isRunning
                    ? [
                        BoxShadow(
                          color: dotColor.withOpacity(0.6),
                          blurRadius: 6,
                          spreadRadius: 1,
                        )
                      ]
                    : null,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              text,
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: dotColor,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
