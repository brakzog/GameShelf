import 'package:flutter/material.dart';

import 'package:gameshelf/domain/models/game_entry.dart';

class LauncherBadge extends StatelessWidget {
  const LauncherBadge({
    super.key,
    required this.launcher,
  });

  final LauncherType launcher;

  @override
  Widget build(BuildContext context) {
    final style = _styleForLauncher(launcher);

    return Tooltip(
      message: style.label,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.72),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: style.color.withValues(alpha: 0.75),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 8,
            vertical: 5,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  color: style.color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                style.shortLabel,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  _LauncherBadgeStyle _styleForLauncher(LauncherType launcher) {
    return switch (launcher) {
      LauncherType.steam => const _LauncherBadgeStyle(
          label: 'Steam',
          shortLabel: 'STEAM',
          color: Color(0xFF66C0F4),
        ),
      LauncherType.gog => const _LauncherBadgeStyle(
          label: 'GOG',
          shortLabel: 'GOG',
          color: Color(0xFFA970FF),
        ),
      LauncherType.epic => const _LauncherBadgeStyle(
          label: 'Epic Games',
          shortLabel: 'EPIC',
          color: Color(0xFFE5E5E5),
        ),
    };
  }
}

class _LauncherBadgeStyle {
  const _LauncherBadgeStyle({
    required this.label,
    required this.shortLabel,
    required this.color,
  });

  final String label;
  final String shortLabel;
  final Color color;
}
