import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// TechButton creates a tactile, arcade-styled button with press feedback,
/// glowing accents, and high contrast.
class TechButton extends StatefulWidget {
  final String text;
  final VoidCallback onPressed;
  final bool isPrimary;
  final IconData? icon;
  final double height;
  final double? width;
  final Color? customAccent;

  const TechButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isPrimary = true,
    this.icon,
    this.height = 58,
    this.width,
    this.customAccent,
  });

  @override
  State<TechButton> createState() => _TechButtonState();
}

class _TechButtonState extends State<TechButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final accent = widget.customAccent ?? (widget.isPrimary ? AppTheme.accent : AppTheme.surfaceElevated);
    final borderColor = widget.isPrimary ? accent : AppTheme.surfaceBorder;
    final textColor = widget.isPrimary ? Colors.black : AppTheme.textPrimary;

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onPressed();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOutQuad,
        child: Container(
          height: widget.height,
          width: widget.width ?? double.infinity,
          decoration: BoxDecoration(
            color: widget.isPrimary ? accent : AppTheme.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: borderColor,
              width: 2.0,
            ),
            boxShadow: widget.isPrimary
                ? [
                    BoxShadow(
                      color: accent.withValues(alpha: _isPressed ? 0.15 : 0.35),
                      blurRadius: _isPressed ? 8 : 16,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.icon != null) ...[
                  Icon(widget.icon, color: textColor, size: 20),
                  const SizedBox(width: 8),
                ],
                Text(
                  widget.text,
                  style: widget.isPrimary
                      ? AppTheme.buttonText.copyWith(color: textColor)
                      : AppTheme.buttonSecondaryText,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
