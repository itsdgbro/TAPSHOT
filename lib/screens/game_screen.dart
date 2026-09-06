import 'package:flutter/material.dart';
import '../controllers/game_controller.dart';
import '../models/app_skin.dart';
import '../models/difficulty.dart';
import '../models/game_mode.dart';
import '../services/storage_service.dart';
import '../services/audio_service.dart';
import '../theme/app_theme.dart';
import '../widgets/floating_score.dart';
import '../widgets/game_hud.dart';
import '../widgets/particle_explosion.dart';
import '../widgets/target_painter.dart';
import 'result_screen.dart';

class GameScreen extends StatefulWidget {
  final GameMode mode;
  final Difficulty? difficulty;
  final StorageService storageService;
  final AudioService audioService;

  const GameScreen({
    super.key,
    required this.mode,
    this.difficulty,
    required this.storageService,
    required this.audioService,
  });

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late GameController _controller;
  final GlobalKey _arenaKey = GlobalKey();
  final List<_ExplosionEffect> _activeExplosions = [];
  late AppSkin _skin;

  @override
  void initState() {
    super.initState();
    _skin = widget.storageService.getSelectedSkin();
    _controller = GameController(
      mode: widget.mode,
      difficulty: widget.difficulty,
      storageService: widget.storageService,
      audioService: widget.audioService,
      skin: _skin,
    );

    _controller.addListener(_onControllerUpdate);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _calculateAndInitPlayableArea();
    });
  }

  void _calculateAndInitPlayableArea() {
    final renderBox = _arenaKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox != null && renderBox.hasSize) {
      final size = renderBox.size;
      const padding = 20.0;
      final area = Rect.fromLTWH(
        padding,
        padding,
        size.width - (padding * 2),
        size.height - (padding * 2),
      );
      _controller.initPlayableArea(area);
      _controller.startGame();
    }
  }

  void _onControllerUpdate() {
    if (!mounted) return;

    if (_controller.isGameOver) {
      _showResultScreen();
    }
  }

  void _showResultScreen() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, anim, secAnim) => ResultScreen(
          stats: _controller.stats,
          storageService: widget.storageService,
          audioService: widget.audioService,
        ),
        transitionsBuilder: (context, anim, secAnim, child) {
          return FadeTransition(opacity: anim, child: child);
        },
      ),
    );
  }

  void _onArenaTapDown(TapDownDetails details) {
    _controller.handleTap(details.localPosition);
  }

  void _onTargetTap(Offset position, Color color) {
    setState(() {
      _activeExplosions.add(
        _ExplosionEffect(
          id: 'exp_${DateTime.now().microsecondsSinceEpoch}',
          position: position,
          color: color,
        ),
      );
    });
  }

  void _togglePause() {
    if (_controller.isPaused) {
      _controller.resumeGame();
    } else {
      _controller.pauseGame();
      _showPauseModal();
    }
  }

  Future<void> _showPauseModal() async {
    final action = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppTheme.surfaceBorder, width: 1.5),
        ),
        title: const Center(
          child: Text(
            'PAUSED',
            style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 4.0, color: AppTheme.textPrimary),
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _skin.primaryAccent,
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () => Navigator.of(ctx).pop('resume'),
              child: const Text('RESUME', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900)),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.danger,
                side: const BorderSide(color: AppTheme.danger),
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () => Navigator.of(ctx).pop('quit'),
              child: const Text('QUIT TO HOME', style: TextStyle(fontWeight: FontWeight.w900)),
            ),
          ],
        ),
      ),
    );

    if (action == 'quit') {
      if (mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } else {
      _controller.resumeGame();
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerUpdate);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: ListenableBuilder(
        listenable: _controller,
        builder: (context, _) {
          final target = _controller.activeTarget;
          final isFrenzy = _controller.stats.isFrenzy;

          return Column(
            children: [
              // Real-time HUD (Safe from any target overlap)
              GameHud(
                stats: _controller.stats,
                skin: _skin,
                onPauseTap: _togglePause,
              ),

              // Interactive Gameplay Arena
              Expanded(
                child: GestureDetector(
                  key: _arenaKey,
                  behavior: HitTestBehavior.opaque,
                  onTapDown: _onArenaTapDown,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // 1. Subtle Precision Background Grid Canvas
                      CustomPaint(
                        painter: _GridBackgroundPainter(
                          gridColor: isFrenzy
                              ? const Color(0xFFFF2A4B).withValues(alpha: 0.15)
                              : _skin.primaryAccent.withValues(alpha: 0.08),
                        ),
                      ),

                      // 2. Active Target
                      if (target != null)
                        TargetWidget(
                          key: ValueKey(target.id),
                          target: target,
                          skin: _skin,
                          isFrenzy: isFrenzy,
                          onTap: () {
                            _onTargetTap(
                              target.position,
                              isFrenzy
                                  ? const Color(0xFFFF2A4B)
                                  : (_controller.stats.combo >= 5 ? _skin.secondaryAccent : _skin.primaryAccent),
                            );
                            _controller.handleTap(target.position);
                          },
                        ),

                      // 3. Particle Explosions
                      for (final exp in _activeExplosions)
                        ParticleExplosion(
                          key: ValueKey(exp.id),
                          position: exp.position,
                          color: exp.color,
                          onComplete: () {
                            setState(() => _activeExplosions.removeWhere((e) => e.id == exp.id));
                          },
                        ),

                      // 4. Floating Score Labels
                      for (final popup in _controller.scorePopups)
                        FloatingScore(
                          key: ValueKey(popup.id),
                          position: popup.position,
                          text: popup.text,
                          color: popup.color,
                          onComplete: () => _controller.removeScorePopup(popup.id),
                        ),

                      // 5. Miss Feedback Indicators
                      for (final miss in _controller.missPopups)
                        MissIndicator(
                          key: ValueKey(miss.id),
                          position: miss.position,
                          onComplete: () => _controller.removeMissPopup(miss.id),
                        ),

                      // 6. 3-2-1 Countdown Ready Gate Overlay
                      if (_controller.isCountingDown)
                        Container(
                          color: Colors.black.withValues(alpha: 0.75),
                          child: Center(
                            child: TweenAnimationBuilder<double>(
                              key: ValueKey(_controller.countdownNumber),
                              tween: Tween(begin: 1.5, end: 1.0),
                              duration: const Duration(milliseconds: 500),
                              curve: Curves.easeOutBack,
                              builder: (context, scale, child) {
                                return Transform.scale(
                                  scale: scale,
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        'GET READY',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 4.0,
                                          color: _skin.secondaryAccent,
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        '${_controller.countdownNumber}',
                                        style: TextStyle(
                                          fontSize: 96,
                                          fontWeight: FontWeight.w900,
                                          color: _skin.primaryAccent,
                                          shadows: [
                                            Shadow(
                                              color: _skin.primaryAccent.withValues(alpha: 0.6),
                                              blurRadius: 28,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ExplosionEffect {
  final String id;
  final Offset position;
  final Color color;

  _ExplosionEffect({
    required this.id,
    required this.position,
    required this.color,
  });
}

class _GridBackgroundPainter extends CustomPainter {
  final Color gridColor;

  const _GridBackgroundPainter({
    this.gridColor = const Color(0x15FFFFFF),
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = gridColor
      ..strokeWidth = 0.8;

    const step = 40.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _GridBackgroundPainter oldDelegate) => oldDelegate.gridColor != gridColor;
}
