import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../app/services.dart';
import '../app/settings.dart';
import '../l10n/app_localizations.dart';
import 'scope.dart';
import 'screens/home_shell.dart';
import 'screens/lock_screen.dart';
import 'screens/onboarding_screen.dart';

ThemeData buildTheme(Color seed, Brightness brightness) {
  final scheme = ColorScheme.fromSeed(seedColor: seed, brightness: brightness);
  return ThemeData(
    colorScheme: scheme,
    useMaterial3: true,
    cardTheme: CardThemeData(
      elevation: 0,
      color: scheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      filled: true,
      fillColor: scheme.surfaceContainerHighest.withValues(alpha: .4),
    ),
    listTileTheme: const ListTileThemeData(
      contentPadding: EdgeInsets.symmetric(horizontal: 16),
    ),
    appBarTheme: const AppBarTheme(centerTitle: false),
  );
}

class MoneyTrackerApp extends StatelessWidget {
  const MoneyTrackerApp({super.key, required this.services, this.locale});

  final AppServices services;

  /// Forces a locale (used by tests).
  final Locale? locale;

  @override
  Widget build(BuildContext context) {
    return AppScope(
      services: services,
      child: ListenableBuilder(
        listenable: services.settings,
        builder: (context, _) {
          final settings = services.settings;
          return MaterialApp(
            onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
            debugShowCheckedModeBanner: false,
            locale: locale,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            themeMode: settings.themeMode,
            theme: buildTheme(settings.seedColor, Brightness.light),
            darkTheme: buildTheme(settings.seedColor, Brightness.dark),
            home: const RootGate(),
          );
        },
      ),
    );
  }
}

/// Decides between lock screen, onboarding and the main UI and reacts to
/// app lifecycle changes (re-locking, recurrences, auto backup).
class RootGate extends StatefulWidget {
  const RootGate({super.key});

  @override
  State<RootGate> createState() => _RootGateState();
}

class _RootGateState extends State<RootGate> with WidgetsBindingObserver {
  bool _locked = true;
  bool _obscured = false;
  DateTime? _pausedAt;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final services = context.read;
      if (services.settings.lockMode == LockMode.none) {
        setState(() => _locked = false);
      }
      services.onResume();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final services = context.read;
    switch (state) {
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
        // Hide the content in the app switcher when a lock is configured.
        if (services.settings.lockMode != LockMode.none) {
          setState(() => _obscured = true);
        }
      case AppLifecycleState.paused:
        _pausedAt ??= DateTime.now();
      case AppLifecycleState.resumed:
        final paused = _pausedAt;
        _pausedAt = null;
        final timeout = services.settings.lockTimeout;
        setState(() {
          _obscured = false;
          if (services.settings.lockMode != LockMode.none &&
              paused != null &&
              DateTime.now().difference(paused).inSeconds >= timeout) {
            _locked = true;
          }
        });
        if (paused != null) services.onResume();
      case AppLifecycleState.detached:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final services = context.services;
    final Widget content;
    if (_locked && services.settings.lockMode != LockMode.none) {
      content = LockScreen(onUnlocked: () => setState(() => _locked = false));
    } else if (services.repo.isEmpty) {
      content = const OnboardingScreen();
    } else {
      content = const HomeShell();
    }
    return Stack(
      children: [
        content,
        if (_obscured)
          Positioned.fill(
            child: ColoredBox(
              color: Theme.of(context).colorScheme.surface,
              child: Center(
                child: Icon(Icons.lock,
                    size: 48, color: Theme.of(context).colorScheme.primary),
              ),
            ),
          ),
      ],
    );
  }
}
