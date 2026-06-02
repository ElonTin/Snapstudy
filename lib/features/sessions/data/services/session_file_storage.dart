import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:snapstudy/core/errors/app_exception.dart';
import 'package:snapstudy/core/utils/logger.dart';

/// Saves capture images to app documents (offline-safe).
class SessionFileStorage {
  /// Copies [sourcePath] into the session folder (handles temp/cache paths on Android).
  Future<String> saveCaptureFromPath(String sourcePath, String sessionId) async {
    final dir = await _sessionDir(sessionId);
    final name = 'cap_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final dest = File(p.join(dir.path, name));

    final source = File(sourcePath);
    if (await source.exists()) {
      await source.copy(dest.path);
    } else {
      try {
        final bytes = await XFile(sourcePath).readAsBytes();
        if (bytes.isEmpty) {
          throw const CacheException('Ảnh rỗng hoặc không đọc được.');
        }
        await dest.writeAsBytes(bytes, flush: true);
      } catch (e) {
        AppLogger.warning('saveCaptureFromPath failed', e);
        throw const CacheException('Không đọc được ảnh để lưu.');
      }
    }

    if (!await dest.exists() || await dest.length() == 0) {
      throw const CacheException('Lưu ảnh vào buổi học thất bại.');
    }

    return dest.path;
  }

  Future<String> saveCapture(File sourceFile, String sessionId) =>
      saveCaptureFromPath(sourceFile.path, sessionId);

  Future<Directory> _sessionDir(String sessionId) async {
    final root = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(root.path, 'sessions', sessionId));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  Future<void> deleteFile(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) await file.delete();
    } catch (e) {
      AppLogger.warning('Failed to delete capture file', e);
    }
  }
}
