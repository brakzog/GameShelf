GameShelf 0.5 - Repository + SQLite

Ce sprint remplace le cache JSON par une base SQLite et sépare les responsabilités :
- LibraryPage : affichage uniquement
- LibraryController : état et actions de la bibliothèque
- GameRepository : lecture/écriture des jeux
- AppDatabase : création et accès à SQLite
- Scanners : découverte Steam et GOG

Nouveauté visible :
- Favoris persistants avec l'étoile
- Les favoris sont affichés en premier
- Chargement immédiat depuis %APPDATA%\GameShelf\gameshelf.db
- Rescan toujours effectué en arrière-plan

Installation :
1. Remplacer lib/ et pubspec.yaml dans le dépôt actuel.
2. Exécuter :
   flutter clean
   flutter pub get
   flutter run -d windows

Note :
Le premier lancement de la 0.5 recrée la bibliothèque dans SQLite. Le cache JSON 0.4 reste présent mais n'est plus utilisé.

Commit suggéré :
feat: migrate library cache to SQLite repository
