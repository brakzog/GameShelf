import 'dart:io';

class GogLauncherLocator {
  const GogLauncherLocator();

  Future<String?> findLaunchExe(
      String? installLocation, String? displayIcon) async {
    final iconExe = _cleanExePath(displayIcon);
    if (iconExe != null && await File(iconExe).exists()) return iconExe;

    if (installLocation == null || installLocation.isEmpty) return null;
    final dir = Directory(installLocation);
    if (!await dir.exists()) return null;

    final candidates = <File>[];
    await for (final entity in dir.list(followLinks: false)) {
      if (entity is File && entity.path.toLowerCase().endsWith('.exe')) {
        final name = entity.uri.pathSegments.last.toLowerCase();
        if (!name.contains('unins') &&
            !name.contains('setup') &&
            !name.contains('redist')) {
          candidates.add(entity);
        }
      }
    }

    if (candidates.isEmpty) return null;
    candidates.sort((a, b) => a.path.length.compareTo(b.path.length));
    return candidates.first.path;
  }

  String? _cleanExePath(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    var cleaned = value.trim();
    if (cleaned.startsWith('"')) {
      final end = cleaned.indexOf('"', 1);
      if (end > 1) cleaned = cleaned.substring(1, end);
    }
    final exeIndex = cleaned.toLowerCase().indexOf('.exe');
    if (exeIndex >= 0) cleaned = cleaned.substring(0, exeIndex + 4);
    return cleaned;
  }
}
