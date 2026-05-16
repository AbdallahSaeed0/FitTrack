import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

/// Copies [sourcePath] to the app's permanent documents directory and
/// returns the new permanent path. Always safe to store in Hive.
Future<String> copyToAppDocuments(String sourcePath,
    {String subfolder = 'profile_photos'}) async {
  final appDir = await getApplicationDocumentsDirectory();
  final dir = Directory('${appDir.path}/$subfolder');
  if (!dir.existsSync()) await dir.create(recursive: true);
  final ext = sourcePath.contains('.') ? sourcePath.split('.').last : 'jpg';
  final dest = '${dir.path}/${const Uuid().v4()}.$ext';
  await File(sourcePath).copy(dest);
  return dest;
}
