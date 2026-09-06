import 'package:flutter/material.dart';
import '../models/difficulty.dart';
import '../models/game_mode.dart';
import '../services/storage_service.dart';
import '../services/audio_service.dart';
import '../theme/app_theme.dart';
import 'game_screen.dart';

class DifficultyScreen extends StatelessWidget {
  final StorageService storageService;
  final AudioService audioService;

  const DifficultyScreen({
    super.key,
    required this.storageService,
    required this.audioService,
  });

  void _onSelectDifficulty(BuildContext context, Difficulty difficulty) {
    audioService.playUiClick();
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, anim, secAnim) => GameScreen(
          mode: GameMode.timed,
          difficulty: difficulty,
          storageService: storageService,
          audioService: audioService,
        ),
        transitionsBuilder: (context, anim, secAnim, child) {
          return FadeTransition(opacity: anim, child: child);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text(
          'SELECT DIFFICULTY',
          style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2.5, fontSize: 18),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: AppTheme.textPrimary),
          onPressed: () {
            audioService.playUiClick();
            Navigator.of(context).pop();
          },
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                '30 SECONDS CHALLENGE',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2.5,
                  color: AppTheme.accent,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Choose your target precision intensity',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 32),

              // Difficulty Cards
              _buildDifficultyOption(
                context: context,
                difficulty: Difficulty.easy,
                accentColor: AppTheme.secondary,
                badge: 'BEGINNER',
                speedLabel: '1.6s Lifetime • Large Static Targets',
              ),
              const SizedBox(height: 18),

              _buildDifficultyOption(
                context: context,
                difficulty: Difficulty.medium,
                accentColor: AppTheme.accent,
                badge: 'STANDARD',
                speedLabel: '1.1s Lifetime • Medium Drifting Targets',
              ),
              const SizedBox(height: 18),

              _buildDifficultyOption(
                context: context,
                difficulty: Difficulty.hard,
                accentColor: AppTheme.danger,
                badge: 'EXPERT',
                speedLabel: '0.75s Lifetime • Rapid Motion & Precision',
              ),

              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDifficultyOption({
    required BuildContext context,
    required Difficulty difficulty,
    required Color accentColor,
    required String badge,
    required String speedLabel,
  }) {
    final highScore = storageService.getTimedHighScore(difficulty);

    return InkWell(
      onTap: () => _onSelectDifficulty(context, difficulty),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: AppTheme.techCardDecoration(borderColor: accentColor.withValues(alpha: 0.5)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: accentColor,
                        boxShadow: [
                          BoxShadow(color: accentColor.withValues(alpha: 0.8), blurRadius: 6),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      difficulty.nameUpper,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2.0,
                        color: accentColor,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: accentColor.withValues(alpha: 0.4)),
                  ),
                  child: Text(
                    badge,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.2,
                      color: accentColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              difficulty.subtitle,
              style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 6),
            Text(
              speedLabel,
              style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'HIGH SCORE: ${highScore > 0 ? highScore : '—'}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.0,
                    color: AppTheme.textSecondary,
                  ),
                ),
                Icon(Icons.arrow_forward_ios, size: 14, color: accentColor),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
