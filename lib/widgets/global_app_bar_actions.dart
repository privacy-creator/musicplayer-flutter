import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../screens/login_screen.dart';
import '../services/auth_service.dart';
import '../services/language_service.dart';

class GlobalAppBarActions extends StatelessWidget {
  const GlobalAppBarActions({super.key});

  void _showLanguagePicker(BuildContext context) {
    final lang = context.read<LanguageService>();
    final l10n = AppL10n.of(context)!;
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => SafeArea(
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
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              _LangOption(
                flag: '🇳🇱',
                label: 'Nederlands',
                code: 'nl',
                current: lang.locale.languageCode,
                onTap: () {
                  lang.setLocale(const Locale('nl'));
                  Navigator.pop(context);
                },
              ),
              _LangOption(
                flag: '🇬🇧',
                label: 'English',
                code: 'en',
                current: lang.locale.languageCode,
                onTap: () {
                  lang.setLocale(const Locale('en'));
                  Navigator.pop(context);
                },
              ),
              _LangOption(
                flag: '🇪🇸',
                label: 'Español',
                code: 'es',
                current: lang.locale.languageCode,
                onTap: () {
                  lang.setLocale(const Locale('es'));
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final l10n = AppL10n.of(context)!;

    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert, color: Color(0xFFB3B3B3), size: 20),
      color: const Color(0xFF1E1E1E),
      onSelected: (value) {
        if (value == 'language') {
          _showLanguagePicker(context);
        } else if (value == 'admin_logout') {
          context.read<AuthService>().logout();
        } else if (value == 'admin_login') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const LoginScreen()),
          );
        }
      },
      itemBuilder: (_) => [
        PopupMenuItem(
          value: 'language',
          child: Row(children: [
            const Icon(Icons.language, color: Color(0xFFB3B3B3), size: 18),
            const SizedBox(width: 10),
            Text(l10n.languagePicker,
                style: const TextStyle(color: Colors.white)),
          ]),
        ),
        PopupMenuItem(
          value: auth.isAuthenticated ? 'admin_logout' : 'admin_login',
          child: Row(children: [
            Icon(
              auth.isAuthenticated
                  ? Icons.logout
                  : Icons.admin_panel_settings_outlined,
              color: const Color(0xFFB3B3B3),
              size: 18,
            ),
            const SizedBox(width: 10),
            Text(
              auth.isAuthenticated
                  ? l10n.tooltipAdminLogout
                  : l10n.tooltipAdminLogin,
              style: const TextStyle(color: Colors.white),
            ),
          ]),
        ),
      ],
    );
  }
}

class _LangOption extends StatelessWidget {
  final String flag;
  final String label;
  final String code;
  final String current;
  final VoidCallback onTap;

  const _LangOption({
    required this.flag,
    required this.label,
    required this.code,
    required this.current,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = code == current;
    return ListTile(
      leading: Text(flag, style: const TextStyle(fontSize: 24)),
      title: Text(
        label,
        style: TextStyle(
          color: isActive ? const Color(0xFF1DB954) : Colors.white,
          fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      trailing: isActive
          ? const Icon(Icons.check, color: Color(0xFF1DB954), size: 18)
          : null,
      onTap: onTap,
    );
  }
}
