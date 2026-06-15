import 'package:flutter/material.dart';
import 'package:opennutritracker/generated/l10n.dart';

class PlaceholderCard extends StatelessWidget {
  static const double _cardWidth = 162;
  static const double _cardHeight = 176;

  final DateTime day;
  final VoidCallback onTap;
  final bool firstListElement;

  const PlaceholderCard({
    super.key,
    required this.day,
    required this.onTap,
    required this.firstListElement,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final cardSurface = Color.alphaBlend(
      colorScheme.onSurface.withValues(
        alpha: colorScheme.brightness == Brightness.dark ? 0.12 : 0.00,
      ),
      colorScheme.surfaceContainerLow,
    );
    final iconSurface = Color.alphaBlend(
      colorScheme.primary.withValues(
        alpha: colorScheme.brightness == Brightness.dark ? 0.20 : 0.10,
      ),
      cardSurface,
    );
    return Align(
      alignment: Alignment.topLeft,
      child: Row(
        children: [
          SizedBox(
            width: firstListElement ? 16 : 10, // Add leading padding
          ),
          SizedBox(
            width: _cardWidth,
            height: _cardHeight,
            child: Material(
              color: cardSurface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: onTap,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: iconSurface,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.add_rounded,
                        size: 34,
                        color: colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      S.of(context).addLabel,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: colorScheme.onSurface,
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
