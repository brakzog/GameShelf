import '../../domain/models/game_entry.dart';
import 'cover_result.dart';

abstract class CoverProvider {
  bool supports(GameEntry game);

  Future<CoverResult> findCover(GameEntry game);
}
