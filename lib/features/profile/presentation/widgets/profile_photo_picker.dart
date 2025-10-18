import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:opennutritracker/core/utils/path_helper.dart';

class ProfilePhotoPicker extends StatefulWidget {
  final void Function(String imagePath) onImagePicked;
  final String? initialImagePath;
  final double size;

  const ProfilePhotoPicker({
    super.key,
    required this.onImagePicked,
    this.initialImagePath,
    this.size = 240,
  });

  @override
  State<ProfilePhotoPicker> createState() => _ProfilePhotoPickerState();
}

class _ProfilePhotoPickerState extends State<ProfilePhotoPicker> {
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

  Future<void> _pickImage() async {
    try {
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
            'profile_photo_$formattedTime${p.extension(pickedFile.path)}';
        final savedPath = await PathHelper.localImagePath(fileName);

        final savedImage = await imageFile.copy(savedPath);

        if (!mounted) return;
        setState(() {
          _imagePath = savedImage.path;
        });
        widget.onImagePicked(fileName);
      }
    } catch (e) {
      debugPrint('Failed to pick and save image: $e');
    }
  }

  String _twoDigits(int n) => n.toString().padLeft(2, '0');

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: _pickImage,
      child: CircleAvatar(
        radius: widget.size / 2,
        backgroundColor: Theme.of(context).colorScheme.primary,
        backgroundImage:
            _imagePath != null ? FileImage(File(_imagePath!)) : null,
        child: _imagePath == null
            ? Icon(Icons.camera_alt,
                size: widget.size / 3,
                color: Theme.of(context).colorScheme.onPrimary)
            : null,
      ),
    );
  }
}
