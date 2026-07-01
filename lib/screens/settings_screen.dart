import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../constants.dart';
import '../l10n/app_localizations.dart';
import '../services/download_service.dart';
import '../services/language_service.dart';
import '../services/theme_service.dart';
import '../services/translation_service.dart';
import '../services/update_service.dart';
import 'downloads_screen.dart';

String _formatBytes(int bytes) {
  if (bytes == 0) return '0 B';
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
  return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
}

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context)!;
    final theme = Theme.of(context);
    final update = context.watch<UpdateService>();

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsTitle)),
      body: ListView(
        children: [
          _SectionHeader(label: l10n.appearanceSection),
          _ThemeTile(),
          const Divider(height: 1, indent: 16, endIndent: 16),
          _SectionHeader(label: l10n.languageSection),
          _LanguageTile(),
          const Divider(height: 1, indent: 16, endIndent: 16),
          _SectionHeader(label: l10n.storageSection),
          _ClearCacheTile(),
          const Divider(height: 1, indent: 16, endIndent: 16),
          _SectionHeader(label: l10n.downloadsHeader),
          _DownloadsTile(),
          const Divider(height: 1, indent: 16, endIndent: 16),
          _SectionHeader(label: l10n.aboutSection),
          _GitHubTile(),
          const SizedBox(height: 32),
          Center(
            child: Text(
              update.currentVersion.isNotEmpty
                  ? 'v${update.currentVersion}'
                  : '',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String label;
  const _SectionHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          color: Theme.of(context).colorScheme.primary,
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

class _ThemeTile extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context)!;
    final themeService = context.watch<ThemeService>();
    final current = themeService.themeMode;

    final options = [
      (ThemeMode.system, l10n.themeSystem, Icons.brightness_auto_outlined),
      (ThemeMode.light, l10n.themeLight, Icons.light_mode_outlined),
      (ThemeMode.dark, l10n.themeDark, Icons.dark_mode_outlined),
    ];

    return ListTile(
      leading: const Icon(Icons.contrast),
      title: Text(l10n.themeMode),
      subtitle: Text(_currentLabel(current, l10n)),
      onTap: () {
        showModalBottomSheet<void>(
          context: context,
          builder: (ctx) => SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                    child: Text(
                      l10n.themeMode,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                  for (final (mode, label, icon) in options)
                    ListTile(
                      leading: Icon(icon,
                          color: mode == current
                              ? Theme.of(context).colorScheme.primary
                              : null),
                      title: Text(
                        label,
                        style: TextStyle(
                          color: mode == current
                              ? Theme.of(context).colorScheme.primary
                              : null,
                          fontWeight: mode == current
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                      trailing: mode == current
                          ? Icon(Icons.check,
                              color: Theme.of(context).colorScheme.primary,
                              size: 18)
                          : null,
                      onTap: () {
                        context.read<ThemeService>().setThemeMode(mode);
                        Navigator.pop(ctx);
                      },
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String _currentLabel(ThemeMode mode, AppL10n l10n) {
    switch (mode) {
      case ThemeMode.light:
        return l10n.themeLight;
      case ThemeMode.dark:
        return l10n.themeDark;
      case ThemeMode.system:
        return l10n.themeSystem;
    }
  }
}

class _LanguageTile extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context)!;
    final lang = context.watch<LanguageService>();

    final options = [
      ('nl', '🇳🇱', 'Nederlands'),
      ('en', '🇬🇧', 'English'),
      ('es', '🇪🇸', 'Español'),
      ('de', '🇩🇪', 'Deutsch'),
      ('it', '🇮🇹', 'Italiano'),
    ];

    final currentLabel = options
        .firstWhere((e) => e.$1 == lang.locale.languageCode,
            orElse: () => options.first)
        .$3;

    return ListTile(
      leading: const Icon(Icons.language),
      title: Text(l10n.languagePicker),
      subtitle: Text(currentLabel),
      onTap: () {
        showModalBottomSheet<void>(
          context: context,
          isScrollControlled: true,
          builder: (ctx) => SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                    child: Text(
                      l10n.languagePicker,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                  Flexible(
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          for (final (code, flag, label) in options)
                            ListTile(
                              leading: Text(flag,
                                  style: const TextStyle(fontSize: 24)),
                              title: Text(
                                label,
                                style: TextStyle(
                                  color: code == lang.locale.languageCode
                                      ? Theme.of(context).colorScheme.primary
                                      : null,
                                  fontWeight: code == lang.locale.languageCode
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                              trailing: code == lang.locale.languageCode
                                  ? Icon(Icons.check,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .primary,
                                      size: 18)
                                  : null,
                              onTap: () {
                                context
                                    .read<LanguageService>()
                                    .setLocale(Locale(code));
                                Navigator.pop(ctx);
                              },
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ClearCacheTile extends StatefulWidget {
  @override
  State<_ClearCacheTile> createState() => _ClearCacheTileState();
}

class _ClearCacheTileState extends State<_ClearCacheTile> {
  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context)!;
    final trans = context.read<TranslationService>();
    final count = trans.cachedTranslationCount;
    final sizeStr = _formatBytes(trans.cacheSizeBytes);

    return ListTile(
      leading: const Icon(Icons.delete_sweep_outlined),
      title: Text(l10n.clearCache),
      subtitle: Text('$count translations · $sizeStr'),
      onTap: () async {
        await trans.clearCache();
        if (context.mounted) {
          setState(() {});
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.cacheCleared)),
          );
        }
      },
    );
  }
}

class _DownloadsTile extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context)!;
    final downloads = context.watch<DownloadService>();
    final count = downloads.downloadedSongs.length;
    final size = _formatBytes(downloads.totalDownloadSizeBytes);

    return ListTile(
      leading: const Icon(Icons.download_done_outlined),
      title: Text(l10n.downloadsHeader),
      subtitle: Text('$count songs · $size'),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute<void>(builder: (_) => const DownloadsScreen()),
      ),
    );
  }
}

class _GitHubTile extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context)!;
    final update = context.watch<UpdateService>();

    return ListTile(
      leading: const Icon(Icons.new_releases_outlined),
      title: Text(l10n.githubReleases),
      subtitle: update.hasUpdate
          ? Text(
              l10n.updateAvailable,
              style:
                  TextStyle(color: Theme.of(context).colorScheme.primary),
            )
          : null,
      trailing: update.hasUpdate
          ? Icon(Icons.circle,
              color: Theme.of(context).colorScheme.primary, size: 10)
          : const Icon(Icons.open_in_new, size: 16),
      onTap: () => launchUrl(
        Uri.parse(AppConstants.githubReleasesUrl),
        mode: LaunchMode.externalApplication,
      ),
    );
  }
}
