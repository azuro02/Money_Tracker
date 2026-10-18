import 'dart:math';
import 'dart:typed_data';

import 'package:pointycastle/export.dart';

/// WinZip AES (AE-1/AE-2) entry encryption as used by zip4j, which the
/// original MoneyWallet app uses for password protected `.mwbs` backups.
///
///  * key derivation: PBKDF2-HMAC-SHA1, 1000 iterations
///  * salt: 8/12/16 bytes for AES-128/192/256
///  * 2 byte password verifier
///  * AES in CTR mode with a little-endian counter starting at 1
///  * authentication: first 10 bytes of HMAC-SHA1 over the cipher text
///
/// Layout of the entry data: salt | verifier | cipher text | mac.
class WinZipAes {
  WinZipAes._();

  static const int iterations = 1000;
  static const int macLength = 10;
  static const int verifierLength = 2;

  /// zip4j 1.x converts every password char to a single byte by truncation
  /// (`(byte) c`); we do the same so passwords behave identically.
  static Uint8List passwordBytes(String password) =>
      Uint8List.fromList(password.codeUnits.map((c) => c & 0xFF).toList());

  static int keyLengthForStrength(int strength) => switch (strength) {
        1 => 16,
        2 => 24,
        3 => 32,
        _ => throw FormatException('Invalid AES strength: $strength'),
      };

  static int saltLengthForStrength(int strength) => keyLengthForStrength(strength) ~/ 2;

  static _Keys _derive(String password, Uint8List salt, int keyLength) {
    final derivator = PBKDF2KeyDerivator(HMac(SHA1Digest(), 64))
      ..init(Pbkdf2Parameters(salt, iterations, keyLength * 2 + 2));
    final out = derivator.process(passwordBytes(password));
    return _Keys(
      Uint8List.sublistView(out, 0, keyLength),
      Uint8List.sublistView(out, keyLength, keyLength * 2),
      Uint8List.sublistView(out, keyLength * 2, keyLength * 2 + 2),
    );
  }

  static void _ctr(Uint8List key, Uint8List data) {
    final aes = AESEngine()..init(true, KeyParameter(key));
    final counter = Uint8List(16);
    final stream = Uint8List(16);
    var nonce = 1;
    for (var offset = 0; offset < data.length; offset += 16) {
      // Little-endian counter in the first 8 bytes (rest stays zero).
      var n = nonce;
      for (var i = 0; i < 8; i++) {
        counter[i] = n & 0xFF;
        n >>= 8;
      }
      aes.processBlock(counter, 0, stream, 0);
      final end = min(offset + 16, data.length);
      for (var i = offset; i < end; i++) {
        data[i] ^= stream[i - offset];
      }
      nonce++;
    }
  }

  static Uint8List _mac(Uint8List key, Uint8List data) {
    final hmac = HMac(SHA1Digest(), 64)..init(KeyParameter(key));
    final out = Uint8List(hmac.macSize);
    hmac
      ..update(data, 0, data.length)
      ..doFinal(out, 0);
    return Uint8List.sublistView(out, 0, macLength);
  }

  /// Encrypts [plain] (already compressed) with AES-256 (strength 3).
  static Uint8List encrypt(Uint8List plain, String password,
      {int strength = 3, Random? random}) {
    final keyLength = keyLengthForStrength(strength);
    final rnd = random ?? Random.secure();
    final salt = Uint8List.fromList(
        List.generate(saltLengthForStrength(strength), (_) => rnd.nextInt(256)));
    final keys = _derive(password, salt, keyLength);
    final cipher = Uint8List.fromList(plain);
    _ctr(keys.encryption, cipher);
    final mac = _mac(keys.authentication, cipher);
    return Uint8List.fromList(
        [...salt, ...keys.verifier, ...cipher, ...mac]);
  }

  /// Decrypts entry data. Throws [WrongPasswordException] when the password
  /// verifier does not match and [FormatException] when the data is corrupt.
  static Uint8List decrypt(Uint8List data, String password,
      {int strength = 3}) {
    final keyLength = keyLengthForStrength(strength);
    final saltLength = saltLengthForStrength(strength);
    if (data.length < saltLength + verifierLength + macLength) {
      throw const FormatException('Encrypted entry too short');
    }
    final salt = Uint8List.sublistView(data, 0, saltLength);
    final verifier =
        Uint8List.sublistView(data, saltLength, saltLength + verifierLength);
    final keys = _derive(password, salt, keyLength);
    if (keys.verifier[0] != verifier[0] || keys.verifier[1] != verifier[1]) {
      throw WrongPasswordException();
    }
    final cipher = Uint8List.fromList(Uint8List.sublistView(
        data, saltLength + verifierLength, data.length - macLength));
    final mac = Uint8List.sublistView(data, data.length - macLength);
    final expected = _mac(keys.authentication, cipher);
    for (var i = 0; i < macLength; i++) {
      if (mac[i] != expected[i]) {
        throw const FormatException('Authentication code mismatch');
      }
    }
    _ctr(keys.encryption, cipher);
    return cipher;
  }
}

class WrongPasswordException implements Exception {
  @override
  String toString() => 'WrongPasswordException';
}

class _Keys {
  _Keys(this.encryption, this.authentication, this.verifier);

  final Uint8List encryption;
  final Uint8List authentication;
  final Uint8List verifier;
}
