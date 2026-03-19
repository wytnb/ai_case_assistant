import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

class IntakeAttachmentStorage {
  const IntakeAttachmentStorage();

  Future<String> saveImageAttachment({
    required String sessionId,
    required String attachmentId,
    required String sourceFilePath,
  }) async {
    final Directory attachmentsDirectory = await _getAttachmentsDirectory(
      sessionId,
    );
    await attachmentsDirectory.create(recursive: true);

    final String extension = path.extension(sourceFilePath);
    final String fileName = '$attachmentId${extension.toLowerCase()}';
    final File destinationFile = File(
      path.join(attachmentsDirectory.path, fileName),
    );
    await File(sourceFilePath).copy(destinationFile.path);
    return destinationFile.path;
  }

  Future<void> deleteStoredAttachments(List<String> filePaths) async {
    for (final String filePath in filePaths) {
      final File file = File(filePath);
      if (await file.exists()) {
        await file.delete();
      }
    }
  }

  Future<Directory> _getAttachmentsDirectory(String sessionId) async {
    final Directory appDirectory = await getApplicationDocumentsDirectory();
    return Directory(
      path.join(appDirectory.path, 'intake_sessions', sessionId, 'attachments'),
    );
  }
}
