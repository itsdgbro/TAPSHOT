import 'package:flutter/material.dart';
import '../models/app_skin.dart';
import '../services/storage_service.dart';
import '../services/audio_service.dart';
import '../theme/app_theme.dart';
import '../widgets/tech_button.dart';

class SettingsScreen extends StatefulWidget {
  final StorageService storageService;
  final AudioService audioService;

  const SettingsScreen({
    super.key,
    required this.storageService,
    required this.audioService,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late bool _soundEnabled;
  late bool _hapticsEnabled;
  late AppSkin _selectedSkin;

  @override
  void initState() {
    super.initState();
    _soundEnabled = widget.storageService.isSoundEnabled();
    _hapticsEnabled = widget.storageService.isHapticsEnabled();
    _selectedSkin = widget.storageService.getSelectedSkin();
  }

  Future<void> _toggleSound(bool val) async {
    setState(() => _soundEnabled = val);
    await widget.storageService.setSoundEnabled(val);
    widget.audioService.playUiClick();
  }

  Future<void> _toggleHaptics(bool val) async {
    setState(() => _hapticsEnabled = val);
    await widget.storageService.setHapticsEnabled(val);
    widget.audioService.playUiClick();
  }

  Future<void> _selectSkin(AppSkin skin) async {
    if (!widget.storageService.isSkinUnlocked(skin)) {
      widget.audioService.playMiss();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppTheme.surfaceElevated,
          content: Text(
            'Locked! Reach a High Score of ${skin.unlockScoreRequirement} to unlock ${skin.nameUpper}.',
            style: const TextStyle(color: AppTheme.danger),
          ),
        ),
      );
      return;
    }

    setState(() => _selectedSkin = skin);
    await widget.storageService.setSelectedSkin(skin);
    widget.audioService.playUiClick();
  }

  Future<void> _showResetConfirmDialog() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppTheme.danger, width: 1.5),
        ),
        title: const Text('RESET SCORES?', style: TextStyle(color: AppTheme.danger, fontWeight: FontWeight.w900)),
        content: const Text(
          'This will permanently clear all local high scores and performance history. This action cannot be undone.',
          style: TextStyle(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('CANCEL', style: TextStyle(color: AppTheme.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.danger),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('RESET', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await widget.storageService.resetHighScores();
      widget.audioService.playUiClick();
      setState(() {
        _selectedSkin = widget.storageService.getSelectedSkin();
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: AppTheme.surfaceElevated,
            content: Text('All high scores have been reset.', style: TextStyle(color: AppTheme.accent)),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text(
          'SETTINGS',
          style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 3.0),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: AppTheme.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 6),
              // Target Themes Section
              const Text('TARGET THEME / SKINS', style: AppTheme.hudLabel),
              const SizedBox(height: 12),
              _buildSkinSelector(),

              const SizedBox(height: 28),
              // Preferences Section
              const Text('PREFERENCES', style: AppTheme.hudLabel),
              const SizedBox(height: 14),

              // Sound Toggle Card
              _buildSettingTile(
                title: 'Sound Effects',
                subtitle: 'Procedural synthetic audio feedback for hits, misses, and countdowns',
                icon: Icons.volume_up,
                value: _soundEnabled,
                onChanged: _toggleSound,
              ),

              const SizedBox(height: 14),

              // Haptic Toggle Card
              _buildSettingTile(
                title: 'Haptic Feedback',
                subtitle: 'Vibration feedback on targets and button presses',
                icon: Icons.vibration,
                value: _hapticsEnabled,
                onChanged: _toggleHaptics,
              ),

              const SizedBox(height: 28),
              const Text('DATA & RECORDS', style: AppTheme.hudLabel),
              const SizedBox(height: 14),

              // Reset High Scores Button
              TechButton(
                text: 'RESET ALL HIGH SCORES',
                isPrimary: false,
                icon: Icons.delete_outline,
                customAccent: AppTheme.danger,
                onPressed: _showResetConfirmDialog,
              ),

              const SizedBox(height: 32),

              // Game Version & Info Card
              Center(
                child: Column(
                  children: [
                    const Text(
                      'TAPSHOT v1.0.0',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 2.0,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '100% Offline High Performance Native Aim Trainer',
                      style: AppTheme.cardSubtitle.copyWith(color: AppTheme.textMuted),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSkinSelector() {
    return Column(
      children: AppSkin.values.map((skin) {
        final isSelected = _selectedSkin == skin;
        final isUnlocked = widget.storageService.isSkinUnlocked(skin);

        return GestureDetector(
          onTap: () => _selectSkin(skin),
          child: Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: AppTheme.techCardDecoration(
              borderColor: isSelected ? skin.primaryAccent : AppTheme.surfaceBorder,
              glow: isSelected,
            ),
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isUnlocked ? skin.primaryAccent : AppTheme.textMuted,
                    boxShadow: isUnlocked
                        ? [
                            BoxShadow(
                              color: skin.primaryAccent.withValues(alpha: 0.5),
                              blurRadius: 8,
                            ),
                          ]
                        : null,
                  ),
                  child: Center(
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            skin.nameUpper,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.2,
                              color: isUnlocked ? AppTheme.textPrimary : AppTheme.textMuted,
                            ),
                          ),
                          if (!isUnlocked) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppTheme.surfaceElevated,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '🔒 ${skin.unlockScoreRequirement} PTS',
                                style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppTheme.danger),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(skin.description, style: AppTheme.cardSubtitle),
                    ],
                  ),
                ),
                if (isSelected)
                  Icon(Icons.check_circle, color: skin.primaryAccent, size: 20)
                else if (!isUnlocked)
                  const Icon(Icons.lock_outline, color: AppTheme.textMuted, size: 18),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSettingTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.techCardDecoration(),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.surfaceElevated,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppTheme.surfaceBorder),
            ),
            child: Icon(icon, color: AppTheme.accent, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppTheme.textPrimary)),
                const SizedBox(height: 4),
                Text(subtitle, style: AppTheme.cardSubtitle),
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            activeThumbColor: AppTheme.accent,
            activeTrackColor: AppTheme.accent.withValues(alpha: 0.3),
            inactiveThumbColor: AppTheme.textMuted,
            inactiveTrackColor: AppTheme.surfaceElevated,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
