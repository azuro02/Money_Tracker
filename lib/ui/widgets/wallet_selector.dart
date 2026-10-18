import 'package:flutter/material.dart';

import '../../core/app_icon.dart';
import '../scope.dart';
import 'common.dart';

/// App bar title that shows the current wallet and lets the user switch
/// between wallets or "all wallets".
class WalletSelector extends StatelessWidget {
  const WalletSelector({super.key});

  @override
  Widget build(BuildContext context) {
    final services = context.services;
    final current = services.settings.currentWallet;
    final wallet = current == null ? null : services.repo.wallet(current);
    if (current != null && wallet == null) {
      // The wallet was deleted.
      WidgetsBinding.instance.addPostFrameCallback(
          (_) => services.settings.currentWallet = null);
    }
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => _showSheet(context),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (wallet != null) ...[
              IconAvatar(wallet.icon, size: 28),
              const SizedBox(width: 10),
            ],
            Flexible(
              child: Text(
                wallet?.name ?? context.l10n.totalWallet,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Icon(Icons.arrow_drop_down),
          ],
        ),
      ),
    );
  }

  void _showSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) {
        final services = context.services;
        final repo = services.repo;
        final current = services.settings.currentWallet;
        final balances = repo.walletBalances();
        final totals = repo.totalBalances();
        return ConstrainedBox(
          constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(context).height * .75),
          child: ListView(
            shrinkWrap: true,
            children: [
              ListTile(
                leading: const IconAvatar(ColorIcon('#37474F', 'Σ')),
                title: Text(context.l10n.totalWallet),
                subtitle: Text(totals.entries
                    .map((e) => context.formatMoney(e.value, e.key))
                    .join('  ·  ')),
                selected: current == null,
                trailing: current == null ? const Icon(Icons.check) : null,
                onTap: () {
                  services.settings.currentWallet = null;
                  Navigator.pop(context);
                },
              ),
              const Divider(height: 1),
              for (final b in balances)
                ListTile(
                  leading: IconAvatar(b.wallet.icon),
                  title: Text(b.wallet.name),
                  subtitle: b.wallet.countInTotal
                      ? null
                      : Text(context.l10n.walletCountInTotal,
                          style: const TextStyle(
                              decoration: TextDecoration.lineThrough)),
                  selected: current == b.wallet.uuid,
                  trailing: MoneyText(b.balance, b.wallet.currency),
                  onTap: () {
                    services.settings.currentWallet = b.wallet.uuid;
                    Navigator.pop(context);
                  },
                ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }
}
