GameShelf 0.4

- Cache local JSON dans %APPDATA%\\GameShelf\\library_cache.json
- Affichage immédiat de la dernière bibliothèque connue
- Rescan Steam + GOG en arrière-plan
- Mise à jour atomique du cache après le scan

Installation : remplacer lib/ et pubspec.yaml, puis :
flutter clean
flutter pub get
flutter run -d windows

Test conseillé :
1. Premier lancement : le scan complet prend le temps habituel.
2. Fermer puis relancer : les jeux doivent apparaître immédiatement pendant le rescan.
