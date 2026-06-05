import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../screens/login_screen.dart';
import '../screens/settings_screen.dart';
import '../services/auth_service.dart';

class GlobalAppBarActions extends StatelessWidget {
  const GlobalAppBarActions({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final l10n = AppL10n.of(context)!;

    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert, size: 20),
      onSelected: (value) {
        if (value == 'settings') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const SettingsScreen()),
          );
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
          value: 'settings',
          child: Row(children: [
            const Icon(Icons.settings_outlined, size: 18),
            const SizedBox(width: 10),
            Text(l10n.navSettings),
          ]),
        ),
        PopupMenuItem(
          value: auth.isAuthenticated ? 'admin_logout' : 'admin_login',
          child: Row(children: [
            Icon(
              auth.isAuthenticated
                  ? Icons.logout
                  : Icons.admin_panel_settings_outlined,
              size: 18,
            ),
            const SizedBox(width: 10),
            Text(auth.isAuthenticated
                ? l10n.tooltipAdminLogout
                : l10n.tooltipAdminLogin),
          ]),
        ),
      ],
    );
  }
}
