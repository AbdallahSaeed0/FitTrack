// Platform-agnostic helper to persist cropped image bytes.
// On native  → writes to app-documents and returns the file path.
// On web     → base64-encodes into a data: URL (works with NetworkImage).
export 'image_bytes_saver_web.dart'
    if (dart.library.io) 'image_bytes_saver_io.dart';
