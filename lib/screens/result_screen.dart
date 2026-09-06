import 'package:flutter/material.dart';
import '../models/app_skin.dart';
import '../models/difficulty.dart';
import '../models/game_mode.dart';
import '../models/game_stats.dart';
import '../services/storage_service.dart';
import '../services/audio_service.dart';
import '../theme/app_theme.dart';
import '../widgets/tech_button.dart';
import 'game_screen.dart';

class ResultScreen extends StatelessWidget {
  final GameStats stats;
  final StorageService storageService;
  final AudioService audioService;

  const ResultScreen({
    super.key,
    required this.stats,
    required this.storageService,
    required this.audioService,
  });

  void _onPlayAgain(BuildContext context) {
    audioService.playUiClick();
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, anim, secAnim) => GameScreen(
          mode: stats.mode,
          difficulty: stats.difficulty,
          storageService: storageService,
          audioService: audioService,
        ),
        transitionsBuilder: (context, anim, secAnim, child) {
          return FadeTransition(opacity: anim, child: child);
        },
      ),
    );
  }

  void _onHome(BuildContext context) {
    audioService.playUiClick();
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final modeLabel = stats.mode == GameMode.endless
        ? 'ENDLESS MODE'
        : '30s • ${(stats.difficulty ?? Difficulty.medium).nameUpper}';
    final skin = storageService.getSelectedSkin();

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Mode Header
              Text(
                modeLabel,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 3.0,
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 6),

              // Title
              Text(
                stats.mode == GameMode.endless ? 'GAME OVER' : "TIME'S UP!",
                style: const TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 4.0,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 14),

              // New High Score Banner
              if (stats.isNewHighScore) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  decoration: BoxDecoration(
                    color: skin.primaryAccent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: skin.primaryAccent, width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: skin.primaryAccent.withValues(alpha: 0.3),
                        blurRadius: 14,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('🏆', style: TextStyle(fontSize: 18)),
                      const SizedBox(width: 8),
                      Text(
                        'NEW HIGH SCORE!',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2.0,
                          color: skin.primaryAccent,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // Score Spotlight Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 18),
                decoration: AppTheme.techCardDecoration(
                  borderColor: stats.isNewHighScore ? skin.primaryAccent : AppTheme.surfaceBorder,
                  glow: stats.isNewHighScore,
                ),
                child: Column(
                  children: [
                    const Text('FINAL SCORE', style: AppTheme.hudLabel),
                    const SizedBox(height: 4),
                    Text(
                      _formatScore(stats.score),
                      style: AppTheme.scoreHighlight.copyWith(
                        color: stats.isNewHighScore ? skin.primaryAccent : AppTheme.textPrimary,
                        fontSize: 48,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Detailed Performance Stats Matrix (6 Cards)
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.65,
                  physics: const BouncingScrollPhysics(),
                  children: [
                    _buildStatCard(
                      label: 'ACCURACY',
                      value: '${stats.accuracyPercentage}%',
                      accentColor: stats.accuracyPercentage >= 90
                          ? skin.primaryAccent
                          : (stats.accuracyPercentage >= 75 ? skin.secondaryAccent : AppTheme.textPrimary),
                    ),
                    _buildStatCard(
                      label: 'AVG REACTION',
                      value: stats.averageReactionTimeMs > 0 ? '${stats.averageReactionTimeMs}ms' : '—',
                      accentColor: stats.averageReactionTimeMs > 0 && stats.averageReactionTimeMs < 250
                          ? skin.primaryAccent
                          : AppTheme.textPrimary,
                    ),
                    _buildStatCard(
                      label: 'TARGETS HIT',
                      value: stats.hits.toString(),
                      accentColor: AppTheme.textPrimary,
                    ),
                    _buildStatCard(
                      label: 'FASTEST TAP',
                      value: stats.bestReactionTimeMs > 0 ? '${stats.bestReactionTimeMs}ms' : '—',
                      accentColor: skin.secondaryAccent,
                    ),
                    _buildStatCard(
                      label: 'MISSES',
                      value: stats.misses.toString(),
                      accentColor: stats.misses > 5 ? AppTheme.danger : AppTheme.textSecondary,
                    ),
                    _buildStatCard(
                      label: 'MAX COMBO',
                      value: stats.maxCombo > 1 ? '×${stats.maxCombo}' : '—',
                      accentColor: stats.maxCombo >= 10
                          ? const Color(0xFFFF2A4B)
                          : (stats.maxCombo >= 5 ? skin.primaryAccent : AppTheme.textPrimary),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // Action Buttons
              TechButton(
                text: 'PLAY AGAIN',
                icon: Icons.replay,
                isPrimary: true,
                onPressed: () => _onPlayAgain(context),
              ),
              const SizedBox(height: 10),
              TechButton(
                text: 'HOME',
                icon: Icons.home_outlined,
                isPrimary: false,
                onPressed: () => _onHome(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required String label,
    required String value,
    required Color accentColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: AppTheme.techCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label, style: AppTheme.hudLabel),
          const SizedBox(height: 3),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.8,
              color: accentColor,
            ),
          ),
        ],
      ),
    );
  }

  String _formatScore(int score) {
    return score.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        );
  }
}
