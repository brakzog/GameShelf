import 'package:flutter/material.dart';

class GsPlayButton extends StatefulWidget {
  const GsPlayButton({
    super.key,
    required this.onPressed,
    this.label = 'JOUER',
  });

  final VoidCallback onPressed;
  final String label;

  @override
  State<GsPlayButton> createState() => _GsPlayButtonState();
}

class _GsPlayButtonState extends State<GsPlayButton> {
  bool _hovered = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) {
        setState(() {
          _hovered = false;
          _pressed = false;
        });
      },
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => setState(() => _pressed = true),
        onTapCancel: () => setState(() => _pressed = false),
        onTapUp: (_) {
          setState(() => _pressed = false);
          widget.onPressed();
        },
        child: AnimatedScale(
          scale: _pressed
              ? 0.96
              : _hovered
                  ? 1.04
                  : 1,
          duration: const Duration(milliseconds: 110),
          curve: Curves.easeOut,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 140),
            curve: Curves.easeOut,
            padding: const EdgeInsets.symmetric(
              horizontal: 22,
              vertical: 13,
            ),
            decoration: BoxDecoration(
              color: _hovered
                  ? colorScheme.primary
                  : colorScheme.primary.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: colorScheme.onPrimary.withValues(
                  alpha: _hovered ? 0.32 : 0.18,
                ),
              ),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: Colors.black.withValues(
                    alpha: _hovered ? 0.5 : 0.32,
                  ),
                  blurRadius: _hovered ? 18 : 10,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Icon(
                  Icons.play_arrow_rounded,
                  color: colorScheme.onPrimary,
                  size: 26,
                ),
                const SizedBox(width: 8),
                Text(
                  widget.label,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: colorScheme.onPrimary,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.1,
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
