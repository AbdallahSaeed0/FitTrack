Future<String> copyToAppDocuments(String sourcePath,
    {String subfolder = 'profile_photos'}) async {
  // On web, the image_picker returns a blob URL — return it as-is.
  return sourcePath;
}
