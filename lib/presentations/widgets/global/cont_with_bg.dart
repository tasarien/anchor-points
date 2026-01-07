import 'package:flutter/material.dart';
import 'package:flutter_svg_provider/flutter_svg_provider.dart';

// Reusable container with background pattern

class ContWithBg extends StatelessWidget {
  final double width;
  final double height;
  final String assetName;
  final double scale;
  final Color? color;
  final Widget child;
  final int? turns;

  const ContWithBg({
    super.key,
    this.width = double.infinity,
    this.height = double.infinity,
    required this.assetName,
    this.scale = 1,
    this.color = Colors.black,
    this.child = const SizedBox(),
    this.turns = 0,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
        width: width,
        height: height,
        child: RotatedBox(
          quarterTurns: turns!,
          child: DecoratedBox(
            decoration: BoxDecoration(
                image: DecorationImage(
                    image: Svg(
                      'assets/patterns/$assetName.svg',
                      size: const Size(5, 5),
                    ),
                    repeat: ImageRepeat.repeat,
                    scale: scale,
                    colorFilter: ColorFilter.mode(color!, BlendMode.srcIn))),
            child: child,
          ),
        ));
  }
}
