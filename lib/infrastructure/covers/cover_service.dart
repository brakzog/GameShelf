import 'dart:io';

import '../../domain/models/game_entry.dart';
import 'cover_cache.dart';
import 'cover_provider.dart';
import 'cover_result.dart';

class CoverService {
  final CoverCache cache;
  final List<CoverProvider> providers;

  const CoverService({
    required this.cache,
    required this.providers,
  });

  Future<String?> resolveCover(GameEntry game) async {
    final currentPath = game.coverPath;

    if (currentPath != null && await File(currentPath).exists()) {
      return currentPath;
    }

    if (await cache.exists(game)) {
      final cachedFile = await cache.getFile(game);
      return cachedFile.path;
    }

    for (final provider in providers) {
      if (!provider.supports(game)) {
        continue;
      }

      final result = await provider.findCover(game);

      if (!result.found) {
        continue;
      }

      final resolvedPath = await _resolveResult(
        game: game,
        result: result,
      );

      if (resolvedPath != null) {
        return resolvedPath;
      }
    }

    return null;
  }

  Future<String?> _resolveResult({
    required GameEntry game,
    required CoverResult result,
  }) async {
    final localPath = result.localPath;

    if (localPath != null) {
      final source = File(localPath);

      if (!await source.exists()) {
        return null;
      }

      final destination = await cache.getFile(game);
      final destinationPath = destination.path;

      if (source.absolute.path != destination.absolute.path) {
        await source.copy(destinationPath);
      }

      return destinationPath;
    }

    final downloadUrl = result.downloadUrl;

    if (downloadUrl != null) {
      return _downloadCover(
        game: game,
        uri: downloadUrl,
      );
    }

    return null;
  }

  Future<String?> _downloadCover({
    required GameEntry game,
    required Uri uri,
  }) async {
    final client = HttpClient();

    try {
      final request = await client.getUrl(uri);
      request.headers.set(
        HttpHeaders.userAgentHeader,
        'GameShelf/1.0',
      );

      final response = await request.close();

      if (response.statusCode < 200 || response.statusCode >= 300) {
        await response.drain<void>();
        return null;
      }

      final destination = await cache.getFile(game);
      final destinationPath = destination.path;
      final temporaryFile = File('$destinationPath.tmp');

      if (await temporaryFile.exists()) {
        await temporaryFile.delete();
      }

      final sink = temporaryFile.openWrite();

      try {
        await response.pipe(sink);
      } catch (_) {
        await sink.close();

        if (await temporaryFile.exists()) {
          await temporaryFile.delete();
        }

        rethrow;
      }

      if (await destination.exists()) {
        await destination.delete();
      }

      await temporaryFile.rename(destinationPath);

      return destinationPath;
    } on SocketException {
      return null;
    } on HttpException {
      return null;
    } on FileSystemException {
      return null;
    } finally {
      client.close(force: true);
    }
  }
}
