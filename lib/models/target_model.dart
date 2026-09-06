import 'package:flutter/material.dart';

/// TargetModel encapsulates active target physics, position, radius, and lifecycle.
class TargetModel {
  final String id;
  Offset position; // Center position of the target
  final double radius;
  Offset velocity; // For drifting/moving targets
  final DateTime createdAt;
  final Duration lifetime;
  final int baseScore;
  final bool isMoving;

  TargetModel({
    required this.id,
    required this.position,
    required this.radius,
    required this.velocity,
    required this.createdAt,
    required this.lifetime,
    this.baseScore = 10,
    this.isMoving = false,
  });

  /// Returns remaining lifetime ratio from 1.0 (spawned) down to 0.0 (expired)
  double remainingRatio(DateTime now) {
    final elapsed = now.difference(createdAt).inMilliseconds;
    final total = lifetime.inMilliseconds;
    if (total <= 0) return 0.0;
    final ratio = 1.0 - (elapsed / total);
    return ratio.clamp(0.0, 1.0);
  }

  /// Whether the target's lifetime has expired
  bool isExpired(DateTime now) {
    return now.difference(createdAt) >= lifetime;
  }

  /// Checks whether a tap at [tapPosition] intersects with the target circular hit area
  bool contains(Offset tapPosition) {
    // Generous precision: slight padding for optimal feel on mobile touchscreens
    final distance = (tapPosition - position).distance;
    return distance <= (radius * 1.12);
  }

  /// Updates position based on velocity and bounces off [bounds]
  void updatePosition(double dtSeconds, Rect bounds) {
    if (!isMoving || velocity == Offset.zero) return;

    double newX = position.dx + velocity.dx * dtSeconds;
    double newY = position.dy + velocity.dy * dtSeconds;
    double vx = velocity.dx;
    double vy = velocity.dy;

    // Bounce horizontally
    if (newX - radius < bounds.left) {
      newX = bounds.left + radius;
      vx = -vx;
    } else if (newX + radius > bounds.right) {
      newX = bounds.right - radius;
      vx = -vx;
    }

    // Bounce vertically
    if (newY - radius < bounds.top) {
      newY = bounds.top + radius;
      vy = -vy;
    } else if (newY + radius > bounds.bottom) {
      newY = bounds.bottom - radius;
      vy = -vy;
    }

    position = Offset(newX, newY);
    velocity = Offset(vx, vy);
  }
}
