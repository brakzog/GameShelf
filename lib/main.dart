import 'package:flutter/material.dart';

import 'features/library/library_page.dart';

void main() {
  runApp(const GameShelfApp());
}

class GameShelfApp extends StatelessWidget {
  const GameShelfApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'GameShelf',
      theme: ThemeData.dark(useMaterial3: true),
      home: const LibraryPage(),
    );
  }
}
