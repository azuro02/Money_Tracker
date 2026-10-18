import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/settings.dart';
import '../scope.dart';

const _pinLength = 4;
const _maxPinLength = 8;

/// Numeric keypad with PIN dots.
class _PinPad extends StatelessWidget {
  const _PinPad({
    required this.title,
    required this.value,
    required this.onDigit,
    required this.onBackspace,
    required this.onSubmit,
    this.error,
    this.extra,
  });

  final String title;
  final String value;
  final ValueChanged<String> onDigit;
  final VoidCallback onBackspace;
  final VoidCallback onSubmit;
  final String? error;
  final Widget? extra;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    Widget key(String label, {VoidCallback? onTap, Widget? child}) => SizedBox(
          width: 76,
          height: 76,
          child: TextButton(
            style: TextButton.styleFrom(shape: const CircleBorder()),
            onPressed: onTap ??
                () {
                  HapticFeedback.selectionClick();
                  onDigit(label);
                },
            child: child ?? Text(label, style: theme.textTheme.headlineMedium),
          ),
        );
    return SafeArea(
      child: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.lock_outline, size: 40, color: theme.colorScheme.primary),
              const SizedBox(height: 16),
              Text(title, style: theme.textTheme.titleLarge),
              const SizedBox(height: 20),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (var i = 0; i < (value.length < _pinLength ? _pinLength : value.length); i++)
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 6),
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: i < value.length
                            ? theme.colorScheme.primary
                            : theme.colorScheme.outlineVariant,
                      ),
                    ),
                ],
              ),
              SizedBox(
                height: 32,
                child: Center(
                  child: Text(error ?? '',
                      style: TextStyle(color: theme.colorScheme.error)),
                ),
              ),
              for (final row in const [
                ['1', '2', '3'],
                ['4', '5', '6'],
                ['7', '8', '9'],
              ])
                Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [for (final k in row) key(k)]),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  key('⌫',
                      onTap: value.isEmpty ? null : onBackspace,
                      child: const Icon(Icons.backspace_outlined)),
                  key('0'),
                  key('✓',
                      onTap: value.length >= _pinLength ? onSubmit : null,
                      child: const Icon(Icons.check_circle, size: 36)),
                ],
              ),
              if (extra != null) ...[const SizedBox(height: 16), extra!],
            ],
          ),
        ),
      ),
    );
  }
}

class LockScreen extends StatefulWidget {
  const LockScreen({super.key, required this.onUnlocked});

  final VoidCallback onUnlocked;

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  String _pin = '';
  String? _error;
  bool _biometric = false;
  int _failures = 0;

  // Digits are appended to the current state (not to the value of the last
  // build) so fast typing never loses input.
  void _digit(String d) => setState(() {
        if (_pin.length < _maxPinLength) _pin += d;
        _error = null;
      });

  void _backspace() => setState(() {
        if (_pin.isNotEmpty) _pin = _pin.substring(0, _pin.length - 1);
      });

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final services = context.read;
      if (services.settings.lockMode == LockMode.pinBiometric &&
          await services.security.canUseBiometrics()) {
        if (!mounted) return;
        setState(() => _biometric = true);
        _tryBiometric();
      }
    });
  }

  Future<void> _tryBiometric() async {
    final ok = await context.read.security
        .authenticateBiometric(context.l10n.lockReason);
    if (ok && mounted) widget.onUnlocked();
  }

  Future<void> _submit() async {
    final ok = await context.read.security.verifyPin(_pin);
    if (!mounted) return;
    if (ok) {
      widget.onUnlocked();
    } else {
      _failures++;
      HapticFeedback.heavyImpact();
      setState(() {
        _pin = '';
        _error = context.l10n.lockWrongPin;
      });
      // Slow down brute force attempts.
      if (_failures >= 5) {
        await Future<void>.delayed(Duration(seconds: _failures * 2));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _PinPad(
        title: context.l10n.lockTitle,
        value: _pin,
        error: _error,
        onDigit: _digit,
        onBackspace: _backspace,
        onSubmit: _submit,
        extra: _biometric
            ? TextButton.icon(
                onPressed: _tryBiometric,
                icon: const Icon(Icons.fingerprint),
                label: Text(context.l10n.lockUseBiometrics),
              )
            : null,
      ),
    );
  }
}

/// Asks for a new PIN twice. Pops with true when the PIN was stored.
class PinSetupScreen extends StatefulWidget {
  const PinSetupScreen({super.key});

  @override
  State<PinSetupScreen> createState() => _PinSetupScreenState();
}

class _PinSetupScreenState extends State<PinSetupScreen> {
  String _pin = '';
  String? _first;
  String? _error;

  // Digits are appended to the current state (not to the value of the last
  // build) so fast typing never loses input.
  void _digit(String d) => setState(() {
        if (_pin.length < _maxPinLength) _pin += d;
        _error = null;
      });

  void _backspace() => setState(() {
        if (_pin.isNotEmpty) _pin = _pin.substring(0, _pin.length - 1);
      });

  Future<void> _submit() async {
    if (_first == null) {
      setState(() {
        _first = _pin;
        _pin = '';
      });
      return;
    }
    if (_first != _pin) {
      setState(() {
        _first = null;
        _pin = '';
        _error = context.l10n.lockPinMismatch;
      });
      return;
    }
    await context.read.security.setPin(_pin);
    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Scaffold(
      appBar: AppBar(),
      body: _PinPad(
        title: _first == null ? l.lockSetPin : l.lockConfirmPin,
        value: _pin,
        error: _error,
        onDigit: _digit,
        onBackspace: _backspace,
        onSubmit: _submit,
      ),
    );
  }
}
