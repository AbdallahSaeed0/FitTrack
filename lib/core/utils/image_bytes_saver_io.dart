import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

Future<String> saveCroppedBytes(
  Uint8List bytes, {
  String subfolder = 'photos',
}) async {
  final dir = await getApplicationDocumentsDirectory();
  final folder = Directory('${dir.path}/$subfolder');
  if (!folder.existsSync()) folder.createSync(recursive: true);
  final path = '${folder.path}/${const Uuid().v4()}.jpg';
  File(path).writeAsBytesSync(bytes);
  return path;
}
