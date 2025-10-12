import 'package:flutter/material.dart';
import 'package:flutter_popup/flutter_popup.dart';

// WholePopup - a customizable popup widget with various options for appearance and behavior

class WholePopup extends StatefulWidget {
  final Widget content;
  final Widget child;
  final Color? popupColor;
  final bool suggested;
  final bool barrier;
  final bool longpress;

  const WholePopup({
    Key? key,
    required this.content,
    required this.child,
    this.popupColor,
    this.suggested = false,
    this.barrier = false,
    this.longpress = false,
  }) : super(key: key);

  @override
  _WholePopupState createState() => _WholePopupState();
}

class _WholePopupState extends State<WholePopup> {
  @override
  Widget build(BuildContext context) {
    ColorScheme colorScheme = Theme.of(context).colorScheme;
    return CustomPopup(
      isLongPress: widget.longpress,
      arrowColor: colorScheme.secondary,
      backgroundColor: colorScheme.secondary,
      animationCurve: Curves.bounceOut,
      animationDuration: Durations.long1,
      barrierColor: widget.barrier ? Colors.black87 : null,
      content: Container(
        padding: EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: widget.popupColor ?? colorScheme.surface,
          border: Border.all(
            color: widget.suggested
                ? colorScheme.onSurface
                : colorScheme.tertiary,
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        child: widget.content,
      ),
      child: widget.child,
    );
  }
}
