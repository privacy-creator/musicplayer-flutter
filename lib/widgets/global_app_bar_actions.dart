import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../screens/login_screen.dart';
import '../screens/settings_screen.dart';
import '../services/auth_service.dart';

class AppBarMenuItem {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? iconColor;

  const AppBarMenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.iconColor,
  });
}

class GlobalAppBarActions extends StatelessWidget {
  final List<AppBarMenuItem> extraItems;

  const GlobalAppBarActions({super.key, this.extraItems = const []});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final l10n = AppL10n.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    return IconButton(
      icon: const Icon(Icons.more_vert),
      iconSize: 28,
      onPressed: () => showModalBottomSheet<void>(
        context: context,
        backgroundColor: Colors.transparent,
        builder: (sheetCtx) => _GlobalMenuSheet(
          auth: auth,
          l10n: l10n,
          colorScheme: colorScheme,
          extraItems: extraItems,
          onSettings: () {
            Navigator.pop(sheetCtx);
            Navigator.push(context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()));
          },
          onAuth: () {
            Navigator.pop(sheetCtx);
            if (auth.isAuthenticated) {
              context.read<AuthService>().logout();
            } else {
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()));
            }
          },
        ),
      ),
    );
  }
}

class _GlobalMenuSheet extends StatelessWidget {
  final AuthService auth;
  final AppL10n l10n;
  final ColorScheme colorScheme;
  final List<AppBarMenuItem> extraItems;
  final VoidCallback onSettings;
  final VoidCallback onAuth;

  const _GlobalMenuSheet({
    required this.auth,
    required this.l10n,
    required this.colorScheme,
    required this.extraItems,
    required this.onSettings,
    required this.onAuth,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHigh,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 4),
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 8),
          for (final item in extraItems)
            _GlobalSheetItem(
              icon: item.icon,
              label: item.label,
              colorScheme: colorScheme,
              iconColor: item.iconColor,
              onTap: item.onTap,
            ),
          if (extraItems.isNotEmpty)
            Divider(
                height: 1,
                color: colorScheme.outline.withValues(alpha: 0.2)),
          _GlobalSheetItem(
            icon: Icons.settings_outlined,
            label: l10n.navSettings,
            colorScheme: colorScheme,
            onTap: onSettings,
          ),
          _GlobalSheetItem(
            icon: auth.isAuthenticated
                ? Icons.logout
                : Icons.admin_panel_settings_outlined,
            label: auth.isAuthenticated
                ? l10n.tooltipAdminLogout
                : l10n.tooltipAdminLogin,
            colorScheme: colorScheme,
            onTap: onAuth,
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom + 12),
        ],
      ),
    );
  }
}

class _GlobalSheetItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final ColorScheme colorScheme;
  final VoidCallback onTap;
  final Color? iconColor;

  const _GlobalSheetItem({
    required this.icon,
    required this.label,
    required this.colorScheme,
    required this.onTap,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Icon(icon, color: iconColor ?? colorScheme.onSurface, size: 22),
            const SizedBox(width: 18),
            Text(
              label,
              style: TextStyle(color: colorScheme.onSurface, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
