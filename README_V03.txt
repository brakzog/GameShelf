GameShelf 0.3

Changes:
- hides Steam tools/runtimes such as Steamworks redistributables, SteamVR, Proton and SDK entries
- hides the GOG Galaxy launcher itself
- displays Steam/GOG counts and scan duration

Install:
Replace lib/ and pubspec.yaml in C:\GameShelf, then run:
  flutter clean
  flutter pub get
  flutter run -d windows
