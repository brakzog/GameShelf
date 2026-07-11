import 'dart:convert';
import 'dart:io';

class Registry {
  const Registry._();

  static Future<String?> queryValue(String key, String valueName) async {
    try {
      final result = await Process.run('reg', ['query', key, '/v', valueName]);
      if (result.exitCode != 0) return null;

      final lines = const LineSplitter().convert(result.stdout.toString());
      for (final line in lines) {
        if (!line.contains(valueName)) continue;
        final parts = line.trim().split(RegExp(r'\s{2,}'));
        if (parts.length >= 3) return parts.sublist(2).join(' ').trim();
      }
    } catch (_) {
      return null;
    }
    return null;
  }

  static Future<List<String>> listKeys(String key) async {
    try {
      final result = await Process.run('reg', ['query', key]);
      if (result.exitCode != 0) return [];

      return const LineSplitter()
          .convert(result.stdout.toString())
          .map((line) => line.trim())
          .where((line) => line.startsWith('HKEY_'))
          .where((line) => line != key)
          .toList();
    } catch (_) {
      return [];
    }
  }
}
