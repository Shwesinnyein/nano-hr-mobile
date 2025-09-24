import 'dart:io';

class AttachmentModel {
  final String id;
  final String fileName;
  final String localPath;
  final String? firebaseUrl;
  final String fileType;
  final double fileSizeMB;
  final DateTime createdAt;
  final bool isUploaded;

  AttachmentModel({
    required this.id,
    required this.fileName,
    required this.localPath,
    this.firebaseUrl,
    required this.fileType,
    required this.fileSizeMB,
    required this.createdAt,
    this.isUploaded = false,
  });

  // Create from file
  factory AttachmentModel.fromFile(File file) {
    final String fileName = file.path.split('/').last;
    final String fileType = fileName.split('.').last.toLowerCase();
    final double fileSizeMB = file.lengthSync() / (1024 * 1024);

    return AttachmentModel(
      id: 'att_${DateTime.now().millisecondsSinceEpoch}',
      fileName: fileName,
      localPath: file.path,
      fileType: fileType,
      fileSizeMB: fileSizeMB,
      createdAt: DateTime.now(),
    );
  }

  // Create from JSON (for API responses)
  factory AttachmentModel.fromJson(Map<String, dynamic> json) {
    return AttachmentModel(
      id: json['id'] ?? '',
      fileName: json['fileName'] ?? json['name'] ?? '',
      localPath: json['localPath'] ?? '',
      firebaseUrl: json['firebaseUrl'] ?? json['url'],
      fileType: json['fileType'] ?? json['type'] ?? '',
      fileSizeMB: (json['fileSizeMB'] ?? 0).toDouble(),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      isUploaded: json['isUploaded'] ?? false,
    );
  }

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fileName': fileName,
      'localPath': localPath,
      'firebaseUrl': firebaseUrl,
      'fileType': fileType,
      'fileSizeMB': fileSizeMB,
      'createdAt': createdAt.toIso8601String(),
      'isUploaded': isUploaded,
    };
  }

  // Convert to API format
  Map<String, dynamic> toApiFormat() {
    return {
      'name': fileName,
      'url': firebaseUrl ?? '',
      'type': fileType,
      'size': fileSizeMB,
    };
  }

  // Copy with updated values
  AttachmentModel copyWith({
    String? id,
    String? fileName,
    String? localPath,
    String? firebaseUrl,
    String? fileType,
    double? fileSizeMB,
    DateTime? createdAt,
    bool? isUploaded,
  }) {
    return AttachmentModel(
      id: id ?? this.id,
      fileName: fileName ?? this.fileName,
      localPath: localPath ?? this.localPath,
      firebaseUrl: firebaseUrl ?? this.firebaseUrl,
      fileType: fileType ?? this.fileType,
      fileSizeMB: fileSizeMB ?? this.fileSizeMB,
      createdAt: createdAt ?? this.createdAt,
      isUploaded: isUploaded ?? this.isUploaded,
    );
  }

  // Helper getters
  String get displayName => fileName;
  String get fileIcon => _getFileIcon(fileType);
  bool get isImage =>
      ['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp'].contains(fileType);
  String get formattedSize => '${fileSizeMB.toStringAsFixed(1)} MB';

  String _getFileIcon(String type) {
    switch (type.toLowerCase()) {
      case 'pdf':
        return '📄';
      case 'doc':
      case 'docx':
        return '📝';
      case 'xls':
      case 'xlsx':
        return '📊';
      case 'ppt':
      case 'pptx':
        return '📋';
      case 'txt':
        return '📃';
      case 'zip':
      case 'rar':
        return '📦';
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
        return '🖼️';
      default:
        return '📎';
    }
  }
}
