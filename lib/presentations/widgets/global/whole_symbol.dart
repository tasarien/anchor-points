import 'package:anchor_point_app/presentations/theme/app_theme.dart';
import 'package:flutter/material.dart';

// Whole Symbol - a widget for displaying single character, especially for emojis

class WholeSymbol extends StatefulWidget {
  final String symbol;
  final Size size;

  const WholeSymbol({
    super.key,
    required this.symbol,
    this.size = const Size(60, 60),
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
        minimumSize: WidgetStatePropertyAll(widget.size),
        maximumSize: WidgetStatePropertyAll(widget.size),
        shape: WidgetStatePropertyAll(
          RoundedSuperellipseBorder(
            side: BorderSide(
              color: isSelected ? colorScheme.error : colorScheme.secondary,
            ),
            borderRadius: BorderRadiusGeometry.all(Radius.circular(10)),
          ),
        ),
      ),
      child: Stack(
        fit: StackFit.loose,
        alignment: Alignment.center,
        children: [
          Icon(Icons.circle_outlined, size: 35, color: AppColors.darkTeal),
          Text(
            widget.symbol,
            style: TextStyle(
              fontFamily: "Emoji",
              color: AppColors.beigeLight,
              fontSize: 28,
            ),
          ),
        ],
      ),
    );
  }
}
