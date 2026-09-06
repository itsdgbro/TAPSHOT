import 'package:flutter/material.dart';
import '../models/app_skin.dart';
import '../models/game_mode.dart';
import '../models/game_stats.dart';
import '../theme/app_theme.dart';

/// GameHud displays real-time statistics: SCORE, LIVES / TIME, COMBO, ACCURACY, and REACTION TIME
class GameHud extends StatelessWidget {
  final GameStats stats;
  final VoidCallback onPauseTap;
  final AppSkin skin;

  const GameHud({
    super.key,
    required this.stats,
    required this.onPauseTap,
    this.skin = AppSkin.volt,
  });

  @override
  Widget build(BuildContext context) {
    final primaryAccent = stats.isFrenzy ? const Color(0xFFFF2A4B) : skin.primaryAccent;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.surface.withValues(alpha: 0.9),
        border: Border(
          bottom: BorderSide(
            color: stats.isFrenzy ? const Color(0xFFFF2A4B) : AppTheme.surfaceBorder,
            width: stats.isFrenzy ? 2.5 : 1.5,
          ),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (stats.isFrenzy) ...[
              Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF2A4B).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: const Color(0xFFFF2A4B)),
                ),
                child: const Text(
                  '🔥 OVERDRIVE FRENZY ACTIVE (2× SCORE) 🔥',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                    color: Color(0xFFFF2A4B),
                  ),
                ),
              ),
            ],
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // 1. Score Counter
                _buildStatColumn(
                  label: 'SCORE',
                  value: stats.score.toString(),
                  valueColor: primaryAccent,
                ),

                // 2. Primary Game Mode Metric (Lives or Time)
                if (stats.mode == GameMode.endless)
                  _buildLivesIndicator(stats.livesRemaining)
                else
                  _buildTimerIndicator(stats.timeRemaining),

                // 3. Reaction Time in ms
                _buildStatColumn(
                  label: 'REACTION',
                  value: stats.averageReactionTimeMs > 0 ? '${stats.averageReactionTimeMs}ms' : '—',
                  valueColor: stats.averageReactionTimeMs > 0 && stats.averageReactionTimeMs < 250
                      ? AppTheme.accent
                      : AppTheme.textPrimary,
                ),

                // 4. Combo Multiplier
                _buildStatColumn(
                  label: 'COMBO',
                  value: stats.combo > 1 ? '×${stats.combo}' : '—',
                  valueColor: stats.combo >= 10
                      ? const Color(0xFFFF2A4B)
                      : (stats.combo >= 5 ? skin.secondaryAccent : AppTheme.textPrimary),
                ),

                // 5. Accuracy %
                _buildStatColumn(
                  label: 'ACCURACY',
                  value: '${stats.accuracyPercentage}%',
                  valueColor: AppTheme.textPrimary,
                ),

                // 6. Pause Button
                IconButton(
                  onPressed: onPauseTap,
                  icon: const Icon(Icons.pause, color: AppTheme.textSecondary, size: 22),
                  tooltip: 'Pause',
                  splashRadius: 20,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatColumn({
    required String label,
    required String value,
    required Color valueColor,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(label, style: AppTheme.hudLabel),
        const SizedBox(height: 2),
        Text(
          value,
          style: AppTheme.hudValue.copyWith(color: valueColor, fontSize: 18),
        ),
      ],
    );
  }

  Widget _buildLivesIndicator(int lives) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text('LIVES', style: AppTheme.hudLabel),
        const SizedBox(height: 5),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (index) {
            final active = index < lives;
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 2.0),
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: active ? AppTheme.danger : Colors.transparent,
                border: Border.all(
                  color: active ? AppTheme.danger : AppTheme.surfaceBorder,
                  width: 1.5,
                ),
                boxShadow: active
                    ? [
                        BoxShadow(
                          color: AppTheme.danger.withValues(alpha: 0.5),
                          blurRadius: 5,
                        ),
                      ]
                    : null,
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildTimerIndicator(double seconds) {
    final isUrgent = seconds <= 5.0;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text('TIME', style: AppTheme.hudLabel),
        const SizedBox(height: 2),
        Text(
          '${seconds.toStringAsFixed(1)}s',
          style: AppTheme.hudValue.copyWith(
            fontSize: 18,
            color: isUrgent ? AppTheme.danger : AppTheme.secondary,
          ),
        ),
      ],
    );
  }
}
