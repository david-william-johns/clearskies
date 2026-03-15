import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../theme/app_theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  static const _metOfficeKeyPref = 'met_office_api_key';
  static const _owmKeyPref = 'owm_api_key';
  final _metOfficeController = TextEditingController();
  final _owmController = TextEditingController();
  bool _obscure = true;
  bool _saved = false;
  bool _owmObscure = true;
  bool _owmSaved = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final metKey = prefs.getString(_metOfficeKeyPref) ?? '';
    final owmKey = prefs.getString(_owmKeyPref) ?? '';
    setState(() {
      _metOfficeController.text = metKey;
      _owmController.text = owmKey;
    });
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_metOfficeKeyPref, _metOfficeController.text.trim());
    setState(() => _saved = true);
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) setState(() => _saved = false);
  }

  Future<void> _saveOwm() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_owmKeyPref, _owmController.text.trim());
    setState(() => _owmSaved = true);
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) setState(() => _owmSaved = false);
  }

  @override
  void dispose() {
    _metOfficeController.dispose();
    _owmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: const Text('Settings'),
        foregroundColor: AppColors.textPrimary,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const _SectionTitle('DATA SOURCES'),
          const SizedBox(height: 10),
          _Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SourceRow(
                  icon: Icons.cloud_outlined,
                  name: 'Open-Meteo',
                  description:
                      'Primary 16-day hourly forecast (free, no key required)',
                  status: 'Active',
                  statusOk: true,
                ),
                const Divider(height: 20),
                _SourceRow(
                  icon: Icons.visibility_outlined,
                  name: '7timer.info',
                  description: 'Seeing & transparency estimates (free)',
                  status: 'Active',
                  statusOk: true,
                ),
                const Divider(height: 20),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SourceRow(
                      icon: Icons.wb_sunny_outlined,
                      name: 'Met Office DataPoint',
                      description:
                          'UK-optimised hourly forecast — add your free API key to enable',
                      status: _metOfficeController.text.isEmpty
                          ? 'No key'
                          : 'Key saved',
                      statusOk: _metOfficeController.text.isNotEmpty,
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _metOfficeController,
                            obscureText: _obscure,
                            style: const TextStyle(
                                color: AppColors.textPrimary, fontSize: 13),
                            decoration: InputDecoration(
                              hintText: 'Paste API key…',
                              hintStyle: const TextStyle(
                                  color: AppColors.textMuted, fontSize: 12),
                              filled: true,
                              fillColor: AppColors.background,
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 10),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(
                                    color: AppColors.surfaceBorder),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(
                                    color: AppColors.surfaceBorder),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(
                                    color: AppColors.primary),
                              ),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscure
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                  color: AppColors.textMuted,
                                  size: 18,
                                ),
                                onPressed: () =>
                                    setState(() => _obscure = !_obscure),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: _save,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: AppColors.background,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 10),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                          ),
                          child: Text(_saved ? '✓ Saved' : 'Save'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Register free at metoffice.gov.uk/services/data/datapoint',
                      style: TextStyle(
                          color: AppColors.textMuted, fontSize: 10),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const _SectionTitle('MAP LAYERS'),
          const SizedBox(height: 10),
          _Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SourceRow(
                  icon: Icons.cloud_outlined,
                  name: 'OpenWeatherMap Cloud Tiles',
                  description:
                      'Overlays real cloud pattern imagery on the satellite map — add your free API key to enable',
                  status: _owmController.text.isEmpty ? 'No key' : 'Key saved',
                  statusOk: _owmController.text.isNotEmpty,
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _owmController,
                        obscureText: _owmObscure,
                        style: const TextStyle(
                            color: AppColors.textPrimary, fontSize: 13),
                        decoration: InputDecoration(
                          hintText: 'Paste API key…',
                          hintStyle: const TextStyle(
                              color: AppColors.textMuted, fontSize: 12),
                          filled: true,
                          fillColor: AppColors.background,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                                color: AppColors.surfaceBorder),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                                color: AppColors.surfaceBorder),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide:
                                const BorderSide(color: AppColors.primary),
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _owmObscure
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              color: AppColors.textMuted,
                              size: 18,
                            ),
                            onPressed: () =>
                                setState(() => _owmObscure = !_owmObscure),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _saveOwm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.background,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                      child: Text(_owmSaved ? '✓ Saved' : 'Save'),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  'Register free at openweathermap.org/api',
                  style:
                      TextStyle(color: AppColors.textMuted, fontSize: 10),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const _SectionTitle('ABOUT'),
          const SizedBox(height: 10),
          _Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text('ClearSkies v1.0',
                    style: TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600)),
                SizedBox(height: 4),
                Text(
                  'Clear sky forecast for amateur astronomers and telescope users.\n'
                  'Shows 14 nights of dark-hour cloud cover, seeing, transparency, '
                  'moon phase and ClearSky scores to help plan the best observing sessions.',
                  style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      height: 1.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
          color: AppColors.textMuted, fontSize: 10, letterSpacing: 1.0),
    );
  }
}

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: child,
    );
  }
}

class _SourceRow extends StatelessWidget {
  final IconData icon;
  final String name;
  final String description;
  final String status;
  final bool statusOk;

  const _SourceRow({
    required this.icon,
    required this.name,
    required this.description,
    required this.status,
    required this.statusOk,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppColors.primary, size: 18),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name,
                  style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 13)),
              Text(description,
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 11)),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: statusOk
                ? AppColors.scoreExcellent.withAlpha(25)
                : AppColors.scorePoor.withAlpha(25),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            status,
            style: TextStyle(
              color: statusOk ? AppColors.scoreExcellent : AppColors.scorePoor,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
