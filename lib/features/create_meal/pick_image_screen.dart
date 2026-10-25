import 'dart:io';
import 'package:opennutritracker/core/styles/color_macro.dart';
import 'package:opennutritracker/generated/l10n.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart';
import 'package:opennutritracker/core/utils/path_helper.dart';

class PhotoPickerButton extends StatefulWidget {
  final void Function(String imagePath) onImagePicked;
  final String? initialImagePath;

  const PhotoPickerButton({
    super.key,
    required this.onImagePicked,
    this.initialImagePath,
  });

  @override
  State<PhotoPickerButton> createState() => _PhotoPickerButtonState();
}

class _PhotoPickerButtonState extends State<PhotoPickerButton> {
  final ImagePicker _picker = ImagePicker();
  String? _imagePath;

  @override
  void initState() {
    super.initState();
    if (widget.initialImagePath != null) {
      PathHelper.localImagePath(widget.initialImagePath!).then((path) {
        if (mounted) {
          setState(() {
            _imagePath = path;
          });
        }
      });
    }
  }

  Future<void> _takeAndStorePhoto() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      final imageFile = File(pickedFile.path);
      if (_imagePath != null) {
        final oldFile = File(_imagePath!);
        if (await oldFile.exists()) {
          try {
            await oldFile.delete();
          } catch (_) {}
        }
      }
      final now = DateTime.now();
      final formattedTime =
          '${now.year}${_twoDigits(now.month)}${_twoDigits(now.day)}_${_twoDigits(now.hour)}${_twoDigits(now.minute)}${_twoDigits(now.second)}';
      final fileName =
          'selected_photo_$formattedTime${extension(pickedFile.path)}';
      final savedPath = await PathHelper.localImagePath(fileName);

      final savedImage = await imageFile.copy(savedPath);

      setState(() {
        _imagePath = savedImage.path;
      });

      widget.onImagePicked(fileName);
    }
  }

  String _twoDigits(int n) => n.toString().padLeft(2, '0');

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final label =
        _imagePath == null ? s.customFoodAddPhoto : s.customFoodChangePhoto;
    return Semantics(
      button: true,
      label: label,
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: atlasBrandGradientColors)),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            key: const ValueKey('recipe-cover'),
            onTap: _takeAndStorePhoto,
            child: SizedBox(
              height: 184,
              child: Stack(children: [
                if (_imagePath != null)
                  Positioned.fill(
                      child: Image.file(File(_imagePath!),
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Center(
                              child: Icon(Icons.restaurant_menu_rounded,
                                  color: Colors.white, size: 48)))),
                if (_imagePath == null) ...[
                  Positioned(
                      right: -32,
                      top: -52,
                      child: Container(
                          width: 210,
                          height: 210,
                          decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withValues(alpha: 0.07)))),
                  Positioned(
                      right: 22,
                      top: 28,
                      child: Icon(Icons.restaurant_menu_rounded,
                          size: 72,
                          color: Colors.white.withValues(alpha: 0.24))),
                ],
                if (_imagePath != null)
                  Positioned.fill(
                      child: DecoratedBox(
                          decoration: BoxDecoration(
                              gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.65)
                      ])))),
                Positioned(
                    left: 20,
                    right: 20,
                    bottom: 20,
                    child: Row(children: [
                      Expanded(
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                            Text(s.recipeCoverLabel,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleLarge
                                    ?.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w800)),
                            const SizedBox(height: 4),
                            Text(label,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                        color: Colors.white
                                            .withValues(alpha: 0.80))),
                          ])),
                      const SizedBox(width: 12),
                      Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.16),
                              borderRadius: BorderRadius.circular(16)),
                          child: const Icon(Icons.add_a_photo_outlined,
                              color: Colors.white, size: 23)),
                    ])),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}
