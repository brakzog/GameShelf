import 'dart:io';

import '../../../core/utils/registry.dart';
import '../../../core/utils/vdf_parser.dart';

class SteamInstallation {
  const SteamInstallation();

  Future<String?> findSteamRoot() async {
    final registryCandidates = <Future<String?>>[
      Registry.queryValue(r'HKCU\Software\Valve\Steam', 'SteamPath'),
      Registry.queryValue(r'HKCU\Software\Valve\Steam', 'InstallPath'),
      Registry.queryValue(
        r'HKLM\SOFTWARE\WOW6432Node\Valve\Steam',
        'InstallPath',
      ),
      Registry.queryValue(
        r'HKLM\SOFTWARE\Valve\Steam',
        'InstallPath',
      ),
    ];

    for (final future in registryCandidates) {
      final value = await future;
      final normalized = _normalizePath(value);

      if (normalized != null && await Directory(normalized).exists()) {
        return normalized;
      }
    }

    final environment = Platform.environment;
    final fallbackCandidates = <String>[
      if (environment['PROGRAMFILES(X86)'] != null)
        '${environment['PROGRAMFILES(X86)']}\\Steam',
      if (environment['PROGRAMFILES'] != null)
        '${environment['PROGRAMFILES']}\\Steam',
    ];

    for (final candidate in fallbackCandidates) {
      if (await Directory(candidate).exists()) {
        return candidate;
      }
    }

    return null;
  }

  Future<Set<String>> findLibraryRoots(String steamRoot) async {
    final roots = <String>{steamRoot};
    final libraryFile = File(
      '$steamRoot\\steamapps\\libraryfolders.vdf',
    );

    if (!await libraryFile.exists()) {
      return roots;
    }

    final content = await libraryFile.readAsString();
    final parsed = VdfParser.parse(content);
    final libraryFolders = parsed['libraryfolders'];

    if (libraryFolders is! Map) {
      return roots;
    }

    for (final entry in libraryFolders.entries) {
      final value = entry.value;

      if (value is Map) {
        final path = _normalizePath(value['path']?.toString());

        if (path != null && await Directory(path).exists()) {
          roots.add(path);
        }

        continue;
      }

      final path = _normalizePath(value?.toString());

      if (path != null && await Directory(path).exists()) {
        roots.add(path);
      }
    }

    return roots;
  }

  String? _normalizePath(String? value) {
    if (value == null) {
      return null;
    }

    final trimmed = value.trim();

    if (trimmed.isEmpty) {
      return null;
    }

    return trimmed.replaceAll('/', '\\');
  }
}
