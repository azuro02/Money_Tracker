// Guards the privacy promise: no network access, no tracking libraries.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('release manifest removes the INTERNET permission', () {
    final manifest =
        File('android/app/src/main/AndroidManifest.xml').readAsStringSync();
    expect(
      manifest,
      contains('<uses-permission android:name="android.permission.INTERNET" '
          'tools:node="remove" />'),
    );
    expect(manifest, contains('android:allowBackup="false"'));
  });

  test('no analytics, ads, crash reporting or network packages', () {
    final lock = File('pubspec.lock').readAsStringSync();
    const forbidden = [
      'firebase',
      'google_mobile_ads',
      'sentry',
      'crashlytics',
      'amplitude',
      'mixpanel',
      'appsflyer',
      'onesignal',
      'google_fonts',
      'cached_network_image',
      'dio',
      'google_sign_in',
      'facebook',
    ];
    for (final name in forbidden) {
      expect(RegExp('^  $name', multiLine: true).hasMatch(lock), isFalse,
          reason: '$name must not be a dependency');
    }
  });

  test('app code does not open network connections', () {
    final offenders = <String>[];
    for (final file in Directory('lib').listSync(recursive: true).whereType<File>()) {
      if (!file.path.endsWith('.dart')) continue;
      final source = file.readAsStringSync();
      if (RegExp(r'HttpClient|package:http/|Socket\.connect|WebSocket')
          .hasMatch(source)) {
        offenders.add(file.path);
      }
    }
    expect(offenders, isEmpty);
  });
}
