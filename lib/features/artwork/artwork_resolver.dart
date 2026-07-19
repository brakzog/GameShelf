import 'package:gameshelf/domain/models/game_entry.dart';

abstract interface class ArtworkResolver {
  Future<String?> resolve(GameEntry game);
}
