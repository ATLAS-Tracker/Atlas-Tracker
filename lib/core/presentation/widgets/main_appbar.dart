import 'package:flutter/material.dart';
import 'package:opennutritracker/core/utils/navigation_options.dart';

class MainAppbar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final IconData iconData;

  const MainAppbar({super.key, required this.title, required this.iconData});

  @override
  Widget build(BuildContext context) {
    // Same height as HomeAppbar so the settings icon lines up across tabs.
    return AppBar(
      toolbarHeight: 72,
      leading: Icon(iconData),
      title: Text(title),
      actions: [
        IconButton(
            onPressed: () {
              Navigator.of(context).pushNamed(NavigationOptions.settingsRoute);
            },
            icon: const Icon(Icons.settings_outlined))
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(72);
}
