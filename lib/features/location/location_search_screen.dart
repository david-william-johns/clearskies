import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_theme.dart';
import 'geocoding_service.dart';
import '../forecast/forecast_providers.dart';

class LocationSearchScreen extends ConsumerStatefulWidget {
  final bool isFirstRun;

  const LocationSearchScreen({super.key, this.isFirstRun = false});

  @override
  ConsumerState<LocationSearchScreen> createState() =>
      _LocationSearchScreenState();
}

class _LocationSearchScreenState extends ConsumerState<LocationSearchScreen> {
  final _controller = TextEditingController();
  final _geocoding = GeocodingService();

  String? _error;
  bool _loading = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _search(String query) async {
    if (query.trim().isEmpty) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final loc = await _geocoding.resolve(query.trim());
      await ref.read(locationProvider.notifier).setLocation(loc);
      if (mounted) {
        if (widget.isFirstRun) {
          // Replace current route
          Navigator.of(context).pop();
        } else {
          Navigator.of(context).pop();
        }
      }
    } on GeocodingException catch (e) {
      setState(() => _error = e.message);
    } catch (e) {
      setState(() => _error = 'Unexpected error: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: widget.isFirstRun
          ? null
          : AppBar(
              backgroundColor: AppColors.background,
              title: const Text('Change Location'),
              foregroundColor: AppColors.textPrimary,
            ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.isFirstRun) ...[
                const SizedBox(height: 32),
                const Row(
                  children: [
                    Icon(Icons.stars, color: AppColors.primary, size: 32),
                    SizedBox(width: 10),
                    Text(
                      'ClearSkies',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  '14-day clear sky forecast\nfor telescope & stargazing',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 40),
              ],
              const Text(
                'Enter your location',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'UK postcode (e.g. SW1A 2AA) or city name (e.g. Manchester)',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _controller,
                autofocus: true,
                onSubmitted: _search,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  hintText: 'Postcode or city…',
                  hintStyle:
                      const TextStyle(color: AppColors.textMuted, fontSize: 14),
                  filled: true,
                  fillColor: AppColors.surface,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide:
                        const BorderSide(color: AppColors.surfaceBorder),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide:
                        const BorderSide(color: AppColors.surfaceBorder),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppColors.primary),
                  ),
                  suffixIcon: _loading
                      ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                  AppColors.primary),
                            ),
                          ),
                        )
                      : IconButton(
                          icon: const Icon(Icons.search,
                              color: AppColors.primary),
                          onPressed: () => _search(_controller.text),
                        ),
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.scorePoor.withAlpha(20),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: AppColors.scorePoor.withAlpha(60)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline,
                          color: AppColors.scorePoor, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _error!,
                          style: const TextStyle(
                              color: AppColors.scorePoor, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 24),
              // Quick suggestions
              const Text(
                'QUICK PICKS',
                style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 10,
                    letterSpacing: 0.8),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: const [
                  _QuickPick(label: 'London'),
                  _QuickPick(label: 'Manchester'),
                  _QuickPick(label: 'Edinburgh'),
                  _QuickPick(label: 'Bristol'),
                  _QuickPick(label: 'Leeds'),
                  _QuickPick(label: 'Cardiff'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickPick extends ConsumerWidget {
  final String label;
  const _QuickPick({required this.label});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () {
        final state =
            context.findAncestorStateOfType<_LocationSearchScreenState>();
        state?._search(label);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.surfaceBorder),
        ),
        child: Text(
          label,
          style:
              const TextStyle(color: AppColors.textSecondary, fontSize: 12),
        ),
      ),
    );
  }
}
