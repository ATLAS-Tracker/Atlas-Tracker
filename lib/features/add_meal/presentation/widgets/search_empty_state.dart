import 'package:flutter/material.dart';
import 'package:opennutritracker/generated/l10n.dart';

class SearchEmptyState extends StatelessWidget {
  final bool _initial;
  final String query;
  final VoidCallback? onCreate;
  final VoidCallback? onScan;
  const SearchEmptyState(
      {super.key, this.query = '', this.onCreate, this.onScan})
      : _initial = false;

  const SearchEmptyState.initial({super.key})
      : _initial = true,
        query = '',
        onCreate = null,
        onScan = null;

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
              child: Icon(
                  _initial ? Icons.search_rounded : Icons.search_off_rounded,
                  color: colors.primary,
                  size: 32),
            ),
            const SizedBox(height: 16),
            Text(
                _initial
                    ? S.of(context).searchDefaultLabel
                    : S.of(context).noResultsFound,
                textAlign: TextAlign.center,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: colors.onSurfaceVariant)),
            if (onCreate != null) ...[
              const SizedBox(height: 16),
              FilledButton.icon(
                  onPressed: onCreate,
                  icon: const Icon(Icons.edit_outlined),
                  label: Text(query.trim().isEmpty
                      ? S.of(context).customFoodTitle
                      : '${S.of(context).customFoodTitle} « ${query.trim()} »')),
            ],
            if (onScan != null)
              TextButton.icon(
                  onPressed: onScan,
                  icon: const Icon(Icons.qr_code_scanner),
                  label: Text(S.of(context).scanProductLabel)),
          ],
        ),
      ),
    );
  }
}
