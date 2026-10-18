import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;

import '../../app/services.dart';
import '../../data/models.dart';
import '../../data/repository.dart';
import '../files.dart';
import '../scope.dart';

/// Lets the user pick a photo or file and stores it as attachment. The
/// returned attachment still has to be linked to a transaction or transfer.
Future<Attachment?> addAttachment(BuildContext context, String source) async {
  final services = context.read;
  ChosenFile? file;
  if (source == 'file') {
    file = await pickAnyFile();
  } else {
    final image = await ImagePicker().pickImage(
      source: source == 'camera' ? ImageSource.camera : ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 2400,
    );
    if (image != null) {
      file = ChosenFile(image.name, await image.readAsBytes());
    }
  }
  if (file == null) return null;
  final uuid = newUuid();
  await File(p.join(services.attachmentsDir.path, uuid)).writeAsBytes(file.bytes);
  final attachment = Attachment(
    uuid: uuid,
    file: uuid,
    name: file.name,
    type: mimeTypeFor(file.name),
    size: file.bytes.length,
  );
  services.repo.saveAttachment(attachment);
  return attachment;
}

/// Removes attachments (and their files) that are no longer referenced.
void cleanupOrphanAttachments(AppServices services) {
  for (final a in services.repo.orphanAttachments()) {
    services.repo.deleteAttachment(a.uuid);
    final file = File(p.join(services.attachmentsDir.path, a.file));
    if (file.existsSync()) file.deleteSync();
  }
}

class AttachmentsSection extends StatelessWidget {
  const AttachmentsSection({
    super.key,
    required this.attachments,
    required this.dir,
    required this.onAdd,
    required this.onRemove,
  });

  final List<Attachment> attachments;
  final Directory dir;
  final void Function(String source) onAdd;
  final void Function(Attachment) onRemove;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
                child: Text(l.attachments,
                    style: Theme.of(context).textTheme.titleSmall)),
            PopupMenuButton<String>(
              icon: const Icon(Icons.attach_file),
              tooltip: l.addAttachment,
              onSelected: onAdd,
              itemBuilder: (context) => [
                PopupMenuItem(
                    value: 'camera',
                    child: ListTile(
                        leading: const Icon(Icons.photo_camera),
                        title: Text(l.attachmentFromCamera))),
                PopupMenuItem(
                    value: 'gallery',
                    child: ListTile(
                        leading: const Icon(Icons.photo),
                        title: Text(l.attachmentFromGallery))),
                PopupMenuItem(
                    value: 'file',
                    child: ListTile(
                        leading: const Icon(Icons.insert_drive_file),
                        title: Text(l.attachmentFromFile))),
              ],
            ),
          ],
        ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final a in attachments)
              _AttachmentChip(attachment: a, file: File(p.join(dir.path, a.file)),
                  onRemove: () => onRemove(a)),
          ],
        ),
      ],
    );
  }
}

class _AttachmentChip extends StatelessWidget {
  const _AttachmentChip({required this.attachment, required this.file, required this.onRemove});

  final Attachment attachment;
  final File file;
  final VoidCallback onRemove;

  bool get _isImage => (attachment.type ?? '').startsWith('image/');

  @override
  Widget build(BuildContext context) {
    final exists = file.existsSync();
    return InputChip(
      avatar: _isImage && exists
          ? ClipOval(child: Image.file(file, width: 24, height: 24, fit: BoxFit.cover))
          : const Icon(Icons.insert_drive_file, size: 18),
      label: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 160),
        child: Text(attachment.name, overflow: TextOverflow.ellipsis),
      ),
      onDeleted: onRemove,
      onPressed: !exists
          ? null
          : () {
              if (_isImage) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => Scaffold(
                      appBar: AppBar(title: Text(attachment.name)),
                      body: InteractiveViewer(
                        child: Center(child: Image.file(file)),
                      ),
                    ),
                  ),
                );
              } else {
                shareBytes(context, file.readAsBytesSync(), attachment.name,
                    mimeType: attachment.type ?? 'application/octet-stream');
              }
            },
    );
  }
}
