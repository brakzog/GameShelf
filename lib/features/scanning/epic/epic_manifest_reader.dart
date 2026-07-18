import 'dart:convert';
import 'dart:io';

class EpicManifestReader {
  const EpicManifestReader({
    this.manifestDirectory =
        r'C:\ProgramData\Epic\EpicGamesLauncher\Data\Manifests',
  });

  final String manifestDirectory;

  Future<List<Map<String, dynamic>>> readAll() async {
    final directory = Directory(manifestDirectory);

    if (!await directory.exists()) {
      return const [];
    }

    final manifests = <Map<String, dynamic>>[];

    await for (final entity in directory.list()) {
      if (entity is! File || !entity.path.toLowerCase().endsWith('.item')) {
        continue;
      }

      final manifest = await _readManifest(entity);

      if (manifest != null) {
        manifests.add(manifest);
      }
    }

    return manifests;
  }

  Future<Map<String, dynamic>?> _readManifest(File file) async {
    try {
      final content = await file.readAsString();
      final decoded = jsonDecode(content);

      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
    } on FileSystemException {
      // An unreadable manifest must not block the complete library scan.
    } on FormatException {
      // Ignore invalid or incomplete JSON manifests.
    }

    return null;
  }
}
