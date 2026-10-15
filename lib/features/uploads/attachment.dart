/// Attachment helpers that follow the backend contract:
/// 1. POST /conversations/{id}/messages with type IMAGE|FILE and non-blank content
/// 2. POST /uploads (multipart: `messageId` + `file`, with a real Content-Type)
/// The returned `fileUrl` is a relative path such as `/uploads/<uuid>.jpg`.
const int maxUploadBytes = 25 * 1024 * 1024;

const Map<String, String> _mimeByExtension = {
  'jpg': 'image/jpeg',
  'jpeg': 'image/jpeg',
  'png': 'image/png',
  'gif': 'image/gif',
  'webp': 'image/webp',
  'bmp': 'image/bmp',
  'mp4': 'video/mp4',
  'mov': 'video/quicktime',
  'mp3': 'audio/mpeg',
  'm4a': 'audio/mp4',
  'wav': 'audio/wav',
  'pdf': 'application/pdf',
  'txt': 'text/plain',
  'zip': 'application/zip',
  'docx':
      'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
  'xlsx':
      'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
};

String _extension(String fileName) {
  final dot = fileName.lastIndexOf('.');
  return dot < 0 ? '' : fileName.substring(dot + 1).toLowerCase();
}

/// Returns a MIME type the backend accepts, or null when unsupported.
String? mimeTypeForFile(String fileName) => _mimeByExtension[_extension(fileName)];

/// Message type to create before uploading: IMAGE for images, FILE otherwise.
String messageTypeForMime(String mime) =>
    mime.startsWith('image/') ? 'IMAGE' : 'FILE';

/// Client-side validation (the backend validates again). Null means valid.
String? validateUpload(String fileName, int sizeBytes) {
  if (mimeTypeForFile(fileName) == null) return 'This file type is not supported.';
  if (sizeBytes <= 0) return 'The file is empty.';
  if (sizeBytes > maxUploadBytes) return 'Files must be 25 MB or smaller.';
  return null;
}

/// Resolves relative `/uploads/...` paths against the API base URL.
String? resolveAttachmentUrl(String? raw, String baseUrl) {
  final value = (raw ?? '').trim();
  if (value.isEmpty) return null;
  final uri = Uri.tryParse(value);
  if (uri == null) return null;
  if (uri.hasScheme) {
    return (uri.scheme == 'http' || uri.scheme == 'https') && uri.host.isNotEmpty
        ? value
        : null;
  }
  final base = baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl;
  return value.startsWith('/') ? '$base$value' : '$base/$value';
}

class Attachment {
  final Object? id;
  final Object? messageId;
  final String type;
  final String fileName;
  final String? fileUrl;
  final String mimeType;
  final int fileSize;
  const Attachment({
    this.id,
    this.messageId,
    required this.type,
    required this.fileName,
    this.fileUrl,
    required this.mimeType,
    this.fileSize = 0,
  });

  bool get isImage =>
      type.toUpperCase() == 'IMAGE' || mimeType.toLowerCase().startsWith('image/');

  /// Parses an UploadResponse (optionally wrapped in {data: ...}).
  factory Attachment.fromJson(Map<String, dynamic> json) {
    final map = json['data'] is Map ? Map<String, dynamic>.from(json['data'] as Map) : json;
    final size = map['fileSize'];
    return Attachment(
      id: map['id'],
      messageId: map['messageId'],
      type: (map['type'] ?? '').toString(),
      fileName: (map['fileName'] ?? 'Attachment').toString(),
      fileUrl: (map['fileUrl'] ?? map['url'])?.toString(),
      mimeType: (map['mimeType'] ?? '').toString(),
      fileSize: size is num ? size.toInt() : 0,
    );
  }
}
