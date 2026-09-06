import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Floating animated text indicator (+10, +50 COMBO x3) floating up and fading
class FloatingScore extends StatefulWidget {
  final Offset position;
  final String text;
  final Color color;
  final VoidCallback onComplete;

  const FloatingScore({
    super.key,
    required this.position,
    required this.text,
    required this.color,
    required this.onComplete,
  });

  @override
  State<FloatingScore> createState() => _FloatingScoreState();
}

class _FloatingScoreState extends State<FloatingScore> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _translateY;
  late Animation<double> _opacity;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 550),
    );

    _translateY = Tween<double>(begin: 0.0, end: -45.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );

    _opacity = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.5, 1.0, curve: Curves.easeIn)),
    );

    _scale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween<double>(begin: 0.7, end: 1.25), weight: 30),
      TweenSequenceItem(tween: Tween<double>(begin: 1.25, end: 1.0), weight: 70),
    ]).animate(_controller);

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
    return Positioned(
      left: widget.position.dx - 60,
      top: widget.position.dy - 20,
      width: 120,
      child: IgnorePointer(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(0, _translateY.value),
              child: Transform.scale(
                scale: _scale.value,
                child: Opacity(
                  opacity: _opacity.value,
                  child: Center(
                    child: Text(
                      widget.text,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                        color: widget.color,
                        shadows: [
                          Shadow(
                            color: Colors.black.withValues(alpha: 0.8),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                          Shadow(
                            color: widget.color.withValues(alpha: 0.6),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Visual feedback for missed taps
class MissIndicator extends StatefulWidget {
  final Offset position;
  final VoidCallback onComplete;

  const MissIndicator({
    super.key,
    required this.position,
    required this.onComplete,
  });

  @override
  State<MissIndicator> createState() => _MissIndicatorState();
}

class _MissIndicatorState extends State<MissIndicator> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
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
    return Positioned(
      left: widget.position.dx - 20,
      top: widget.position.dy - 20,
      width: 40,
      height: 40,
      child: IgnorePointer(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final progress = _controller.value;
            final opacity = (1.0 - progress).clamp(0.0, 1.0);
            return Opacity(
              opacity: opacity,
              child: Transform.scale(
                scale: 0.8 + progress * 0.6,
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppTheme.danger,
                      width: 2.0 * (1.0 - progress),
                    ),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.close,
                      color: AppTheme.danger,
                      size: 16,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
