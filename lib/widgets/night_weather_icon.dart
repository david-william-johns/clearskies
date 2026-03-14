import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/day_forecast.dart';
import '../theme/app_theme.dart';

enum _NightCondition { clear, partlyCloudy, mostlyCloudy, overcast, rainy, snowy }

_NightCondition _deriveCondition(DayForecast f) {
  if (f.darkHourSlots.isEmpty) return _NightCondition.clear;
  final n = f.darkHourSlots.length;
  final avgCloud =
      f.darkHourSlots.map((s) => s.cloudCoverTotal).reduce((a, b) => a + b) ~/ n;
  final avgPrecip =
      f.darkHourSlots.map((s) => s.precipitationProbability).reduce((a, b) => a + b) ~/
          n;
  final avgTemp =
      f.darkHourSlots.map((s) => s.temperature).reduce((a, b) => a + b) / n;
  if (avgPrecip > 40 && avgTemp <= 1.0) return _NightCondition.snowy;
  if (avgPrecip > 40) return _NightCondition.rainy;
  if (avgCloud > 80) return _NightCondition.overcast;
  if (avgCloud > 50) return _NightCondition.mostlyCloudy;
  if (avgCloud > 20) return _NightCondition.partlyCloudy;
  return _NightCondition.clear;
}

/// Animated night-sky weather icon for collapsed day tile headers.
class NightWeatherIcon extends StatefulWidget {
  final DayForecast forecast;
  const NightWeatherIcon({super.key, required this.forecast});

  @override
  State<NightWeatherIcon> createState() => _NightWeatherIconState();
}

class _NightWeatherIconState extends State<NightWeatherIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late _NightCondition _condition;

  @override
  void initState() {
    super.initState();
    _condition = _deriveCondition(widget.forecast);
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => CustomPaint(
        size: const Size(52, 44),
        painter: _NightIconPainter(
          condition: _condition,
          t: _ctrl.value,
          moonPhase: widget.forecast.moonPhase,
        ),
      ),
    );
  }
}

// ─── Painter ──────────────────────────────────────────────────────────────────

class _NightIconPainter extends CustomPainter {
  final _NightCondition condition;
  final double t; // 0–1 animation progress
  final double moonPhase;

  const _NightIconPainter({
    required this.condition,
    required this.t,
    required this.moonPhase,
  });

  // Moon colour depending on how obscured it is
  static const _moonColor = Color(0xFFFFE082);
  static const _moonGlow = Color(0x33FFE082);
  static const _cloudColor = Color(0xFF90A4AE);
  static const _cloudDark = Color(0xFF546E7A);
  static const _rainColor = Color(0xFF4FC3F7);
  static const _snowColor = Color(0xFFE0F7FA);

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;

    switch (condition) {
      case _NightCondition.clear:
        _drawClear(canvas, size, cx, cy);
      case _NightCondition.partlyCloudy:
        _drawPartlyCloudy(canvas, size, cx, cy);
      case _NightCondition.mostlyCloudy:
        _drawMostlyCloudy(canvas, size, cx, cy);
      case _NightCondition.overcast:
        _drawOvercast(canvas, size, cx, cy);
      case _NightCondition.rainy:
        _drawRainy(canvas, size, cx, cy);
      case _NightCondition.snowy:
        _drawSnowy(canvas, size, cx, cy);
    }
  }

  // ── Clear: moon glow pulse + twinkling stars ─────────────────────────────

  void _drawClear(Canvas canvas, Size size, double cx, double cy) {
    // Pulsing glow
    final glow = 0.5 + 0.5 * math.sin(t * 2 * math.pi);
    final glowPaint = Paint()
      ..color = _moonGlow.withAlpha((glow * 60).round())
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawCircle(Offset(cx, cy - 2), 14, glowPaint);

    // Moon crescent
    _drawMoon(canvas, cx, cy - 2, 11);

    // Three stars
    final starPositions = [
      Offset(cx + 18, cy - 10),
      Offset(cx - 18, cy - 12),
      Offset(cx + 14, cy + 10),
    ];
    for (var i = 0; i < 3; i++) {
      final twinkle = 0.3 + 0.7 * math.sin((t + i * 0.33) * 2 * math.pi);
      final sp = Paint()
        ..color = Colors.white.withAlpha((twinkle * 200).round());
      canvas.drawCircle(starPositions[i], 1.5, sp);
    }
  }

  // ── Partly cloudy: cloud drifts across moon ──────────────────────────────

  void _drawPartlyCloudy(Canvas canvas, Size size, double cx, double cy) {
    // Moon (fixed)
    _drawMoon(canvas, cx - 6, cy - 4, 10);

    // Cloud drifts horizontally: offset from -8 to +8
    final drift = -8.0 + 16.0 * t;
    _drawCloud(canvas, cx + drift, cy + 4, 1.0, _cloudColor);
  }

  // ── Mostly cloudy: moon briefly visible ──────────────────────────────────

  void _drawMostlyCloudy(Canvas canvas, Size size, double cx, double cy) {
    // Moon fades in/out
    final vis = math.max(0.0, math.sin(t * 2 * math.pi));
    _drawMoon(canvas, cx - 4, cy - 6, 9, alpha: (vis * 180).round());

    // Two overlapping clouds
    _drawCloud(canvas, cx, cy + 2, 1.1, _cloudColor);
    _drawCloud(canvas, cx - 4, cy + 6, 0.8, _cloudDark);
  }

  // ── Overcast: solid rolling cloud bank ───────────────────────────────────

  void _drawOvercast(Canvas canvas, Size size, double cx, double cy) {
    // Moon hidden — faint glow behind clouds
    final glowPaint = Paint()
      ..color = _moonGlow.withAlpha(30)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
    canvas.drawCircle(Offset(cx, cy - 4), 10, glowPaint);

    // Rolling effect: slight horizontal sway
    final sway = 3.0 * math.sin(t * 2 * math.pi);
    _drawCloud(canvas, cx + sway, cy - 2, 1.3, _cloudDark);
    _drawCloud(canvas, cx - sway + 2, cy + 6, 1.0, _cloudColor);
  }

  // ── Rainy: cloud + falling drops ─────────────────────────────────────────

  void _drawRainy(Canvas canvas, Size size, double cx, double cy) {
    // Faint moon behind cloud
    final glowPaint = Paint()
      ..color = _moonGlow.withAlpha(25)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawCircle(Offset(cx - 4, cy - 8), 8, glowPaint);

    _drawCloud(canvas, cx, cy - 2, 1.1, _cloudDark);

    // 5 rain drops falling at different phases
    final rainPaint = Paint()
      ..color = _rainColor
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;
    final dropXs = [-14.0, -7.0, 0.0, 7.0, 14.0];
    for (var i = 0; i < 5; i++) {
      final phase = (t + i * 0.2) % 1.0;
      final dropY = cy + 6 + phase * 14;
      canvas.drawLine(
        Offset(cx + dropXs[i], dropY),
        Offset(cx + dropXs[i] - 1, dropY + 4),
        rainPaint,
      );
    }
  }

  // ── Snowy: cloud + falling flakes ────────────────────────────────────────

  void _drawSnowy(Canvas canvas, Size size, double cx, double cy) {
    final glowPaint = Paint()
      ..color = _moonGlow.withAlpha(25)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawCircle(Offset(cx - 4, cy - 8), 8, glowPaint);

    _drawCloud(canvas, cx, cy - 2, 1.1, _cloudDark);

    final snowPaint = Paint()..color = _snowColor;
    final flakeXs = [-12.0, -5.0, 2.0, 9.0, 16.0];
    for (var i = 0; i < 5; i++) {
      final phase = (t + i * 0.2) % 1.0;
      final flakeY = cy + 6 + phase * 14;
      final flakeX = cx + flakeXs[i] + 2 * math.sin((t + i) * 4 * math.pi);
      canvas.drawCircle(Offset(flakeX, flakeY), 1.5, snowPaint);
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  void _drawMoon(Canvas canvas, double cx, double cy, double r,
      {int alpha = 255}) {
    // Draw a crescent using two overlapping circles
    final moonPaint = Paint()..color = _moonColor.withAlpha(alpha);
    canvas.drawCircle(Offset(cx, cy), r, moonPaint);
    // Darken one side for crescent effect based on moon phase
    final offset = moonPhase < 0.5 ? r * 0.5 : -r * 0.5;
    final maskPaint = Paint()
      ..color = AppColors.background.withAlpha((alpha * 0.85).round())
      ..blendMode = BlendMode.srcOver;
    canvas.drawCircle(Offset(cx + offset, cy), r * 0.85, maskPaint);
  }

  void _drawCloud(
      Canvas canvas, double cx, double cy, double scale, Color color) {
    final p = Paint()..color = color;
    final r = 8.0 * scale;
    // Body
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(cx, cy + r * 0.4), width: r * 3.2, height: r * 1.2),
        Radius.circular(r * 0.6),
      ),
      p,
    );
    // Bumps
    canvas.drawCircle(Offset(cx - r * 0.7, cy), r * 0.72, p);
    canvas.drawCircle(Offset(cx + r * 0.4, cy - r * 0.1), r * 0.85, p);
    canvas.drawCircle(Offset(cx - r * 0.1, cy - r * 0.3), r * 0.7, p);
  }

  @override
  bool shouldRepaint(_NightIconPainter old) =>
      old.t != t || old.condition != condition;
}
