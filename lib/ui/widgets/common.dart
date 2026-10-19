import 'package:flutter/material.dart';

import '../../core/app_icon.dart';
import '../icons.dart';
import '../scope.dart';

/// Round avatar for an [AppIcon] (color + initials or a symbol).
class IconAvatar extends StatelessWidget {
  const IconAvatar(this.icon, {super.key, this.size = 40});

  final AppIcon icon;
  final double size;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    switch (icon) {
      case ColorIcon(:final argb, :final name):
        final color = Color(argb);
        final onColor = _onColor(color);
        return _circle(
          color,
          Text(
            name,
            maxLines: 1,
            style: TextStyle(
              color: onColor,
              fontWeight: FontWeight.w600,
              fontSize: size * (name.length > 2 ? .3 : .38),
            ),
          ),
        );
      case ResourceIcon(:final resource, :final argb):
        final data = iconForResource(resource);
        if (argb != null) {
          final color = Color(argb);
          return _circle(color,
              Icon(data ?? Icons.category, size: size * .55, color: _onColor(color)));
        }
        if (data == null) {
          return _circle(scheme.tertiaryContainer,
              Icon(Icons.category, size: size * .55, color: scheme.onTertiaryContainer));
        }
        return _circle(scheme.secondaryContainer,
            Icon(data, size: size * .55, color: scheme.onSecondaryContainer));
    }
  }

  static Color _onColor(Color color) =>
      ThemeData.estimateBrightnessForColor(color) == Brightness.dark
          ? Colors.white
          : Colors.black87;

  Widget _circle(Color color, Widget child) => Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        child: child,
      );
}

/// Colored, formatted amount.
class MoneyText extends StatelessWidget {
  const MoneyText(
    this.minor,
    this.currency, {
    super.key,
    this.style,
    this.colored = true,
    this.signed = false,
    this.muted = false,
  });

  final int minor;
  final String currency;
  final TextStyle? style;
  final bool colored;
  final bool signed;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final settings = context.settings;
    Color? color;
    if (colored && minor != 0) {
      color = minor > 0 ? settings.incomeColor : settings.expenseColor;
      if (Theme.of(context).brightness == Brightness.dark) {
        color = Color.lerp(color, Colors.white, .35);
      }
    }
    if (muted) color = color?.withValues(alpha: .6);
    return Text(
      context.formatMoney(minor, currency, forceSign: signed),
      style: (style ?? const TextStyle()).copyWith(
        color: color,
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.action,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: theme.colorScheme.outline),
            const SizedBox(height: 12),
            Text(title,
                style: theme.textTheme.titleMedium, textAlign: TextAlign.center),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(subtitle!,
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  textAlign: TextAlign.center),
            ],
            if (action != null) ...[const SizedBox(height: 16), action!],
          ],
        ),
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  const SectionHeader(this.text, {super.key, this.trailing});

  final String text;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Row(
        children: [
          Expanded(
            child: Text(text,
                style: theme.textTheme.titleSmall
                    ?.copyWith(color: theme.colorScheme.primary)),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

/// Card with title used on dashboard and statistics.
class InfoCard extends StatelessWidget {
  const InfoCard({super.key, this.title, required this.child, this.trailing, this.padding});

  final String? title;
  final Widget child;
  final Widget? trailing;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Padding(
        padding: padding ?? const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (title != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Expanded(
                        child: Text(title!, style: theme.textTheme.titleMedium)),
                    ?trailing,
                  ],
                ),
              ),
            child,
          ],
        ),
      ),
    );
  }
}

Future<bool> confirmDelete(BuildContext context, String name) async {
  final l = context.l10n;
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(l.confirmDeleteTitle),
      content: Text(l.confirmDeleteMessage(name)),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l.actionCancel)),
        FilledButton.tonal(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l.actionDelete)),
      ],
    ),
  );
  return result ?? false;
}

Future<bool> confirm(BuildContext context, String message) async {
  final l = context.l10n;
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      content: Text(message),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l.actionCancel)),
        FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l.actionOk)),
      ],
    ),
  );
  return result ?? false;
}

/// Runs [action] and shows repository errors as snack bar. Returns true on
/// success.
bool guarded(BuildContext context, void Function() action) {
  try {
    action();
    return true;
  } catch (e) {
    context.showError(e);
    return false;
  }
}
