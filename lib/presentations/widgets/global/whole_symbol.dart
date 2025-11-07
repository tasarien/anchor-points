import 'package:anchor_point_app/presentations/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

// Whole Symbol - a widget for displaying single character, especially for emojis

class WholeSymbol extends StatefulWidget {
  final String? symbol;
  final Size size;
  final IconData? icon;

  const WholeSymbol({
    super.key,
    this.symbol,
    this.size = const Size(60, 60),
    this.icon,
  });

  @override
  State<WholeSymbol> createState() => _WholeSymbolState();
}

class _WholeSymbolState extends State<WholeSymbol> {
  late bool isSelected = false;

  @override
  Widget build(BuildContext context) {
    ColorScheme colorScheme = Theme.of(context).colorScheme;
    return FilledButton(
      onPressed: null,
      style: ButtonStyle(
        foregroundColor: WidgetStateColor.fromMap({
          WidgetState.pressed: colorScheme.onSurface,
          WidgetState.any: colorScheme.surface,
        }),
        shadowColor: WidgetStatePropertyAll(Colors.black),
        elevation: WidgetStatePropertyAll(3),
        padding: WidgetStatePropertyAll(EdgeInsets.zero),

        backgroundColor: WidgetStateColor.fromMap({
          WidgetState.any: Theme.of(context).scaffoldBackgroundColor,
        }),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        minimumSize: WidgetStatePropertyAll(widget.size),
        maximumSize: WidgetStatePropertyAll(widget.size),
        shape: WidgetStatePropertyAll(
          RoundedSuperellipseBorder(
            side: BorderSide(
              color: isSelected ? colorScheme.error : colorScheme.primary,
            ),
            borderRadius: BorderRadiusGeometry.all(Radius.circular(10)),
          ),
        ),
      ),
      child: Stack(
        fit: StackFit.loose,
        alignment: Alignment.center,
        children: [
          Icon(
            Icons.circle_outlined,
            size: widget.size.height * 0.65,
            color: colorScheme.primary,
          ),
          widget.symbol != null
              ? Text(
                  widget.symbol!,
                  style: TextStyle(
                    fontFamily: "Emoji",
                    color: colorScheme.onSurface,
                    fontSize: widget.size.height / 2,
                  ),
                )
              : widget.icon != null
              ? FaIcon(widget.icon, color: colorScheme.onSurface)
              : SizedBox.shrink(),
        ],
      ),
    );
  }
}
