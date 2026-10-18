import 'dart:convert';
import 'dart:io' show ZLibCodec;
import 'dart:typed_data';

import 'package:archive/archive.dart' show getCrc32;

import 'winzip_aes.dart';

/// Minimal ZIP reader/writer supporting stored and deflated entries and
/// WinZip AES encryption (method 99), which is what zip4j produces for the
/// original MoneyWallet backups. ZIP64 is not needed for this use case.
class ZipEntry {
  ZipEntry(this.name, this.data);

  final String name;
  final Uint8List data;
}

class PasswordRequiredException implements Exception {
  @override
  String toString() => 'PasswordRequiredException';
}

const _localHeaderSig = 0x04034b50;
const _centralHeaderSig = 0x02014b50;
const _endOfCentralDirSig = 0x06054b50;
const _aesExtraId = 0x9901;
const _methodStored = 0;
const _methodDeflate = 8;
const _methodAes = 99;

final _rawZlib = ZLibCodec(raw: true, level: 6);

class ZipWriter {
  /// Builds an archive. When [password] is given every entry is encrypted
  /// with WinZip AES-256 (AE-2) like zip4j does.
  static Uint8List encode(List<ZipEntry> entries, {String? password}) {
    final out = BytesBuilder(copy: false);
    final central = BytesBuilder(copy: false);
    final (dosTime, dosDate) = _dosDateTime(DateTime.now());
    for (final entry in entries) {
      final nameBytes = utf8.encode(entry.name);
      final crc = getCrc32(entry.data);
      var payload = Uint8List.fromList(_rawZlib.encode(entry.data));
      var method = _methodDeflate;
      var flags = 0x0800; // UTF-8 names
      var storedCrc = crc;
      var extra = Uint8List(0);
      var version = 20;
      if (password != null) {
        payload = WinZipAes.encrypt(payload, password);
        method = _methodAes;
        flags |= 0x0001;
        storedCrc = 0; // AE-2 does not store the CRC
        version = 51;
        extra = (BytesData()
              ..u16(_aesExtraId)
              ..u16(7)
              ..u16(2) // AE-2
              ..bytes(ascii.encode('AE'))
              ..u8(3) // AES-256
              ..u16(_methodDeflate))
            .toBytes();
      }
      final offset = out.length;
      out.add((BytesData()
            ..u32(_localHeaderSig)
            ..u16(version)
            ..u16(flags)
            ..u16(method)
            ..u16(dosTime)
            ..u16(dosDate)
            ..u32(storedCrc)
            ..u32(payload.length)
            ..u32(entry.data.length)
            ..u16(nameBytes.length)
            ..u16(extra.length)
            ..bytes(nameBytes)
            ..bytes(extra))
          .toBytes());
      out.add(payload);
      central.add((BytesData()
            ..u32(_centralHeaderSig)
            ..u16(version)
            ..u16(version)
            ..u16(flags)
            ..u16(method)
            ..u16(dosTime)
            ..u16(dosDate)
            ..u32(storedCrc)
            ..u32(payload.length)
            ..u32(entry.data.length)
            ..u16(nameBytes.length)
            ..u16(extra.length)
            ..u16(0) // comment
            ..u16(0) // disk
            ..u16(0) // internal attrs
            ..u32(0) // external attrs
            ..u32(offset)
            ..bytes(nameBytes)
            ..bytes(extra))
          .toBytes());
    }
    final centralOffset = out.length;
    final centralBytes = central.toBytes();
    out.add(centralBytes);
    out.add((BytesData()
          ..u32(_endOfCentralDirSig)
          ..u16(0)
          ..u16(0)
          ..u16(entries.length)
          ..u16(entries.length)
          ..u32(centralBytes.length)
          ..u32(centralOffset)
          ..u16(0))
        .toBytes());
    return out.toBytes();
  }

  static (int, int) _dosDateTime(DateTime d) {
    final time = (d.hour << 11) | (d.minute << 5) | (d.second ~/ 2);
    final date = ((d.year - 1980).clamp(0, 127) << 9) | (d.month << 5) | d.day;
    return (time, date);
  }
}

class ZipReader {
  ZipReader(this.bytes) {
    _readCentralDirectory();
  }

  final Uint8List bytes;
  final List<_CentralEntry> _entries = [];

  List<String> get names => [for (final e in _entries) e.name];

  bool get isEncrypted => _entries.any((e) => e.flags & 1 != 0);

  bool contains(String name) => _entries.any((e) => e.name == name);

  /// Returns the decompressed content of [name], or null if not present.
  Uint8List? read(String name, {String? password}) {
    for (final e in _entries) {
      if (e.name == name) return _extract(e, password);
    }
    return null;
  }

  void _readCentralDirectory() {
    final view = ByteData.sublistView(bytes);
    var eocd = -1;
    final minPos = bytes.length - 22 - 0xFFFF;
    for (var i = bytes.length - 22; i >= 0 && i >= minPos; i--) {
      if (view.getUint32(i, Endian.little) == _endOfCentralDirSig) {
        eocd = i;
        break;
      }
    }
    if (eocd < 0) throw const FormatException('Not a zip file');
    final count = view.getUint16(eocd + 10, Endian.little);
    var pos = view.getUint32(eocd + 16, Endian.little);
    for (var i = 0; i < count; i++) {
      if (view.getUint32(pos, Endian.little) != _centralHeaderSig) {
        throw const FormatException('Corrupt central directory');
      }
      final flags = view.getUint16(pos + 8, Endian.little);
      final method = view.getUint16(pos + 10, Endian.little);
      final crc = view.getUint32(pos + 16, Endian.little);
      final compressedSize = view.getUint32(pos + 20, Endian.little);
      final size = view.getUint32(pos + 24, Endian.little);
      final nameLength = view.getUint16(pos + 28, Endian.little);
      final extraLength = view.getUint16(pos + 30, Endian.little);
      final commentLength = view.getUint16(pos + 32, Endian.little);
      final localOffset = view.getUint32(pos + 42, Endian.little);
      final nameBytes = bytes.sublist(pos + 46, pos + 46 + nameLength);
      final name = (flags & 0x0800) != 0
          ? utf8.decode(nameBytes)
          : latin1.decode(nameBytes);
      final extra = Uint8List.sublistView(bytes, pos + 46 + nameLength,
          pos + 46 + nameLength + extraLength);
      _entries.add(_CentralEntry(
        name: name.replaceAll('\\', '/'),
        flags: flags,
        method: method,
        crc: crc,
        compressedSize: compressedSize,
        size: size,
        localOffset: localOffset,
        aes: _parseAesExtra(extra),
      ));
      pos += 46 + nameLength + extraLength + commentLength;
    }
  }

  static _AesInfo? _parseAesExtra(Uint8List extra) {
    final view = ByteData.sublistView(extra);
    var p = 0;
    while (p + 4 <= extra.length) {
      final id = view.getUint16(p, Endian.little);
      final size = view.getUint16(p + 2, Endian.little);
      if (id == _aesExtraId && size >= 7 && p + 4 + size <= extra.length) {
        return _AesInfo(
          version: view.getUint16(p + 4, Endian.little),
          strength: extra[p + 8],
          method: view.getUint16(p + 9, Endian.little),
        );
      }
      p += 4 + size;
    }
    return null;
  }

  Uint8List _extract(_CentralEntry e, String? password) {
    final view = ByteData.sublistView(bytes);
    final p = e.localOffset;
    if (view.getUint32(p, Endian.little) != _localHeaderSig) {
      throw const FormatException('Corrupt local header');
    }
    final nameLength = view.getUint16(p + 26, Endian.little);
    final extraLength = view.getUint16(p + 28, Endian.little);
    final start = p + 30 + nameLength + extraLength;
    var data = Uint8List.sublistView(bytes, start, start + e.compressedSize);
    var method = e.method;
    var checkCrc = true;
    if (e.flags & 1 != 0) {
      if (method != _methodAes || e.aes == null) {
        throw const FormatException(
            'Unsupported encryption (only WinZip AES is supported)');
      }
      if (password == null || password.isEmpty) {
        throw PasswordRequiredException();
      }
      data = WinZipAes.decrypt(data, password, strength: e.aes!.strength);
      method = e.aes!.method;
      checkCrc = e.aes!.version == 1;
    }
    final Uint8List result;
    switch (method) {
      case _methodStored:
        result = Uint8List.fromList(data);
      case _methodDeflate:
        result = Uint8List.fromList(_rawZlib.decode(data));
      default:
        throw FormatException('Unsupported compression method $method');
    }
    if (checkCrc && getCrc32(result) != e.crc) {
      throw const FormatException('CRC mismatch');
    }
    return result;
  }
}

class _CentralEntry {
  _CentralEntry({
    required this.name,
    required this.flags,
    required this.method,
    required this.crc,
    required this.compressedSize,
    required this.size,
    required this.localOffset,
    this.aes,
  });

  final String name;
  final int flags;
  final int method;
  final int crc;
  final int compressedSize;
  final int size;
  final int localOffset;
  final _AesInfo? aes;
}

class _AesInfo {
  _AesInfo({required this.version, required this.strength, required this.method});

  final int version;
  final int strength;
  final int method;
}

/// Little-endian byte builder.
class BytesData {
  final _b = BytesBuilder();

  void u8(int v) => _b.addByte(v & 0xFF);

  void u16(int v) {
    _b.addByte(v & 0xFF);
    _b.addByte((v >> 8) & 0xFF);
  }

  void u32(int v) {
    u16(v & 0xFFFF);
    u16((v >> 16) & 0xFFFF);
  }

  void bytes(List<int> v) => _b.add(v);

  Uint8List toBytes() => _b.toBytes();
}
