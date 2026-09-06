import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Lightweight Canvas particle emitter for target burst feedback
class ParticleExplosion extends StatefulWidget {
  final Offset position;
  final VoidCallback onComplete;
  final Color color;

  const ParticleExplosion({
    super.key,
    required this.position,
    required this.onComplete,
    this.color = AppTheme.accent,
  });

  @override
  State<ParticleExplosion> createState() => _ParticleExplosionState();
}

class _ParticleExplosionState extends State<ParticleExplosion> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<_Particle> _particles = [];
  final math.Random _random = math.Random();

  @override
  void initState() {
    super.initState();
    // Generate 12-16 micro particles
    final count = 12 + _random.nextInt(6);
    for (int i = 0; i < count; i++) {
      final angle = (i / count) * 2 * math.pi + (_random.nextDouble() * 0.4 - 0.2);
      final speed = 60.0 + _random.nextDouble() * 90.0;
      final size = 2.5 + _random.nextDouble() * 3.5;
      _particles.add(_Particle(
        velocity: Offset(math.cos(angle) * speed, math.sin(angle) * speed),
        size: size,
      ));
    }

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );

    _controller.forward().then((_) {
      if (mounted) {
        widget.onComplete();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return CustomPaint(
              painter: _ParticlePainter(
                origin: widget.position,
                particles: _particles,
                progress: _controller.value,
                color: widget.color,
              ),
            );
          },
        ),
      ),
    );
  }
}

class _Particle {
  final Offset velocity;
  final double size;

  _Particle({
    required this.velocity,
    required this.size,
  });
}

class _ParticlePainter extends CustomPainter {
  final Offset origin;
  final List<_Particle> particles;
  final double progress;
  final Color color;

  _ParticlePainter({
    required this.origin,
    required this.particles,
    required this.progress,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final opacity = (1.0 - progress).clamp(0.0, 1.0);
    final paint = Paint()
      ..color = color.withValues(alpha: opacity)
      ..style = PaintingStyle.fill;

    // Expanding shock ring
    final shockPaint = Paint()
      ..color = color.withValues(alpha: opacity * 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0 * (1.0 - progress);
    canvas.drawCircle(origin, progress * 48.0, shockPaint);

    for (final p in particles) {
      final pos = origin + (p.velocity * progress * 0.4);
      final radius = p.size * (1.0 - (progress * 0.7));
      canvas.drawCircle(pos, radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlePainter oldDelegate) => true;
}
