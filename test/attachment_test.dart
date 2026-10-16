import 'package:flutter_test/flutter_test.dart';
import 'package:mychat/features/uploads/attachment.dart';

void main() {
  test('parses an UploadResponse wrapped in ApiResponse', () {
    final a = Attachment.fromJson({
      'success': true,
      'data': {
        'id': 1, 'messageId': 100, 'type': 'IMAGE', 'fileName': 'photo.jpg',
        'fileUrl': '/uploads/abc.jpg', 'mimeType': 'image/jpeg', 'fileSize': 1048576,
      },
    });
    expect(a.isImage, isTrue);
    expect(a.messageId, 100);
    expect(a.fileSize, 1048576);
  });

  test('resolves relative upload paths against the API base', () {
    expect(resolveAttachmentUrl('/uploads/a.jpg', 'https://api.test'), 'https://api.test/uploads/a.jpg');
    expect(resolveAttachmentUrl('/uploads/a.jpg', 'https://api.test/'), 'https://api.test/uploads/a.jpg');
    expect(resolveAttachmentUrl('https://cdn.test/a.jpg', 'https://api.test'), 'https://cdn.test/a.jpg');
    expect(resolveAttachmentUrl('javascript:alert(1)', 'https://api.test'), isNull);
    expect(resolveAttachmentUrl('  ', 'https://api.test'), isNull);
  });

  test('validates type and size', () {
    expect(validateUpload('a.jpg', 100), isNull);
    expect(validateUpload('a.exe', 100), isNotNull);
    expect(validateUpload('a.jpg', maxUploadBytes + 1), isNotNull);
    expect(validateUpload('a.jpg', 0), isNotNull);
  });

  test('mime and message type mapping', () {
    expect(mimeTypeForFile('X.PNG'), 'image/png');
    expect(messageTypeForMime('image/png'), 'IMAGE');
    expect(messageTypeForMime('application/pdf'), 'FILE');
  });
}
