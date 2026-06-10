import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

Future<String> copyToAppDocuments(String sourcePath,
    {String subfolder = 'profile_photos'}) async {
  final appDir = await getApplicationDocumentsDirectory();
  final dir = Directory('${appDir.path}/$subfolder');
  if (!dir.existsSync()) await dir.create(recursive: true);
  final dest = '${dir.path}/${const Uuid().v4()}.jpg';
  // Use File.copy when the source is a real file path, otherwise
  // this will throw for content:// URIs on Android — caller should
  // use readAsBytes() and pass those bytes instead.
  try {
    await File(sourcePath).copy(dest);
  } catch (_) {
    // Fallback: return the source path unchanged so the caller can
    // try reading bytes independently.
    return sourcePath;
  }
  return dest;
}
