import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'theme/app_theme.dart';
import 'features/forecast/forecast_screen.dart';
import 'widgets/starfield_background.dart';

void main() {
  runApp(const ProviderScope(child: ClearSkiesApp()));
}

class ClearSkiesApp extends StatelessWidget {
  const ClearSkiesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ClearSkies',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      home: const _AppShell(),
    );
  }
}

class _AppShell extends StatelessWidget {
  const _AppShell();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: const [
          StarfieldBackground(),
          ForecastScreen(),
        ],
      ),
    );
  }
}
