import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/widgets.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// A file chosen by the user.
class ChosenFile {
  const ChosenFile(this.name, this.bytes);

  final String name;
  final Uint8List bytes;
}

Future<ChosenFile?> pickAnyFile({FileType type = FileType.any}) async {
  final file = await FilePicker.pickFile(type: type);
  if (file == null) return null;
  return ChosenFile(file.name, await file.xFile.readAsBytes());
}

/// Hands a file to the system share sheet (e.g. to save it to Files, send
/// it by mail or open it in another app). Nothing is uploaded by this app.
Future<void> shareBytes(BuildContext context, Uint8List bytes, String name,
    {String mimeType = 'application/octet-stream'}) async {
  final box = context.findRenderObject() as RenderBox?;
  final dir = await getTemporaryDirectory();
  final file = File(p.join(dir.path, name));
  await file.writeAsBytes(bytes, flush: true);
  await SharePlus.instance.share(ShareParams(
    files: [XFile(file.path, mimeType: mimeType, name: name)],
    sharePositionOrigin:
        box == null ? null : box.localToGlobal(Offset.zero) & box.size,
  ));
}

/// Lets the user choose where to save a file. Returns false if cancelled.
Future<bool> saveBytesAs(Uint8List bytes, String name,
    {String mimeType = 'application/octet-stream'}) async {
  final uri = await FilePicker.saveFile(
      fileName: name, bytes: bytes, mimeType: mimeType);
  return uri != null;
}

String mimeTypeFor(String name) {
  switch (p.extension(name).toLowerCase()) {
    case '.jpg':
    case '.jpeg':
      return 'image/jpeg';
    case '.png':
      return 'image/png';
    case '.gif':
      return 'image/gif';
    case '.webp':
      return 'image/webp';
    case '.heic':
      return 'image/heic';
    case '.pdf':
      return 'application/pdf';
    case '.csv':
      return 'text/csv';
    case '.txt':
      return 'text/plain';
    case '.xlsx':
      return 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
    default:
      return 'application/octet-stream';
  }
}
