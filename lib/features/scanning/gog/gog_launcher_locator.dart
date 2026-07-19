import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

class GogLauncherLocator {
  const GogLauncherLocator();

  Future<String?> findLaunchExe(
    String? installLocation,
    String? displayIcon,
  ) async {
    final installDirectory = await _resolveInstallDirectory(
      installLocation,
    );

    if (installDirectory == null) {
      return null;
    }

    final manifestTarget = await _findFromManifest(
      installDirectory,
    );

    if (manifestTarget != null) {
      return manifestTarget;
    }

    final shortcutTarget = await _findLaunchShortcut(
      installDirectory,
    );

    if (shortcutTarget != null) {
      return shortcutTarget;
    }

    final iconTarget = _extractExePath(displayIcon);

    if (iconTarget != null &&
        await File(iconTarget).exists() &&
        !_isIgnoredExecutable(p.basename(iconTarget))) {
      return iconTarget;
    }

    return _findBestExecutable(installDirectory);
  }

  Future<Directory?> _resolveInstallDirectory(
    String? installLocation,
  ) async {
    if (installLocation == null || installLocation.trim().isEmpty) {
      return null;
    }

    final cleanedPath = _cleanRegistryPath(installLocation);
    final directDirectory = Directory(cleanedPath);

    if (await directDirectory.exists()) {
      return directDirectory;
    }

    /*
     * Certains uninstallers GOG enregistrent un chemin légèrement différent
     * du dossier réel : caractère invisible, tiret, ponctuation ou espace.
     *
     * On recherche donc un dossier équivalent dans le parent.
     */
    final parentPath = p.dirname(cleanedPath);
    final expectedName = _normalizeName(
      p.basename(cleanedPath),
    );

    final parentDirectory = Directory(parentPath);

    if (!await parentDirectory.exists()) {
      return null;
    }

    await for (final entity in parentDirectory.list(
      followLinks: false,
    )) {
      if (entity is! Directory) {
        continue;
      }

      final candidateName = _normalizeName(
        p.basename(entity.path),
      );

      if (candidateName == expectedName) {
        return entity;
      }
    }

    return null;
  }

  Future<String?> _findFromManifest(
    Directory installDirectory,
  ) async {
    await for (final entity in installDirectory.list(
      followLinks: false,
    )) {
      if (entity is! File) {
        continue;
      }

      final fileName = p.basename(entity.path).toLowerCase();

      if (!fileName.startsWith('goggame-') || !fileName.endsWith('.info')) {
        continue;
      }

      try {
        final decoded = jsonDecode(
          await entity.readAsString(),
        );

        if (decoded is! Map) {
          continue;
        }

        final playTasks = decoded['playTasks'];

        if (playTasks is! List) {
          continue;
        }

        final tasks = playTasks.whereType<Map>().toList(growable: false)
          ..sort((first, second) {
            final firstPrimary = first['isPrimary'] == true ? 1 : 0;

            final secondPrimary = second['isPrimary'] == true ? 1 : 0;

            return secondPrimary.compareTo(firstPrimary);
          });

        for (final task in tasks) {
          final rawPath = task['path']?.toString();

          if (rawPath == null || rawPath.trim().isEmpty) {
            continue;
          }

          final candidatePath = p.isAbsolute(rawPath)
              ? p.normalize(_cleanRegistryPath(rawPath))
              : p.normalize(
                  p.join(
                    installDirectory.path,
                    _cleanRegistryPath(rawPath),
                  ),
                );

          final candidate = File(candidatePath);

          if (await candidate.exists()) {
            return candidate.path;
          }
        }
      } on FormatException {
        continue;
      } on FileSystemException {
        continue;
      }
    }

    return null;
  }

  Future<String?> _findLaunchShortcut(
    Directory installDirectory,
  ) async {
    await for (final entity in installDirectory.list(
      followLinks: false,
    )) {
      if (entity is! File) {
        continue;
      }

      final name = p.basename(entity.path).toLowerCase();

      if (!name.endsWith('.lnk')) {
        continue;
      }

      if (name.startsWith('launch ') ||
          name.startsWith('play ') ||
          name.startsWith('start ')) {
        return entity.path;
      }
    }

    return null;
  }

  Future<String?> _findBestExecutable(
    Directory installDirectory,
  ) async {
    final candidates = <File>[];

    await for (final entity in installDirectory.list(
      recursive: true,
      followLinks: false,
    )) {
      if (entity is! File) {
        continue;
      }

      final name = p.basename(entity.path);

      if (!name.toLowerCase().endsWith('.exe')) {
        continue;
      }

      if (_isIgnoredExecutable(name)) {
        continue;
      }

      candidates.add(entity);
    }

    if (candidates.isEmpty) {
      return null;
    }

    candidates.sort((first, second) {
      final firstRelativePath = p.relative(
        first.path,
        from: installDirectory.path,
      );

      final secondRelativePath = p.relative(
        second.path,
        from: installDirectory.path,
      );

      final firstDepth = p.split(firstRelativePath).length;

      final secondDepth = p.split(secondRelativePath).length;

      final depthComparison = firstDepth.compareTo(secondDepth);

      if (depthComparison != 0) {
        return depthComparison;
      }

      return first.path.length.compareTo(
        second.path.length,
      );
    });

    return candidates.first.path;
  }

  bool _isIgnoredExecutable(String value) {
    final name = value.toLowerCase();

    const ignoredParts = <String>[
      'unins',
      'setup',
      'redist',
      'support',
      'config',
      'crash',
      'report',
      'register',
      'dxsetup',
      'vcredist',
      'dotnet',
      'performancetester',
      'benchmark',
      'editor',
      'server',
      'galaxyclient',
      'launcher',
    ];

    return ignoredParts.any(name.contains);
  }

  String _cleanRegistryPath(String value) {
    return value
        .replaceAll('\u0000', '')
        .replaceAll('"', '')
        .trim()
        .replaceAll(RegExp(r'[\\/]+$'), '');
  }

  String _normalizeName(String value) {
    return value
        .replaceAll('\u0000', '')
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '')
        .trim();
  }

  String? _extractExePath(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null;
    }

    final cleaned = _cleanRegistryPath(value);
    final exeIndex = cleaned.toLowerCase().indexOf('.exe');

    if (exeIndex < 0) {
      return null;
    }

    return cleaned.substring(0, exeIndex + 4);
  }
}
