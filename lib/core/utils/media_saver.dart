import 'dart:typed_data';

import 'media_saver_stub.dart'
    if (dart.library.js_interop) 'media_saver_web.dart'
    if (dart.library.io) 'media_saver_io.dart'
    as implementation;

/// 把已下载的媒体字节保存到当前平台。
Future<bool> saveMediaBytes({
  required Uint8List bytes,
  required String fileName,
  required String mimeType,
}) => implementation.saveMediaBytes(
  bytes: bytes,
  fileName: fileName,
  mimeType: mimeType,
);
