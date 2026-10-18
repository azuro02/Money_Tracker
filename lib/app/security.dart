import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'package:pointycastle/export.dart';

/// Key/value store for secrets (Keychain / Android Keystore backed).
abstract class SecretStore {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
  Future<void> delete(String key);
}

class SecureSecretStore implements SecretStore {
  const SecureSecretStore();

  static const _storage = FlutterSecureStorage();

  @override
  Future<String?> read(String key) => _storage.read(key: key);

  @override
  Future<void> write(String key, String value) =>
      _storage.write(key: key, value: value);

  @override
  Future<void> delete(String key) => _storage.delete(key: key);
}

class MemorySecretStore implements SecretStore {
  final Map<String, String> values = {};

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> write(String key, String value) async => values[key] = value;

  @override
  Future<void> delete(String key) async => values.remove(key);
}

/// PIN handling and biometric unlock. The PIN is never stored in plain text
/// but as salted PBKDF2-HMAC-SHA256 hash.
class SecurityService {
  SecurityService(this.store, {LocalAuthentication? auth})
      : _auth = auth ?? LocalAuthentication();

  final SecretStore store;
  final LocalAuthentication _auth;

  static const _pinKey = 'pin_hash';
  static const _backupPasswordKey = 'auto_backup_password';
  static const _iterations = 20000;

  static String hashPin(String pin, Uint8List salt, {int iterations = _iterations}) {
    final derivator = PBKDF2KeyDerivator(HMac(SHA256Digest(), 64))
      ..init(Pbkdf2Parameters(salt, iterations, 32));
    return base64Encode(derivator.process(Uint8List.fromList(utf8.encode(pin))));
  }

  Future<void> setPin(String pin) async {
    final random = Random.secure();
    final salt = Uint8List.fromList(List.generate(16, (_) => random.nextInt(256)));
    await store.write(
        _pinKey, '$_iterations:${base64Encode(salt)}:${hashPin(pin, salt)}');
  }

  Future<bool> hasPin() async => (await store.read(_pinKey)) != null;

  Future<bool> verifyPin(String pin) async {
    final stored = await store.read(_pinKey);
    if (stored == null) return false;
    final parts = stored.split(':');
    if (parts.length != 3) return false;
    final hash = hashPin(pin, base64Decode(parts[1]),
        iterations: int.tryParse(parts[0]) ?? _iterations);
    // Constant time comparison.
    if (hash.length != parts[2].length) return false;
    var diff = 0;
    for (var i = 0; i < hash.length; i++) {
      diff |= hash.codeUnitAt(i) ^ parts[2].codeUnitAt(i);
    }
    return diff == 0;
  }

  Future<void> clearPin() => store.delete(_pinKey);

  Future<bool> canUseBiometrics() async {
    try {
      return await _auth.canCheckBiometrics && await _auth.isDeviceSupported();
    } catch (_) {
      return false;
    }
  }

  Future<bool> authenticateBiometric(String reason) async {
    try {
      return await _auth.authenticate(
          localizedReason: reason, biometricOnly: true);
    } catch (_) {
      return false;
    }
  }

  Future<String?> autoBackupPassword() => store.read(_backupPasswordKey);

  Future<void> setAutoBackupPassword(String? password) =>
      password == null || password.isEmpty
          ? store.delete(_backupPasswordKey)
          : store.write(_backupPasswordKey, password);
}
