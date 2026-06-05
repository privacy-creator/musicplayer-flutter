import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../services/language_service.dart';
import '../services/theme_service.dart';
import '../services/translation_service.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context)!;
    final theme = Theme.of(context);

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
          const SizedBox(height: 32),
          Center(
            child: Text(
              'alfa 0.6.0',
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
                              color: Theme.of(context).colorScheme.primary,
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
        );
      },
    );
  }
}

class _ClearCacheTile extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context)!;

    return ListTile(
      leading: const Icon(Icons.delete_sweep_outlined),
      title: Text(l10n.clearCache),
      subtitle: const Text('Translation cache'),
      onTap: () async {
        await context.read<TranslationService>().clearCache();
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.cacheCleared)),
          );
        }
      },
    );
  }
}
