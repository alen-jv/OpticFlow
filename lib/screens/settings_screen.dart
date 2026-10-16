import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../timer/timer_provider.dart';
import '../utils/app_theme.dart';

/// Settings screen for configuring custom focus and break durations.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late int _focusMinutes;
  late int _breakSeconds;
  bool _saved = false;

  @override
  void initState() {
    super.initState();
    final timer = context.read<TimerProvider>();
    _focusMinutes = timer.focusMinutes;
    _breakSeconds = timer.breakSeconds;
  }

  Future<void> _save() async {
    final timer = context.read<TimerProvider>();
    await timer.saveSettings(
      focusMinutes: _focusMinutes,
      breakSeconds: _breakSeconds,
    );
    setState(() => _saved = true);
    await Future.delayed(const Duration(seconds: 1));
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.focusBg,
      body: SafeArea(
        child: Column(
          children: [
            // ── App Bar ──────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 16, 20, 0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded,
                        color: AppTheme.textSecondary, size: 20),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Settings',
                    style: TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.focusAccent,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  const SizedBox(height: 8),

                  // ── Background Tracking ─────────────────────────────────
                  _SectionHeader(
                    icon: Icons.sensors_rounded,
                    label: 'Background Tracking',
                    color: AppTheme.focusAccent,
                  ),
                  const SizedBox(height: 16),
                  Consumer<TimerProvider>(
                    builder: (context, timer, _) => Column(
                      children: [
                        _BackgroundTrackingCard(
                          enabled: timer.backgroundServiceEnabled,
                          onChanged: (val) {
                            timer.toggleBackgroundService(val);
                          },
                        ),
                        const SizedBox(height: 14),
                        _OverlayPermissionCard(
                          granted: timer.overlayPermissionGranted,
                          onRequest: () async {
                            await timer.requestOverlayPermission();
                            await Future.delayed(const Duration(seconds: 1));
                            await timer.checkOverlayPermission();
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // ── Focus duration ─────────────────────────────────────────
                  _SectionHeader(
                    icon: Icons.timer_outlined,
                    label: 'Focus Duration',
                    color: AppTheme.focusAccent,
                  ),
                  const SizedBox(height: 16),
                  _SliderCard(
                    value: _focusMinutes.toDouble(),
                    min: 1,
                    max: 60,
                    divisions: 59,
                    activeColor: AppTheme.focusRing,
                    label: '$_focusMinutes min',
                    sublabel: _focusMinutes == 20
                        ? 'Recommended (20-20-20 rule)'
                        : _focusMinutes < 20
                            ? 'Shorter than recommended'
                            : 'Longer than recommended',
                    onChanged: (v) => setState(() => _focusMinutes = v.round()),
                  ),

                  const SizedBox(height: 32),

                  // ── Break duration ─────────────────────────────────────────
                  _SectionHeader(
                    icon: Icons.visibility_outlined,
                    label: 'Break Duration',
                    color: AppTheme.breakAccent,
                  ),
                  const SizedBox(height: 16),
                  _SliderCard(
                    value: _breakSeconds.toDouble(),
                    min: 10,
                    max: 120,
                    divisions: 22,
                    activeColor: AppTheme.breakRing,
                    label: '$_breakSeconds sec',
                    sublabel: _breakSeconds == 20
                        ? 'Recommended (20-20-20 rule)'
                        : _breakSeconds < 20
                            ? 'Shorter than recommended'
                            : 'Longer than recommended',
                    onChanged: (v) => setState(() {
                      // Snap to nearest 5
                      _breakSeconds = (v / 5).round() * 5;
                    }),
                  ),

                  const SizedBox(height: 48),

                  // ── Preview card ───────────────────────────────────────────
                  _PreviewCard(
                      focusMinutes: _focusMinutes,
                      breakSeconds: _breakSeconds),

                  const SizedBox(height: 40),

                  // ── Save button ────────────────────────────────────────────
                  _SaveButton(saved: _saved, onSave: _save),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Section header ───────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _SectionHeader(
      {required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 10),
        Text(
          label,
          style: TextStyle(
            fontFamily: AppTheme.fontFamily,
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }
}

// ── Slider card ──────────────────────────────────────────────────────────────

class _SliderCard extends StatelessWidget {
  final double value;
  final double min;
  final double max;
  final int divisions;
  final Color activeColor;
  final String label;
  final String sublabel;
  final ValueChanged<double> onChanged;

  const _SliderCard({
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.activeColor,
    required this.label,
    required this.sublabel,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
      decoration: BoxDecoration(
        color: AppTheme.focusCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: activeColor.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontSize: 32,
                  fontWeight: FontWeight.w200,
                  color: AppTheme.textPrimary,
                ),
              ),
              Text(
                sublabel,
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontSize: 11,
                  color: activeColor.withOpacity(0.7),
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.right,
              ),
            ],
          ),
          const SizedBox(height: 8),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: activeColor,
              inactiveTrackColor: activeColor.withOpacity(0.15),
              thumbColor: activeColor,
              overlayColor: activeColor.withOpacity(0.15),
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
              trackHeight: 4,
            ),
            child: Slider(
              value: value,
              min: min,
              max: max,
              divisions: divisions,
              onChanged: onChanged,
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${min.toInt()}',
                  style: AppTheme.labelText.copyWith(fontSize: 11)),
              Text('${max.toInt()}',
                  style: AppTheme.labelText.copyWith(fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Preview card ─────────────────────────────────────────────────────────────

class _PreviewCard extends StatelessWidget {
  final int focusMinutes;
  final int breakSeconds;
  const _PreviewCard(
      {required this.focusMinutes, required this.breakSeconds});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1F0F),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.breakRing.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your 20-20-20 Cycle',
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppTheme.textSecondary,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _CycleChip(
                icon: Icons.timer_outlined,
                label: '$focusMinutes min',
                sublabel: 'Focus',
                color: AppTheme.focusAccent,
              ),
              const SizedBox(width: 12),
              const Icon(Icons.arrow_forward_rounded,
                  color: AppTheme.textMuted, size: 16),
              const SizedBox(width: 12),
              _CycleChip(
                icon: Icons.visibility_outlined,
                label: '$breakSeconds sec',
                sublabel: 'Break',
                color: AppTheme.breakAccent,
              ),
              const SizedBox(width: 12),
              const Icon(Icons.loop_rounded,
                  color: AppTheme.textMuted, size: 16),
            ],
          ),
        ],
      ),
    );
  }
}

class _CycleChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String sublabel;
  final Color color;
  const _CycleChip(
      {required this.icon,
      required this.label,
      required this.sublabel,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.25), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 13),
              const SizedBox(width: 5),
              Text(sublabel,
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontSize: 11,
                    color: color.withOpacity(0.7),
                    fontWeight: FontWeight.w500,
                  )),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Save button ──────────────────────────────────────────────────────────────

class _SaveButton extends StatelessWidget {
  final bool saved;
  final VoidCallback onSave;
  const _SaveButton({required this.saved, required this.onSave});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: saved ? null : onSave,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        height: 56,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          gradient: LinearGradient(
            colors: saved
                ? [const Color(0xFF1A5C3A), const Color(0xFF0A3D25)]
                : [const Color(0xFF3730A3), const Color(0xFF1E1B6B)],
          ),
          boxShadow: [
            BoxShadow(
              color: (saved ? AppTheme.breakRing : AppTheme.focusRing)
                  .withOpacity(0.3),
              blurRadius: 20,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              saved ? Icons.check_circle_outline_rounded : Icons.save_outlined,
              color: saved ? AppTheme.breakAccent : AppTheme.focusAccent,
              size: 20,
            ),
            const SizedBox(width: 10),
            Text(
              saved ? 'Saved!' : 'Save & Apply',
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: saved ? AppTheme.breakAccent : AppTheme.focusAccent,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Background tracking card ────────────────────────────────────────────────

class _BackgroundTrackingCard extends StatelessWidget {
  final bool enabled;
  final ValueChanged<bool> onChanged;

  const _BackgroundTrackingCard({
    required this.enabled,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.focusCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: enabled
              ? AppTheme.focusAccent.withOpacity(0.3)
              : Colors.white.withOpacity(0.06),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: enabled
                            ? AppTheme.focusAccent.withOpacity(0.15)
                            : Colors.white.withOpacity(0.05),
                      ),
                      child: Icon(
                        enabled
                            ? Icons.screen_lock_portrait_rounded
                            : Icons.phone_android_rounded,
                        color: enabled
                            ? AppTheme.focusAccent
                            : AppTheme.textSecondary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Screen-On Auto-Timer',
                            style: TextStyle(
                              fontFamily: AppTheme.fontFamily,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            enabled ? 'Active in background' : 'Disabled',
                            style: TextStyle(
                              fontFamily: AppTheme.fontFamily,
                              fontSize: 12,
                              color: enabled
                                  ? AppTheme.focusAccent
                                  : AppTheme.textMuted,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Switch.adaptive(
                value: enabled,
                activeColor: AppTheme.focusAccent,
                activeTrackColor: AppTheme.focusAccent.withOpacity(0.3),
                inactiveThumbColor: AppTheme.textSecondary,
                inactiveTrackColor: Colors.white.withOpacity(0.1),
                onChanged: onChanged,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Runs silently in the background. The timer starts automatically whenever the screen turns on, pauses when the screen turns off, and auto-starts on boot.',
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontSize: 12,
              height: 1.4,
              color: AppTheme.textSecondary.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Overlay permission card ─────────────────────────────────────────────────

class _OverlayPermissionCard extends StatelessWidget {
  final bool granted;
  final VoidCallback onRequest;

  const _OverlayPermissionCard({
    required this.granted,
    required this.onRequest,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.focusCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: granted
              ? const Color(0xFF10B981).withOpacity(0.3)
              : Colors.amber.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: granted
                      ? const Color(0xFF10B981).withOpacity(0.15)
                      : Colors.amber.withOpacity(0.15),
                ),
                child: Icon(
                  granted
                      ? Icons.layers_rounded
                      : Icons.layers_clear_rounded,
                  color: granted
                      ? const Color(0xFF10B981)
                      : Colors.amber,
                  size: 20,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Display Over Other Apps',
                      style: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      granted
                          ? 'Override other apps active'
                          : 'Permission needed to pop up',
                      style: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontSize: 12,
                        color: granted
                            ? const Color(0xFF10B981)
                            : Colors.amber,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              if (granted)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check, size: 14, color: Color(0xFF10B981)),
                      SizedBox(width: 4),
                      Text(
                        'Allowed',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF10B981),
                        ),
                      ),
                    ],
                  ),
                )
              else
                ElevatedButton(
                  onPressed: onRequest,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Grant',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            granted
                ? 'When your 20-minute focus session ends, the break screen will automatically appear on top of other apps (browsers, YouTube, games) and return back when finished.'
                : 'Allow this permission so the 20-second eye break screen can automatically appear on top of whichever app you are using.',
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontSize: 12,
              height: 1.4,
              color: AppTheme.textSecondary.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }
}
