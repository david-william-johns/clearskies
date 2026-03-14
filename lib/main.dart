import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'theme/app_theme.dart';
import 'features/forecast/forecast_screen.dart';
import 'features/forecast/settings_screen.dart';
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

class _AppShell extends StatefulWidget {
  const _AppShell();

  @override
  State<_AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<_AppShell> {
  int _tab = 0;

  static const _tabs = [
    ForecastScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          const StarfieldBackground(),
          IndexedStack(index: _tab, children: _tabs),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        backgroundColor: AppColors.surface,
        indicatorColor: AppColors.primary.withAlpha(40),
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.nightlight_outlined,
                color: AppColors.textSecondary),
            selectedIcon: Icon(Icons.nightlight, color: AppColors.primary),
            label: 'Forecast',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined,
                color: AppColors.textSecondary),
            selectedIcon: Icon(Icons.settings, color: AppColors.primary),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
