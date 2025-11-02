import 'package:flutter/material.dart';
import 'package:opennutritracker/core/presentation/widgets/info_dialog.dart';

class WeightInfo extends StatelessWidget {
  final Widget widget;
  final String title;
  final String body;
  final Color color;
  const WeightInfo(
      {super.key,
      required this.widget,
      required this.title,
      required this.body,
      required this.color});

  void _showInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => InfoDialog(
        title: title,
        body: body,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 117,
      height: 75,
      padding: const EdgeInsets.all(20.0),
      decoration: ShapeDecoration(
        color: color,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.0),
        ),
        shadows: const [],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: <Widget>[
          InkWell(
            onTap: () => _showInfoDialog(context),
            child: Center(
              child: widget,
            ),
          ),
          Positioned(
              top: -10,
              right: -13.0,
              child: InkWell(
                onTap: () => _showInfoDialog(context),
                child: const Icon(
                  Icons.help_outline_outlined,
                  size: 20,
                ),
              ))
        ],
      ),
    );
  }
}
