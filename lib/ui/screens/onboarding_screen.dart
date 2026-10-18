import 'package:flutter/material.dart';

import '../scope.dart';
import 'backup_screen.dart';
import 'wallets_screen.dart';

/// Shown while no wallet exists.
class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    width: 96,
                    height: 96,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(28),
                    ),
                    child: Icon(Icons.account_balance_wallet_rounded,
                        size: 52, color: theme.colorScheme.onPrimaryContainer),
                  ),
                  const SizedBox(height: 32),
                  Text(l.welcomeTitle,
                      style: theme.textTheme.headlineSmall,
                      textAlign: TextAlign.center),
                  const SizedBox(height: 12),
                  Text(l.welcomeText,
                      style: theme.textTheme.bodyLarge?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant),
                      textAlign: TextAlign.center),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.wifi_off,
                          size: 16, color: theme.colorScheme.primary),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(l.privacy,
                            style: theme.textTheme.labelLarge
                                ?.copyWith(color: theme.colorScheme.primary)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),
                  FilledButton.icon(
                    icon: const Icon(Icons.add),
                    label: Text(l.welcomeCreateWallet),
                    style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(52)),
                    // Default categories are created by the home screen.
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const WalletEditor(),
                          fullscreenDialog: true),
                    ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.restore),
                    label: Text(l.welcomeRestore),
                    style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(52)),
                    onPressed: () => restoreBackupFlow(context),
                  ),
                  const SizedBox(height: 8),
                  Text(l.welcomeRestoreHint,
                      style: theme.textTheme.bodySmall,
                      textAlign: TextAlign.center),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
