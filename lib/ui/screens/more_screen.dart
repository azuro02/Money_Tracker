import 'package:flutter/material.dart';

import '../scope.dart';
import 'backup_screen.dart';
import 'calendar_screen.dart';
import 'categories_screen.dart';
import 'debts_screen.dart';
import 'entities_screen.dart';
import 'recurrences_screen.dart';
import 'search_screen.dart';
import 'settings_screen.dart';
import 'wallets_screen.dart';

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    void open(Widget screen) =>
        Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
    Widget item(IconData icon, String title, Widget screen) => ListTile(
          leading: Icon(icon),
          title: Text(title),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => open(screen),
        );
    return Scaffold(
      appBar: AppBar(title: Text(l.navMore)),
      body: ListView(
        children: [
          item(Icons.account_balance_wallet_outlined, l.wallets, const WalletsScreen()),
          item(Icons.category_outlined, l.categories, const CategoriesScreen()),
          item(Icons.handshake_outlined, l.debts, const DebtsScreen()),
          item(Icons.repeat, l.recurrences, const RecurrencesScreen()),
          item(Icons.bookmarks_outlined, l.models, const ModelsScreen()),
          const Divider(),
          item(Icons.calendar_month_outlined, l.calendar, const CalendarScreen()),
          item(Icons.search, l.search, const SearchScreen()),
          item(Icons.celebration_outlined, l.events, const EventsScreen()),
          item(Icons.people_outline, l.people, const PeopleScreen()),
          item(Icons.place_outlined, l.places, const PlacesScreen()),
          const Divider(),
          item(Icons.save_alt, l.backupAndExport, const BackupScreen()),
          item(Icons.settings_outlined, l.settings, const SettingsScreen()),
          item(Icons.info_outline, l.about, const AboutScreen()),
        ],
      ),
    );
  }
}
