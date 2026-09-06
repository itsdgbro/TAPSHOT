import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/app_skin.dart';
import '../models/target_model.dart';
import '../theme/app_theme.dart';

/// TargetPainter creates a custom-painted Minimalist Precision target supporting unlockable skins:
/// - Outer countdown ring showing remaining lifetime
/// - High-contrast concentric geometric rings
/// - Neon center bulls-eye point
/// - Precision crosshair ticks
class TargetPainter extends CustomPainter {
  final TargetModel target;
  final DateTime currentTime;
  final AppSkin skin;
  final bool isFrenzy;

  TargetPainter({
    required this.target,
    required this.currentTime,
    this.skin = AppSkin.volt,
    this.isFrenzy = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = target.radius;
    final lifeRatio = target.remainingRatio(currentTime);

    final primaryColor = isFrenzy ? const Color(0xFFFF2A4B) : skin.primaryAccent;
    final secondaryColor = isFrenzy ? const Color(0xFFFF9100) : skin.secondaryAccent;

    // 1. Outer Glow
    final glowPaint = Paint()
      ..color = (lifeRatio < 0.3 ? AppTheme.danger : primaryColor).withValues(alpha: isFrenzy ? 0.4 : 0.22)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, isFrenzy ? 18 : 12);
    canvas.drawCircle(center, radius + (isFrenzy ? 6 : 4), glowPaint);

    // 2. Dark backdrop circle
    final bgPaint = Paint()
      ..color = AppTheme.surfaceElevated
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius, bgPaint);

    // 3. Lifetime Countdown Ring (Arc that shrinks around outer edge)
    final ringPaint = Paint()
      ..color = lifeRatio < 0.25 ? AppTheme.danger : primaryColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = isFrenzy ? 3.5 : 2.5
      ..strokeCap = StrokeCap.round;

    final sweepAngle = 2 * math.pi * lifeRatio;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      sweepAngle,
      false,
      ringPaint,
    );

    // 4. Static track circle
    final trackPaint = Paint()
      ..color = AppTheme.surfaceBorder.withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawCircle(center, radius, trackPaint);

    // 5. Middle Ring
    final midPaint = Paint()
      ..color = secondaryColor.withValues(alpha: 0.45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawCircle(center, radius * 0.58, midPaint);

    // 6. Crosshair ticks (4 cardinal precision notches)
    final tickPaint = Paint()
      ..color = primaryColor.withValues(alpha: 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final tickLength = radius * 0.22;
    // Top
    canvas.drawLine(Offset(center.dx, center.dy - radius), Offset(center.dx, center.dy - radius + tickLength), tickPaint);
    // Bottom
    canvas.drawLine(Offset(center.dx, center.dy + radius), Offset(center.dx, center.dy + radius - tickLength), tickPaint);
    // Left
    canvas.drawLine(Offset(center.dx - radius, center.dy), Offset(center.dx - radius + tickLength, center.dy), tickPaint);
    // Right
    canvas.drawLine(Offset(center.dx + radius, center.dy), Offset(center.dx + radius - tickLength, center.dy), tickPaint);

    // 7. Center Bullseye Solid Dot
    final centerDotPaint = Paint()
      ..color = lifeRatio < 0.25 ? AppTheme.danger : primaryColor
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius * 0.24, centerDotPaint);

    // Inner pure white precision pin
    final innerDotPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius * 0.10, innerDotPaint);
  }

  @override
  bool shouldRepaint(covariant TargetPainter oldDelegate) {
    return true; // Continuously animate sweep angle
  }
}

/// TargetWidget hosts the TargetPainter with entrance scale/spawn animations
class TargetWidget extends StatefulWidget {
  final TargetModel target;
  final VoidCallback onTap;
  final AppSkin skin;
  final bool isFrenzy;

  const TargetWidget({
    super.key,
    required this.target,
    required this.onTap,
    this.skin = AppSkin.volt,
    this.isFrenzy = false,
  });

  @override
  State<TargetWidget> createState() => _TargetWidgetState();
}

class _TargetWidgetState extends State<TargetWidget> with SingleTickerProviderStateMixin {
  late AnimationController _spawnController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _spawnController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 140),
    );
    _scaleAnimation = CurvedAnimation(
      parent: _spawnController,
      curve: Curves.easeOutBack,
    );
    _spawnController.forward();
  }

  @override
  void didUpdateWidget(covariant TargetWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.target.id != widget.target.id) {
      _spawnController.reset();
      _spawnController.forward();
    }
  }

  @override
  void dispose() {
    _spawnController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.target.radius * 2 + 16; // Margin for glow and stroke

    return Positioned(
      left: widget.target.position.dx - (size / 2),
      top: widget.target.position.dy - (size / 2),
      width: size,
      height: size,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (_) => widget.onTap(),
          child: CustomPaint(
            size: Size(size, size),
            painter: TargetPainter(
              target: widget.target,
              currentTime: DateTime.now(),
              skin: widget.skin,
              isFrenzy: widget.isFrenzy,
            ),
          ),
        ),
      ),
    );
  }
}
