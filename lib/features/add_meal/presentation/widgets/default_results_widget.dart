import 'package:flutter/material.dart';
import 'package:opennutritracker/generated/l10n.dart';

class DefaultsResultsWidget extends StatelessWidget {
  const DefaultsResultsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                  color: colors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(24)),
              child:
                  Icon(Icons.search_rounded, color: colors.primary, size: 32),
            ),
            const SizedBox(height: 16),
            Text(S.of(context).searchDefaultLabel,
                textAlign: TextAlign.center,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: colors.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }
}
