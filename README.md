# GameShelf 0.1

V0.1 très simple :
- détecte Steam via `libraryfolders.vdf` + `appmanifest_*.acf`
- détecte GOG via le registre Windows
- affiche une liste de jeux
- recherche instantanée
- lance Steam via `steam://rungameid/<appid>`
- lance les jeux GOG via leur executable si trouvé

## Création du projet

```bash
flutter create gameshelf
cd gameshelf
```

Remplace ensuite `pubspec.yaml` et le dossier `lib/` par ceux de ce zip.

## Lancement Windows

```bash
flutter run -d windows
```

## Build exe

```bash
flutter build windows --release
```

