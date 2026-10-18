import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:money_tracker/io/backup/winzip_aes.dart';
import 'package:money_tracker/io/backup/zip.dart';

Uint8List _fixture(String name) =>
    File('test/fixtures/$name').readAsBytesSync();

void main() {
  group('WinZip AES', () {
    test('round trip', () {
      final plain = Uint8List.fromList(utf8.encode('x' * 1000 + 'end'));
      final enc = WinZipAes.encrypt(plain, 'pässwört');
      expect(enc.length, 16 + 2 + plain.length + 10);
      expect(WinZipAes.decrypt(enc, 'pässwört'), plain);
    });

    test('wrong password is detected', () {
      final enc = WinZipAes.encrypt(Uint8List.fromList([1, 2, 3]), 'a');
      expect(() => WinZipAes.decrypt(enc, 'b'),
          throwsA(isA<WrongPasswordException>()));
    });

    test('tampered data fails authentication', () {
      final enc = WinZipAes.encrypt(Uint8List.fromList([1, 2, 3, 4]), 'a');
      enc[20] ^= 0xFF;
      expect(() => WinZipAes.decrypt(enc, 'a'), throwsFormatException);
    });
  });

  group('ZipReader/ZipWriter', () {
    final entries = [
      ZipEntry('databases/database.json',
          Uint8List.fromList(utf8.encode('{"header":{"version_code":2}}'))),
      ZipEntry('attachments/file-1', Uint8List.fromList(List.generate(3000, (i) => i % 7))),
    ];

    test('plain round trip', () {
      final zip = ZipReader(ZipWriter.encode(entries));
      expect(zip.isEncrypted, isFalse);
      expect(zip.names, ['databases/database.json', 'attachments/file-1']);
      expect(zip.read('attachments/file-1'), entries[1].data);
    });

    test('encrypted round trip', () {
      final zip = ZipReader(ZipWriter.encode(entries, password: 'secret'));
      expect(zip.isEncrypted, isTrue);
      expect(() => zip.read('databases/database.json'),
          throwsA(isA<PasswordRequiredException>()));
      expect(utf8.decode(zip.read('databases/database.json', password: 'secret')!),
          '{"header":{"version_code":2}}');
      expect(() => zip.read('attachments/file-1', password: 'wrong'),
          throwsA(isA<WrongPasswordException>()));
    });

    test('reads AES-256 archives created by 7-Zip (stored)', () {
      final zip = ZipReader(_fixture('aes256_7z.zip'));
      expect(utf8.decode(zip.read('databases/database.json', password: 'secret123')!),
          '{"header":{"version_code":2}}');
      expect(utf8.decode(zip.read('attachments/abc-file', password: 'secret123')!),
          'hello attachment');
    });

    test('reads AES-256 archives created by 7-Zip (deflate)', () {
      final zip = ZipReader(_fixture('aes256_deflate_7z.zip'));
      expect(utf8.decode(zip.read('databases/big.txt', password: 'secret123')!),
          'x' * 5000);
    });

    test('rejects legacy ZipCrypto encryption with a clear error', () {
      final zip = ZipReader(_fixture('zipcrypto_7z.zip'));
      expect(() => zip.read('databases/database.json', password: 'secret123'),
          throwsFormatException);
    });

    test('7-Zip can extract our encrypted archives', () async {
      final sevenZip = Process.runSync('which', ['7z']);
      if (sevenZip.exitCode != 0) {
        markTestSkipped('7z not installed');
        return;
      }
      final dir = Directory.systemTemp.createTempSync('mt_zip');
      try {
        final file = File('${dir.path}/backup.mwbs')
          ..writeAsBytesSync(ZipWriter.encode(entries, password: 'secret'));
        final result = Process.runSync(
            '7z', ['x', '-psecret', '-o${dir.path}/out', file.path]);
        expect(result.exitCode, 0, reason: '${result.stdout}${result.stderr}');
        expect(File('${dir.path}/out/attachments/file-1').readAsBytesSync(),
            entries[1].data);
      } finally {
        dir.deleteSync(recursive: true);
      }
    });
  });
}
