import 'package:flutter/material.dart';

import 'package:gameshelf/app/app_services.dart';
import 'package:gameshelf/features/home/home_page.dart';
import 'package:gameshelf/features/library/library_controller.dart';
import 'package:gameshelf/features/library/library_page.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  late final LibraryController _libraryController;

  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();

    _libraryController = AppServices.createLibraryController();
    _libraryController.initialize();
  }

  @override
  void dispose() {
    _libraryController.dispose();
    super.dispose();
  }

  void _selectPage(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final extended = MediaQuery.sizeOf(context).width >= 1250;

    return Scaffold(
      body: Row(
        children: <Widget>[
          SafeArea(
            child: NavigationRail(
              selectedIndex: _selectedIndex,
              onDestinationSelected: _selectPage,
              extended: extended,
              leading: const Padding(
                padding: EdgeInsets.only(
                  top: 16,
                  bottom: 28,
                ),
                child: _GameShelfLogo(),
              ),
              destinations: const <NavigationRailDestination>[
                NavigationRailDestination(
                  icon: Icon(Icons.home_outlined),
                  selectedIcon: Icon(Icons.home),
                  label: Text('Accueil'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.grid_view_outlined),
                  selectedIcon: Icon(Icons.grid_view_rounded),
                  label: Text('Bibliothèque'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.star_border_rounded),
                  selectedIcon: Icon(Icons.star_rounded),
                  label: Text('Favoris'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.settings_outlined),
                  selectedIcon: Icon(Icons.settings),
                  label: Text('Paramètres'),
                ),
              ],
            ),
          ),
          const VerticalDivider(
            width: 1,
            thickness: 1,
          ),
          Expanded(
            child: IndexedStack(
              index: _selectedIndex,
              children: <Widget>[
                HomePage(
                  onOpenLibrary: () => _selectPage(1),
                  onOpenFavorites: () => _selectPage(2),
                ),
                LibraryPage(
                  controller: _libraryController,
                ),
                LibraryPage(
                  controller: _libraryController,
                  favoritesOnly: true,
                ),
                const _ComingSoonPage(
                  icon: Icons.settings,
                  title: 'Paramètres',
                  description:
                      'Les préférences de GameShelf seront regroupées ici.',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GameShelfLogo extends StatelessWidget {
  const _GameShelfLogo();

  @override
  Widget build(BuildContext context) {
    final extended = MediaQuery.sizeOf(context).width >= 1250;
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(13),
          ),
          child: Icon(
            Icons.sports_esports_rounded,
            color: colorScheme.onPrimaryContainer,
          ),
        ),
        if (extended) ...<Widget>[
          const SizedBox(width: 12),
          const Text(
            'GameShelf',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ],
    );
  }
}

class _ComingSoonPage extends StatelessWidget {
  const _ComingSoonPage({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: 420,
        ),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(
                icon,
                size: 64,
              ),
              const SizedBox(height: 24),
              Text(
                title,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 12),
              Text(
                description,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
