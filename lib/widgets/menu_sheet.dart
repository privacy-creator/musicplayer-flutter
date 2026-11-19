import 'package:flutter/material.dart';

/// Opties-menu als bottom sheet, in dezelfde stijl als het nummer-menu en
/// het algemene menu elders in de app (greep bovenaan, optionele kop met
/// titel/ondertitel, daarna de items).
class MenuSheet extends StatelessWidget {
  final String? title;
  final String? subtitle;
  final IconData headerIcon;
  final List<Widget> children;

  const MenuSheet({
    super.key,
    this.title,
    this.subtitle,
    this.headerIcon = Icons.music_note,
    required this.children,
  });

  /// Toont een [MenuSheet] met transparante achtergrond (de afgeronde
  /// container tekent zelf de achtergrond, net als de andere menu's).
  static Future<T?> show<T>(
    BuildContext context, {
    String? title,
    String? subtitle,
    IconData headerIcon = Icons.music_note,
    required List<Widget> Function(BuildContext sheetCtx) items,
  }) =>
      showModalBottomSheet<T>(
        context: context,
        backgroundColor: Colors.transparent,
        isScrollControlled: true,
        builder: (sheetCtx) => MenuSheet(
          title: title,
          subtitle: subtitle,
          headerIcon: headerIcon,
          children: items(sheetCtx),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerHigh,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 4),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: cs.onSurfaceVariant.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            if (title != null) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        width: 54,
                        height: 54,
                        color: cs.surfaceContainerHighest,
                        child: Icon(headerIcon, color: cs.primary, size: 28),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title!,
                            style: TextStyle(
                              color: cs.onSurface,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (subtitle != null) ...[
                            const SizedBox(height: 3),
                            Text(
                              subtitle!,
                              style: TextStyle(
                                  color: cs.onSurfaceVariant, fontSize: 13),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Divider(height: 1, color: cs.outline.withValues(alpha: 0.2)),
            ] else
              const SizedBox(height: 8),
            ...children,
            SizedBox(height: MediaQuery.of(context).padding.bottom + 12),
          ],
        ),
      ),
    );
  }
}

class MenuSheetItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  const MenuSheetItem({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? Theme.of(context).colorScheme.onSurface;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Icon(icon, color: c, size: 22),
            const SizedBox(width: 18),
            Expanded(
              child: Text(label, style: TextStyle(color: c, fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}
