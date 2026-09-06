import 'package:flutter/material.dart';
import '../models/app_skin.dart';
import '../models/game_mode.dart';
import '../services/storage_service.dart';
import '../services/audio_service.dart';
import '../theme/app_theme.dart';
import '../widgets/tech_button.dart';
import 'difficulty_screen.dart';
import 'game_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  final StorageService storageService;
  final AudioService audioService;

  const HomeScreen({
    super.key,
    required this.storageService,
    required this.audioService,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _endlessHigh = 0;
  int _timedBestHigh = 0;
  late AppSkin _skin;
  List<GameRecord> _history = [];

  @override
  void initState() {
    super.initState();
    _loadState();
  }

  void _loadState() {
    setState(() {
      _endlessHigh = widget.storageService.getEndlessHighScore();
      _timedBestHigh = widget.storageService.getBestOverallTimedHighScore();
      _skin = widget.storageService.getSelectedSkin();
      _history = widget.storageService.getHistoryRecords();
    });
  }

  void _onStartEndless() {
    widget.audioService.playUiClick();
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, anim, secAnim) => GameScreen(
          mode: GameMode.endless,
          storageService: widget.storageService,
          audioService: widget.audioService,
        ),
        transitionsBuilder: (context, anim, secAnim, child) {
          return FadeTransition(opacity: anim, child: child);
        },
      ),
    ).then((_) => _loadState());
  }

  void _onStartTimed() {
    widget.audioService.playUiClick();
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, anim, secAnim) => DifficultyScreen(
          storageService: widget.storageService,
          audioService: widget.audioService,
        ),
        transitionsBuilder: (context, anim, secAnim, child) {
          return FadeTransition(opacity: anim, child: child);
        },
      ),
    ).then((_) => _loadState());
  }

  void _onOpenSettings() {
    widget.audioService.playUiClick();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => SettingsScreen(
          storageService: widget.storageService,
          audioService: widget.audioService,
        ),
      ),
    ).then((_) => _loadState());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Top Bar with Active Skin & Settings
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: _skin.primaryAccent.withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _skin.primaryAccent,
                            boxShadow: [
                              BoxShadow(color: _skin.primaryAccent, blurRadius: 4),
                            ],
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _skin.nameUpper,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.0,
                            color: _skin.primaryAccent,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.surfaceBorder),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.settings_outlined, color: AppTheme.textPrimary, size: 22),
                      tooltip: 'Settings & Skins',
                      onPressed: _onOpenSettings,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              // Brand Header
              Text(
                'TAPSHOT',
                style: AppTheme.brandTitle.copyWith(
                  shadows: [
                    Shadow(color: _skin.primaryAccent.withValues(alpha: 0.25), blurRadius: 16),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              Text('AIM. REACT. REPEAT.', style: AppTheme.brandTagline.copyWith(color: _skin.primaryAccent)),

              const SizedBox(height: 24),

              // High Scores Summary Cards
              Row(
                children: [
                  Expanded(
                    child: _buildHighScoreCard(
                      title: 'BEST ENDLESS',
                      score: _endlessHigh,
                      accentColor: _skin.primaryAccent,
                      icon: Icons.all_inclusive,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildHighScoreCard(
                      title: 'BEST 30s',
                      score: _timedBestHigh,
                      accentColor: _skin.secondaryAccent,
                      icon: Icons.timer_outlined,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Recent Performance Sparkline Bar / Activity
              if (_history.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: AppTheme.techCardDecoration(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('RECENT ACCURACY', style: AppTheme.hudLabel),
                          Text(
                            'LAST ${_history.length} MATCHES',
                            style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppTheme.textMuted),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        height: 38,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: _history.reversed.map((record) {
                            final ratio = (record.accuracy / 100.0).clamp(0.1, 1.0);
                            final isTop = record.accuracy >= 90;
                            return Expanded(
                              child: Container(
                                margin: const EdgeInsets.symmetric(horizontal: 3),
                                height: 38 * ratio,
                                decoration: BoxDecoration(
                                  color: isTop ? _skin.primaryAccent : AppTheme.secondary.withValues(alpha: 0.6),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const Spacer(),

              // Game Mode Buttons
              TechButton(
                text: 'ENDLESS MODE',
                isPrimary: true,
                customAccent: _skin.primaryAccent,
                icon: Icons.play_arrow,
                onPressed: _onStartEndless,
              ),

              const SizedBox(height: 14),

              TechButton(
                text: '30 SECONDS',
                isPrimary: false,
                icon: Icons.timer,
                onPressed: _onStartTimed,
              ),

              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHighScoreCard({
    required String title,
    required int score,
    required Color accentColor,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: AppTheme.techCardDecoration(borderColor: accentColor.withValues(alpha: 0.3)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: accentColor),
              const SizedBox(width: 6),
              Text(
                title,
                style: AppTheme.hudLabel.copyWith(color: accentColor),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            score > 0 ? _formatScore(score) : '—',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.0,
              color: score > 0 ? AppTheme.textPrimary : AppTheme.textMuted,
            ),
          ),
          const SizedBox(height: 2),
          const Text('POINTS', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppTheme.textMuted)),
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
