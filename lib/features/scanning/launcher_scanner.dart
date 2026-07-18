import 'package:gameshelf/domain/models/game_entry.dart';

abstract interface class LauncherScanner {
  String get name;

  Future<List<GameEntry>> scan();
}
