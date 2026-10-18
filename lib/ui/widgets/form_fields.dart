import 'package:flutter/material.dart';

import '../../core/app_icon.dart';
import '../../core/calculator.dart';
import '../../core/money.dart';
import '../scope.dart';
import 'common.dart';

/// Large amount input that also accepts simple calculations (12+3*2).
class AmountField extends StatefulWidget {
  const AmountField({
    super.key,
    required this.controller,
    required this.decimals,
    required this.currencySymbol,
    this.autofocus = false,
    this.label,
    this.color,
    this.allowZero = false,
    this.allowNegative = false,
  });

  final TextEditingController controller;
  final int decimals;
  final String currencySymbol;
  final bool autofocus;
  final String? label;
  final Color? color;
  final bool allowZero;
  final bool allowNegative;

  @override
  State<AmountField> createState() => _AmountFieldState();
}

class _AmountFieldState extends State<AmountField> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_changed);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_changed);
    super.dispose();
  }

  void _changed() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final text = widget.controller.text;
    final value = evaluateAmount(text, widget.decimals);
    final isExpression = RegExp(r'[+*/×÷()]').hasMatch(text) ||
        (text.length > 1 && text.substring(1).contains('-'));
    final theme = Theme.of(context);
    return TextFormField(
      controller: widget.controller,
      autofocus: widget.autofocus,
      keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
      style: theme.textTheme.headlineMedium?.copyWith(
        color: widget.color,
        fontWeight: FontWeight.w600,
      ),
      decoration: InputDecoration(
        labelText: widget.label ?? context.l10n.amount,
        suffixText: widget.currencySymbol,
        helperText: isExpression && value != null
            ? '= ${minorToPlainString(value, widget.decimals)}'
            : null,
      ),
      validator: (v) {
        final amount = evaluateAmount(v ?? '', widget.decimals);
        if (amount == null ||
            (amount < 0 && !widget.allowNegative) ||
            (amount == 0 && !widget.allowZero)) {
          return context.l10n.invalidAmount;
        }
        return null;
      },
    );
  }
}

/// A tappable row showing a selected value (used for pickers in forms).
class PickerTile extends StatelessWidget {
  const PickerTile({
    super.key,
    required this.icon,
    required this.label,
    this.value,
    this.leading,
    this.onTap,
    this.onClear,
    this.error,
  });

  final IconData icon;
  final String label;
  final String? value;
  final Widget? leading;
  final VoidCallback? onTap;
  final VoidCallback? onClear;
  final String? error;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: leading ??
          CircleAvatar(
            backgroundColor: theme.colorScheme.surfaceContainerHighest,
            child: Icon(icon, color: theme.colorScheme.onSurfaceVariant),
          ),
      title: Text(
        value ?? label,
        style: value == null
            ? TextStyle(color: error != null ? theme.colorScheme.error : theme.colorScheme.onSurfaceVariant)
            : null,
      ),
      subtitle: value == null
          ? (error == null ? null : Text(error!, style: TextStyle(color: theme.colorScheme.error)))
          : Text(label),
      trailing: value != null && onClear != null
          ? IconButton(icon: const Icon(Icons.close), onPressed: onClear)
          : null,
      onTap: onTap,
      enabled: onTap != null,
    );
  }
}

/// Icon + name header used by the simple entity editors.
class IconNameField extends StatelessWidget {
  const IconNameField({
    super.key,
    required this.icon,
    required this.controller,
    required this.onIconTap,
    required this.label,
  });

  final AppIcon icon;
  final TextEditingController controller;
  final VoidCallback onIconTap;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        InkWell(
          customBorder: const CircleBorder(),
          onTap: onIconTap,
          child: Stack(
            children: [
              IconAvatar(icon, size: 56),
              Positioned(
                right: 0,
                bottom: 0,
                child: CircleAvatar(
                  radius: 10,
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  child: Icon(Icons.edit, size: 12,
                      color: Theme.of(context).colorScheme.onPrimary),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: TextFormField(
            controller: controller,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(labelText: label),
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? context.l10n.required : null,
          ),
        ),
      ],
    );
  }
}
