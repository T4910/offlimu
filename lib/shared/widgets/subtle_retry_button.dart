import 'package:flutter/material.dart';

class SubtleRetryButton extends StatelessWidget {
  const SubtleRetryButton({
    super.key,
    required this.onPressed,
    this.tooltip = 'Retry',
    this.icon = Icons.refresh_rounded,
  });

  final VoidCallback? onPressed;
  final String tooltip;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.onSurfaceVariant;
    return IconButton(
      tooltip: tooltip,
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints.tightFor(width: 30, height: 30),
      style: IconButton.styleFrom(
        foregroundColor: color.withValues(alpha: 0.72),
        backgroundColor: Theme.of(
          context,
        ).colorScheme.surface.withValues(alpha: 0.62),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      iconSize: 17,
      icon: Icon(icon),
      onPressed: onPressed,
    );
  }
}
