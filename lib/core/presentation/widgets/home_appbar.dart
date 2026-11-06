import 'package:flutter/material.dart';
import 'package:opennutritracker/core/presentation/widgets/dynamic_ont_logo.dart';
import 'package:opennutritracker/core/utils/navigation_options.dart';
import 'package:opennutritracker/generated/l10n.dart';
import 'package:opennutritracker/services/firebase_messaging_service.dart';

class HomeAppbar extends StatefulWidget implements PreferredSizeWidget {
  const HomeAppbar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(72);

  @override
  State<HomeAppbar> createState() => _HomeAppbarState();
}

class _HomeAppbarState extends State<HomeAppbar> {
  bool _hasToken = false;

  @override
  void initState() {
    super.initState();
    _checkToken();
  }

  Future<void> _checkToken() async {
    final hasToken =
        await FirebaseMessagingService.instance().hasPushNotificationsToken();
    if (mounted) {
      setState(() {
        _hasToken = hasToken;
      });
    }
  }

  Future<void> _onNotificationPressed() async {
    if (_hasToken) return;
    final success = await FirebaseMessagingService.instance()
        .refreshPushNotificationsToken();
    if (success) {
      await _checkToken();
      if (!_hasToken) {
        _showError();
      }
    } else {
      _showError();
    }
  }

  void _showError() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(S.of(context).notificationActivationError)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      toolbarHeight: 72,
      title: Align(
        alignment: Alignment.centerLeft,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(width: 46, height: 46, child: DynamicOntLogo()),
            const SizedBox(width: 8),
            const _BrandName(),
          ],
        ),
      ),
      actions: [
        IconButton(
          icon: Icon(
            _hasToken
                ? Icons.notifications_active_outlined
                : Icons.notifications_off_outlined,
            color: Theme.of(context)
                .colorScheme
                .onSurface
                .withAlpha(_hasToken ? 255 : 128),
          ),
          tooltip: S.of(context).notificationsLabel,
          onPressed: _onNotificationPressed,
        ),
        IconButton(
          icon: Icon(Icons.settings_outlined,
              color: Theme.of(context).colorScheme.onSurface),
          tooltip: S.of(context).settingsLabel,
          onPressed: () {
            Navigator.of(context).pushNamed(NavigationOptions.settingsRoute);
          },
        )
      ],
    );
  }
}

class _BrandName extends StatelessWidget {
  const _BrandName();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'ATLAS',
          style: textTheme.titleMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.w800,
            height: 0.96,
            letterSpacing: 1.2,
          ),
        ),
        Text(
          'TRACKER',
          style: textTheme.titleMedium?.copyWith(
            color: Theme.of(context).colorScheme.primary,
            fontWeight: FontWeight.w800,
            height: 0.96,
            letterSpacing: 0.9,
          ),
        ),
      ],
    );
  }
}
