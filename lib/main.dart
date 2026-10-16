import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'timer/timer_provider.dart';
import 'utils/app_theme.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock orientation to portrait for mobile
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  // Use edge-to-edge system UI
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );

  runApp(const TwentyApp());
}

class TwentyApp extends StatelessWidget {
  const TwentyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => TimerProvider()..init(),
      child: MaterialApp(
        title: '20·20·20 Eye Health',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.themeData,
        home: const _InitGate(),
      ),
    );
  }
}

/// Shows a splash screen while the TimerProvider initializes (loads prefs).
class _InitGate extends StatelessWidget {
  const _InitGate();

  @override
  Widget build(BuildContext context) {
    final timer = context.watch<TimerProvider>();
    if (!timer.initialized) {
      return const Scaffold(
        backgroundColor: AppTheme.focusBg,
        body: Center(
          child: CircularProgressIndicator(
            color: AppTheme.focusAccent,
            strokeWidth: 2,
          ),
        ),
      );
    }
    return const HomeScreen();
  }
}
