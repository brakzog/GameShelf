import 'dart:io';

import 'package:gameshelf/domain/models/game_entry.dart';
import 'package:gameshelf/features/artwork/artwork_resolver.dart';
import 'package:path/path.dart' as p;

class LocalArtworkResolver implements ArtworkResolver {
  const LocalArtworkResolver();

  static const _supportedExtensions = <String>{
    '.jpg',
    '.jpeg',
    '.png',
    '.webp',
  };

  static const _preferredNames = <String>[
    'cover',
    'poster',
    'vertical',
    'library',
    'background',
    'keyart',
    'artwork',
    'hero',
  ];

  static const _ignoredParts = <String>[
    'icon',
    'logo',
    'splash',
    'cursor',
    'avatar',
    'thumbnail',
    'unins',
    'support',
    'redist',
  ];

  @override
  Future<String?> resolve(GameEntry game) async {
    final installPath = game.installPath?.trim();

    if (installPath == null || installPath.isEmpty) {
      return null;
    }

    final directory = Directory(
      installPath.replaceAll('"', ''),
    );

    if (!await directory.exists()) {
      return null;
    }

    final candidates = <File>[];

    try {
      await for (final entity in directory.list(
        recursive: true,
        followLinks: false,
      )) {
        if (entity is! File) {
          continue;
        }

        final extension = p.extension(entity.path).toLowerCase();

        if (!_supportedExtensions.contains(extension)) {
          continue;
        }

        final relativePath = p
            .relative(
              entity.path,
              from: directory.path,
            )
            .toLowerCase();

        if (_ignoredParts.any(relativePath.contains)) {
          continue;
        }

        candidates.add(entity);

        // On évite de parcourir des installations gigantesques indéfiniment.
        if (candidates.length >= 200) {
          break;
        }
      }
    } on FileSystemException {
      return null;
    }

    if (candidates.isEmpty) {
      return null;
    }

    final scoredCandidates = <_ArtworkCandidate>[];

    for (final file in candidates) {
      scoredCandidates.add(
        _ArtworkCandidate(
          file: file,
          score: await _score(file, directory),
        ),
      );
    }

    scoredCandidates.sort(
      (first, second) => second.score.compareTo(first.score),
    );

    final winner = scoredCandidates.first;

    return winner.score > 0 ? winner.file.path : null;
  }

  Future<int> _score(
    File file,
    Directory installDirectory,
  ) async {
    final name = p.basenameWithoutExtension(file.path).toLowerCase();

    final relativePath = p
        .relative(
          file.path,
          from: installDirectory.path,
        )
        .toLowerCase();

    var score = 0;

    for (final preferredName in _preferredNames) {
      if (name == preferredName) {
        score += 100;
      } else if (name.contains(preferredName)) {
        score += 40;
      }
    }

    if (relativePath.contains('artwork')) {
      score += 25;
    }

    if (relativePath.contains('images')) {
      score += 15;
    }

    if (relativePath.contains('assets')) {
      score += 10;
    }

    try {
      final size = await file.length();

      if (size >= 500000) {
        score += 20;
      } else if (size >= 100000) {
        score += 10;
      } else if (size < 20000) {
        score -= 30;
      }
    } on FileSystemException {
      score -= 50;
    }

    final depth = p
        .split(
          p.relative(
            file.path,
            from: installDirectory.path,
          ),
        )
        .length;

    score -= depth * 2;

    return score;
  }
}

class _ArtworkCandidate {
  final File file;
  final int score;

  const _ArtworkCandidate({
    required this.file,
    required this.score,
  });
}
