import 'dart:io';

class FileUtils {
  static double getFileSizeInMB(File file) {
    try {
      final bytes = file.lengthSync();
      return bytes / (1024 * 1024);
    } catch (e) {
      return 0.0;
    }
  }

  static String getFileExtension(String fileName) {
    try {
      final parts = fileName.split('.');
      if (parts.length > 1) {
        return parts.last.toLowerCase();
      }
      return '';
    } catch (e) {
      return '';
    }
  }

  static bool isImageFile(String fileName) {
    final extension = getFileExtension(fileName);
    return ['jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp'].contains(extension);
  }

  static bool isDocumentFile(String fileName) {
    final extension = getFileExtension(fileName);
    return ['pdf', 'doc', 'docx', 'txt', 'rtf'].contains(extension);
  }
}
