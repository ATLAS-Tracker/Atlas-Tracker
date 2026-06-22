import 'package:flutter/material.dart';
import 'package:opennutritracker/generated/l10n.dart';

class CopyOrDeleteDialog extends StatelessWidget {
  const CopyOrDeleteDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      contentPadding: const EdgeInsets.fromLTRB(24, 18, 24, 0),
      actionsPadding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
      title: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Color.alphaBlend(
                colorScheme.primary.withValues(
                  alpha:
                      colorScheme.brightness == Brightness.dark ? 0.24 : 0.12,
                ),
                colorScheme.surfaceContainerHighest,
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.more_horiz_rounded,
              color: colorScheme.primary,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              S.of(context).copyOrDeleteTimeDialogTitle,
              style: theme.textTheme.titleLarge?.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
      content: Text(
        S.of(context).copyOrDeleteTimeDialogContent,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: colorScheme.onSurfaceVariant,
          height: 1.35,
        ),
      ),
      actions: [
        TextButton.icon(
          onPressed: () {
            Navigator.of(context).pop(false);
          },
          icon: const Icon(Icons.delete_outline_rounded, size: 18),
          label: Text(S.of(context).dialogDeleteLabel),
          style: TextButton.styleFrom(foregroundColor: colorScheme.error),
        ),
        FilledButton.icon(
          onPressed: () {
            Navigator.of(context).pop(true);
          },
          icon: const Icon(Icons.today_rounded, size: 18),
          label: Text(S.of(context).dialogCopyLabel),
        ),
      ],
    );
  }
}
