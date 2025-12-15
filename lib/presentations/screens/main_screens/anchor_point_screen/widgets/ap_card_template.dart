import 'dart:math';

import 'package:anchor_point_app/core/utils/anchor_point_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class ApCardTemplate extends StatefulWidget {
  final Widget child;
  final EdgeInsets? padding;
  final double? elevation;
  final bool available;
  final int step;
  final bool activeStep;
  final IconData icon;

  const ApCardTemplate({
    Key? key,
    required this.child,
    this.padding,
    this.elevation,
    this.available = true,
    required this.step,
    this.activeStep = false,
    this.icon = Icons.archive,
  }) : super(key: key);

  @override
  State<ApCardTemplate> createState() => _ApCardTemplateState();
}

class _ApCardTemplateState extends State<ApCardTemplate>
    with TickerProviderStateMixin {
  @override
  Widget build(BuildContext context) {
    ColorScheme colorScheme = Theme.of(context).colorScheme;
    return Animate(
      autoPlay: true,
      delay: Duration(milliseconds: 3000),
      onComplete: (controller) async {
        await controller.reverse();
        await Future.delayed(Duration(milliseconds: 500));
        controller.forward();
      },
      effects: [
        if (widget.activeStep)
          TintEffect(
            curve: Curves.linear,
            begin: 0,
            end: 0.1,
            color: colorScheme.onSurface,
            duration: 1000.ms,
          ),
      ],
      child: Card(
        elevation: widget.activeStep ? 5 : 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(
            color: widget.available
                ? colorScheme.primary
                : colorScheme.secondary,
          ),
        ),

        child: Stack(
          children: [
            Padding(
              padding: widget.padding ?? const EdgeInsets.all(10.0),
              child: widget.child,
            ),
            Align(
              alignment: Alignment.topLeft,
              child: Padding(
                padding: EdgeInsetsGeometry.all(8),
                child: FaIcon(widget.icon, size: 12),
              ),
            ),
            if (!widget.available)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: Colors.black.withOpacity(0.5),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
