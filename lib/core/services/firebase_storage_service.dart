import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as path;

class UploadProgress {
  final double progress;
  final String fileName;
  final bool isComplete;
  final String? downloadUrl;
  final String? error;

  UploadProgress({
    required this.progress,
    required this.fileName,
    this.isComplete = false,
    this.downloadUrl,
    this.error,
  });
}

class FirebaseStorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Upload file to Firebase Storage with progress tracking
  Future<String> uploadFile({
    required File file,
    required String folder,
    String? customFileName,
    String? userId,
    Function(UploadProgress)? onProgress,
  }) async {
    try {
      print(
        '🔄 FirebaseStorageService: Starting file upload to folder: $folder',
      );

      // Generate unique filename with timestamp
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName =
          customFileName ?? '${timestamp}_${path.basename(file.path)}';

      // Create file path with user ID if provided
      final filePath = userId != null
          ? '$folder/$userId/$fileName'
          : '$folder/$fileName';

      // Create reference to the file location
      final ref = _storage.ref().child(filePath);

      // Upload file
      final uploadTask = ref.putFile(file);

      // Track upload progress
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        final progress =
            (snapshot.bytesTransferred / snapshot.totalBytes) * 100;
        print(
          '📤 FirebaseStorageService: Upload progress: ${progress.toStringAsFixed(2)}%',
        );

        // Call progress callback if provided
        onProgress?.call(
          UploadProgress(
            progress: progress,
            fileName: fileName,
            isComplete: progress == 100,
          ),
        );
      });

      // Wait for upload to complete
      final snapshot = await uploadTask;

      // Get download URL
      final downloadUrl = await snapshot.ref.getDownloadURL();

      print('✅ FirebaseStorageService: File uploaded successfully');
      print('🔗 FirebaseStorageService: Download URL: $downloadUrl');

      // Call final progress callback
      onProgress?.call(
        UploadProgress(
          progress: 100.0,
          fileName: fileName,
          isComplete: true,
          downloadUrl: downloadUrl,
        ),
      );

      return downloadUrl;
    } catch (e) {
      print('❌ FirebaseStorageService: Upload error: $e');

      // Call error progress callback
      onProgress?.call(
        UploadProgress(
          progress: 0.0,
          fileName: customFileName ?? path.basename(file.path),
          isComplete: false,
          error: e.toString(),
        ),
      );

      throw Exception('Failed to upload file: ${e.toString()}');
    }
  }

  // Upload multiple files with progress tracking
  Future<List<String>> uploadMultipleFiles({
    required List<File> files,
    required String folder,
    String? userId,
    Function(UploadProgress)? onProgress,
  }) async {
    final List<String> downloadUrls = [];
    final List<Future<String>> uploadTasks = [];

    for (int i = 0; i < files.length; i++) {
      final file = files[i];
      final fileName =
          '${DateTime.now().millisecondsSinceEpoch}_${i}_${path.basename(file.path)}';

      uploadTasks.add(
        uploadFile(
          file: file,
          folder: folder,
          customFileName: fileName,
          userId: userId,
          onProgress: (progress) {
            // Call progress callback with file index
            onProgress?.call(
              UploadProgress(
                progress: progress.progress,
                fileName: progress.fileName,
                isComplete: progress.isComplete,
                downloadUrl: progress.downloadUrl,
                error: progress.error,
              ),
            );
          },
        ),
      );
    }

    try {
      final results = await Future.wait(uploadTasks);
      downloadUrls.addAll(results);
      print('✅ FirebaseStorageService: All files uploaded successfully');
      return downloadUrls;
    } catch (e) {
      print('❌ FirebaseStorageService: Multiple upload error: $e');
      throw Exception('Failed to upload files: ${e.toString()}');
    }
  }

  // Upload leave request attachment
  Future<String> uploadLeaveAttachment(File file) async {
    return await uploadFile(file: file, folder: 'leave-attachments');
  }

  // Upload profile image
  Future<String> uploadProfileImage(File file) async {
    return await uploadFile(file: file, folder: 'profile-images');
  }

  // Upload document
  Future<String> uploadDocument(File file) async {
    return await uploadFile(file: file, folder: 'documents');
  }

  // Delete file from Firebase Storage
  Future<void> deleteFile(String downloadUrl) async {
    try {
      print('🔄 FirebaseStorageService: Deleting file: $downloadUrl');

      final ref = _storage.refFromURL(downloadUrl);
      await ref.delete();

      print('✅ FirebaseStorageService: File deleted successfully');
    } catch (e) {
      print('❌ FirebaseStorageService: Delete error: $e');
      throw Exception('Failed to delete file: ${e.toString()}');
    }
  }

  // Get file metadata
  Future<FullMetadata> getFileMetadata(String downloadUrl) async {
    try {
      final ref = _storage.refFromURL(downloadUrl);
      return await ref.getMetadata();
    } catch (e) {
      print('❌ FirebaseStorageService: Get metadata error: $e');
      throw Exception('Failed to get file metadata: ${e.toString()}');
    }
  }

  // List files in a folder
  Future<List<Reference>> listFiles(String folder) async {
    try {
      final ref = _storage.ref().child(folder);
      final result = await ref.listAll();
      return result.items;
    } catch (e) {
      print('❌ FirebaseStorageService: List files error: $e');
      throw Exception('Failed to list files: ${e.toString()}');
    }
  }
}

// Provider for FirebaseStorageService
final firebaseStorageServiceProvider = Provider<FirebaseStorageService>((ref) {
  return FirebaseStorageService();
});
