import 'package:flutter/material.dart';
import 'package:opennutritracker/core/utils/custom_icons.dart';
import 'package:opennutritracker/generated/l10n.dart';

class MealSearchBar extends StatelessWidget {
  final ValueNotifier<String> searchStringListener;
  final Function(String) onSearchSubmit;
  final Function() onBarcodePressed;

  final _searchTextController = TextEditingController();

  MealSearchBar({
    super.key,
    required this.searchStringListener,
    required this.onSearchSubmit,
    required this.onBarcodePressed,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final searchSurface = Color.alphaBlend(
      colorScheme.onPrimary.withValues(alpha: 0.16),
      colorScheme.primary,
    );
    final hintColor = colorScheme.onPrimary.withValues(alpha: 0.78);
    final dividerColor = colorScheme.onPrimary.withValues(alpha: 0.14);

    return SizedBox(
      height: 76,
      child: TextField(
        controller: _searchTextController,
        cursorColor: colorScheme.onPrimary,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: colorScheme.onPrimary,
              fontWeight: FontWeight.w600,
            ),
        textInputAction: TextInputAction.search,
        onChanged: (input) {
          searchStringListener.value = input;
        },
        onSubmitted: onSearchSubmit,
        decoration: InputDecoration(
          hintText: S.of(context).searchFoodRecipeHint,
          hintStyle: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: hintColor,
                fontWeight: FontWeight.w600,
              ),
          prefixIcon: Icon(
            Icons.search_rounded,
            color: colorScheme.onPrimary,
            size: 32,
          ),
          prefixIconConstraints: const BoxConstraints(
            minWidth: 66,
            minHeight: 76,
          ),
          suffixIcon: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: 42,
                child: VerticalDivider(
                  width: 1,
                  thickness: 1,
                  color: dividerColor,
                ),
              ),
              SizedBox(
                width: 64,
                height: 76,
                child: IconButton(
                  tooltip: S.of(context).searchLabel,
                  icon: Icon(
                    CustomIcons.barcode_scan,
                    color: colorScheme.onPrimary,
                    size: 30,
                  ),
                  onPressed: () {
                    FocusManager.instance.primaryFocus?.unfocus();
                    onBarcodePressed();
                  },
                ),
              ),
            ],
          ),
          suffixIconConstraints: const BoxConstraints(
            minWidth: 82,
            minHeight: 76,
          ),
          filled: true,
          fillColor: searchSurface,
          contentPadding: const EdgeInsets.symmetric(vertical: 26),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(24),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(24),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(24),
            borderSide: BorderSide(
              color: colorScheme.onPrimary.withValues(alpha: 0.22),
            ),
          ),
        ),
      ),
    );
  }
}
