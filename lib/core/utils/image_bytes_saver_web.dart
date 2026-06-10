import 'dart:convert';
import 'dart:typed_data';

Future<String> saveCroppedBytes(
  Uint8List bytes, {
  String subfolder = 'photos',
}) async {
  // Return a data URL — works as a NetworkImage source in Flutter web.
  return 'data:image/jpeg;base64,${base64Encode(bytes)}';
}
