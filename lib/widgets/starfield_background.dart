import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

// ─── Data classes ─────────────────────────────────────────────────────────────

class _Star {
  final double x; // 0–1 normalised
  final double y;
  final double radius;
  final double phase;  // twinkle phase offset
  final double speed;  // twinkle speed
  final Color color;

  const _Star({
    required this.x,
    required this.y,
    required this.radius,
    required this.phase,
    required this.speed,
    required this.color,
  });
}

class _ShootingStar {
  double x, y;       // current position (0–1 normalised)
  final double dx, dy; // velocity per second (normalised)
  double progress;     // 0–1
  final double duration; // seconds
  final double length;   // trail length (normalised units)

  _ShootingStar({
    required this.x,
    required this.y,
    required this.dx,
    required this.dy,
    required this.duration,
    required this.length,
  }) : progress = 0;
}

class _Satellite {
  double x, y;
  final double dx, dy;
  double elapsed;
  final double duration;

  _Satellite({
    required this.x,
    required this.y,
    required this.dx,
    required this.dy,
    required this.duration,
  }) : elapsed = 0;
}

class _AlienShip {
  double x, y;
  final double baseY;
  final double dx;
  double elapsed;
  final double duration;

  _AlienShip({
    required this.x,
    required this.y,
    required this.dx,
    required this.duration,
  })  : baseY = y,
        elapsed = 0;
}

// ─── Widget ───────────────────────────────────────────────────────────────────

class StarfieldBackground extends StatefulWidget {
  const StarfieldBackground({super.key});

  @override
  State<StarfieldBackground> createState() => _StarfieldBackgroundState();
}

class _StarfieldBackgroundState extends State<StarfieldBackground>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  late final List<_Star> _stars;
  final List<_ShootingStar> _shootingStars = [];
  _Satellite? _satellite;
  _AlienShip? _alienShip;

  double _elapsed = 0; // total seconds since start
  double _lastShootingStarTime = -4.0;
  double _nextShootingStarInterval = 6.4;
  double _lastSatelliteTime = -24.0;
  double _nextSatelliteInterval = 48.0;
  double _lastAlienTime = -72.0;
  double _nextAlienInterval = 144.0;

  static const int _starCount = 200;
  final _rng = Random(42); // fixed seed for stable star layout

  @override
  void initState() {
    super.initState();
    _generateStars();
    _ticker = createTicker(_onTick)..start();
  }

  void _generateStars() {
    final rng = Random(42);
    _stars = List.generate(_starCount, (i) {
      final bright = rng.nextDouble() < 0.15;
      final radius = bright
          ? 1.6 + rng.nextDouble() * 0.9
          : 0.5 + rng.nextDouble() * 1.1;

      final colorRoll = rng.nextDouble();
      final Color color;
      if (colorRoll < 0.80) {
        color = const Color(0xFFE8EEF8); // blue-white
      } else if (colorRoll < 0.95) {
        color = const Color(0xFFFFF8E1); // warm white
      } else {
        color = const Color(0xFF80DEEA); // faint cyan
      }

      return _Star(
        x: rng.nextDouble(),
        y: rng.nextDouble(),
        radius: radius,
        phase: rng.nextDouble() * 2 * pi,
        speed: 0.4 + rng.nextDouble() * 1.2,
        color: color,
      );
    });
  }

  void _onTick(Duration elapsed) {
    final dt = elapsed.inMicroseconds / 1e6 - _elapsed;
    _elapsed = elapsed.inMicroseconds / 1e6;

    // Update shooting stars
    _shootingStars.removeWhere((s) => s.progress >= 1.0);
    for (final s in _shootingStars) {
      s.progress += dt / s.duration;
      s.x += s.dx * dt;
      s.y += s.dy * dt;
    }
    if (_shootingStars.length < 2 &&
        _elapsed - _lastShootingStarTime > _nextShootingStarInterval) {
      _spawnShootingStar();
      _lastShootingStarTime = _elapsed;
      _nextShootingStarInterval = 4.0 + _rng.nextDouble() * 8.0;
    }

    // Update satellite
    if (_satellite != null) {
      _satellite!.elapsed += dt;
      _satellite!.x += _satellite!.dx * dt;
      _satellite!.y += _satellite!.dy * dt;
      if (_satellite!.elapsed >= _satellite!.duration) _satellite = null;
    }
    if (_satellite == null &&
        _elapsed - _lastSatelliteTime > _nextSatelliteInterval) {
      _spawnSatellite();
      _lastSatelliteTime = _elapsed;
      _nextSatelliteInterval = 36.0 + _rng.nextDouble() * 36.0;
    }

    // Update alien ship
    if (_alienShip != null) {
      _alienShip!.elapsed += dt;
      _alienShip!.x += _alienShip!.dx * dt;
      _alienShip!.y = _alienShip!.baseY +
          0.02 * sin(_alienShip!.elapsed * 1.5 * pi);
      if (_alienShip!.elapsed >= _alienShip!.duration) _alienShip = null;
    }
    if (_alienShip == null &&
        _elapsed - _lastAlienTime > _nextAlienInterval) {
      _spawnAlienShip();
      _lastAlienTime = _elapsed;
      _nextAlienInterval = 96.0 + _rng.nextDouble() * 96.0;
    }

    setState(() {});
  }

  void _spawnShootingStar() {
    // Start along top edge or right edge
    final fromTop = _rng.nextBool();
    final double startX = fromTop ? _rng.nextDouble() : 1.0;
    final double startY = fromTop ? 0.0 : _rng.nextDouble() * 0.5;
    // Trajectory: generally down-left
    final angle = pi * (0.55 + _rng.nextDouble() * 0.2); // ~100–136 degrees
    final spd = 0.5 + _rng.nextDouble() * 0.4; // speed
    _shootingStars.add(_ShootingStar(
      x: startX,
      y: startY,
      dx: cos(angle) * spd,
      dy: sin(angle) * spd,
      duration: 0.3 + _rng.nextDouble() * 0.4,
      length: 0.08 + _rng.nextDouble() * 0.06,
    ));
  }

  void _spawnSatellite() {
    // Slow horizontal crossing from left, at a random vertical position
    final startY = 0.1 + _rng.nextDouble() * 0.5;
    final dur = 3.0 + _rng.nextDouble() * 3.0;
    _satellite = _Satellite(
      x: -0.02,
      y: startY,
      dx: 1.04 / dur,
      dy: (_rng.nextDouble() - 0.5) * 0.1 / dur,
      duration: dur,
    );
  }

  void _spawnAlienShip() {
    final fromLeft = _rng.nextBool();
    final startY = 0.05 + _rng.nextDouble() * 0.35;
    final dur = 4.0 + _rng.nextDouble() * 3.0;
    final speed = 1.04 / dur;
    _alienShip = _AlienShip(
      x: fromLeft ? -0.05 : 1.05,
      y: startY,
      dx: fromLeft ? speed : -speed,
      duration: dur,
    );
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: CustomPaint(
        painter: _StarfieldPainter(
          elapsed: _elapsed,
          stars: _stars,
          shootingStars: List.unmodifiable(_shootingStars),
          satellite: _satellite,
          alienShip: _alienShip,
        ),
        child: const SizedBox.expand(),
      ),
    );
  }
}

// ─── Painter ──────────────────────────────────────────────────────────────────

class _StarfieldPainter extends CustomPainter {
  final double elapsed;
  final List<_Star> stars;
  final List<_ShootingStar> shootingStars;
  final _Satellite? satellite;
  final _AlienShip? alienShip;

  const _StarfieldPainter({
    required this.elapsed,
    required this.stars,
    required this.shootingStars,
    required this.satellite,
    required this.alienShip,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Background
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = const Color(0xFF090E1A),
    );

    _drawStars(canvas, size);
    _drawShootingStars(canvas, size);
    _drawSatellite(canvas, size);
    _drawAlienShip(canvas, size);
  }

  void _drawStars(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    for (final star in stars) {
      final alpha = _lerp(
        120,
        255,
        (sin(elapsed * star.speed + star.phase) + 1) / 2,
      ).round().clamp(0, 255);
      paint.color = star.color.withAlpha(alpha);
      canvas.drawCircle(
        Offset(star.x * size.width, star.y * size.height),
        star.radius,
        paint,
      );
    }
  }

  void _drawShootingStars(Canvas canvas, Size size) {
    for (final s in shootingStars) {
      final headX = s.x * size.width;
      final headY = s.y * size.height;
      final tailDx = -s.dx * s.length * size.width;
      final tailDy = -s.dy * s.length * size.height;

      // Fade out near end of lifetime
      final alpha = (255 * (1.0 - s.progress)).round().clamp(0, 255);

      final paint = Paint()
        ..shader = LinearGradient(
          colors: [
            Colors.white.withAlpha(alpha),
            Colors.white.withAlpha(0),
          ],
        ).createShader(
          Rect.fromPoints(
            Offset(headX, headY),
            Offset(headX + tailDx, headY + tailDy),
          ),
        )
        ..strokeWidth = 1.5
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      final path = Path()
        ..moveTo(headX, headY)
        ..lineTo(headX + tailDx, headY + tailDy);
      canvas.drawPath(path, paint);

      // Bright head dot
      canvas.drawCircle(
        Offset(headX, headY),
        1.2,
        Paint()
          ..color = Colors.white.withAlpha(alpha)
          ..style = PaintingStyle.fill,
      );
    }
  }

  void _drawSatellite(Canvas canvas, Size size) {
    final sat = satellite;
    if (sat == null) return;

    final cx = sat.x * size.width;
    final cy = sat.y * size.height;

    // Short trail
    final trailPaint = Paint()
      ..color = const Color(0xFF80DEEA).withAlpha(60)
      ..strokeWidth = 1.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    canvas.drawLine(
      Offset(cx - sat.dx * size.width * 0.012,
          cy - sat.dy * size.height * 0.012),
      Offset(cx, cy),
      trailPaint,
    );

    // Dot
    canvas.drawCircle(
      Offset(cx, cy),
      1.5,
      Paint()
        ..color = const Color(0xFF80DEEA).withAlpha(140)
        ..style = PaintingStyle.fill,
    );
  }

  void _drawAlienShip(Canvas canvas, Size size) {
    final ship = alienShip;
    if (ship == null) return;

    final cx = ship.x * size.width;
    final cy = ship.y * size.height;

    // Fade in/out
    final fade = ship.elapsed < 0.5
        ? ship.elapsed / 0.5
        : ship.elapsed > ship.duration - 0.5
            ? (ship.duration - ship.elapsed) / 0.5
            : 1.0;
    final alpha = (fade * 220).round().clamp(0, 220);

    final bodyW = 28.0;
    final bodyH = 8.0;

    // Green glow ring
    canvas.drawOval(
      Rect.fromCenter(
          center: Offset(cx, cy + bodyH / 2), width: bodyW + 10, height: 6),
      Paint()
        ..color = const Color(0xFF00E676).withAlpha((alpha * 0.25).round())
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );

    // Saucer body
    canvas.drawOval(
      Rect.fromCenter(
          center: Offset(cx, cy + bodyH / 2), width: bodyW, height: bodyH),
      Paint()..color = const Color(0xFF78909C).withAlpha(alpha),
    );

    // Dome
    final domeRect =
        Rect.fromCenter(center: Offset(cx, cy + 2), width: 12, height: 8);
    canvas.drawArc(domeRect, pi, pi, false,
        Paint()..color = const Color(0xFFB0BEC5).withAlpha(alpha));

    // Window dots on body
    final dotPaint = Paint()
      ..color = const Color(0xFF00E676).withAlpha(alpha)
      ..style = PaintingStyle.fill;
    for (final xOff in [-6.0, 0.0, 6.0]) {
      canvas.drawCircle(Offset(cx + xOff, cy + bodyH / 2 + 1), 1.0, dotPaint);
    }
  }

  double _lerp(double a, double b, double t) => a + (b - a) * t;

  @override
  bool shouldRepaint(_StarfieldPainter old) =>
      old.elapsed != elapsed ||
      old.shootingStars.length != shootingStars.length ||
      old.satellite != satellite ||
      old.alienShip != alienShip;
}
