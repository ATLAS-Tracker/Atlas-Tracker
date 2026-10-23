import 'package:flutter/material.dart';
import 'package:opennutritracker/generated/l10n.dart';

class MealSearchBar extends StatefulWidget {
  final ValueNotifier<String> searchStringListener;
  final ValueChanged<String> onSearchSubmit;
  final VoidCallback onBarcodePressed;

  const MealSearchBar(
      {super.key,
      required this.searchStringListener,
      required this.onSearchSubmit,
      required this.onBarcodePressed});

  @override
  State<MealSearchBar> createState() => _MealSearchBarState();
}

class _MealSearchBarState extends State<MealSearchBar> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.searchStringListener.value);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
            child: TextField(
          controller: _controller,
          textInputAction: TextInputAction.search,
          onChanged: (input) {
            widget.searchStringListener.value = input;
            widget.onSearchSubmit(input);
          },
          onSubmitted: widget.onSearchSubmit,
          style: Theme.of(context).textTheme.bodyMedium,
          decoration: InputDecoration(
            hintText: S.of(context).searchLabel,
            hintMaxLines: 1,
            hintStyle: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: colors.onSurfaceVariant),
            prefixIcon: Icon(Icons.search_rounded,
                color: colors.onSurfaceVariant, size: 23),
            filled: true,
            fillColor: colors.surfaceContainerLowest,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                    color: colors.onSurface.withValues(alpha: 0.08))),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: colors.primary, width: 1.5)),
          ),
        )),
        const SizedBox(width: 10),
        IconButton.filled(
          constraints: const BoxConstraints(minWidth: 52, minHeight: 52),
          style: IconButton.styleFrom(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16))),
          tooltip: S.of(context).searchLabel,
          icon: const Icon(Icons.qr_code_scanner_rounded, size: 25),
          onPressed: () {
            FocusManager.instance.primaryFocus?.unfocus();
            widget.onBarcodePressed();
          },
        ),
      ],
    );
  }
}
