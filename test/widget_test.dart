import 'package:flutter_test/flutter_test.dart';
import 'package:opticflow/timer/timer_provider.dart';
import 'package:opticflow/models/session_type.dart';

void main() {
  group('TimerProvider', () {
    test('starts in focus session with correct duration', () {
      final provider = TimerProvider();
      expect(provider.session, SessionType.focus);
      expect(provider.remainingSeconds, kDefaultFocusMinutes * 60);
      expect(provider.isRunning, false);
    });

    test('isRunning becomes true on start', () {
      final provider = TimerProvider();
      provider.start();
      expect(provider.isRunning, true);
      provider.dispose();
    });

    test('pause stops timer', () {
      final provider = TimerProvider();
      provider.start();
      provider.pause();
      expect(provider.isRunning, false);
      provider.dispose();
    });

    test('reset returns to focus session at full time', () {
      final provider = TimerProvider();
      provider.start();
      provider.reset();
      expect(provider.session, SessionType.focus);
      expect(provider.remainingSeconds, kDefaultFocusMinutes * 60);
      expect(provider.isRunning, false);
      provider.dispose();
    });

    test('progress is 1.0 at start (full time remaining)', () {
      final provider = TimerProvider();
      expect(provider.progress, 1.0);
      provider.dispose();
    });
  });
}
