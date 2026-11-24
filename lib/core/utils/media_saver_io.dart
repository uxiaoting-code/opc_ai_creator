import 'dart:io';

import 'package:flutter/services.dart';

const MethodChannel _channel = MethodChannel('opc_ai_creator/media');

Future<bool> saveMediaBytes({
  required Uint8List bytes,
  required String fileName,
  required String mimeType,
}) async {
  if (Platform.isAndroid) {
    final savedUri = await _channel.invokeMethod<String>('saveToGallery', {
      'bytes': bytes,
      'fileName': fileName,
      'mimeType': mimeType,
    });
    return savedUri != null && savedUri.isNotEmpty;
  }

  final target = File('${Directory.systemTemp.path}/$fileName');
  await target.writeAsBytes(bytes, flush: true);
  return true;
}
