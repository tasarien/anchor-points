import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class PageIndicator extends StatefulWidget {
  final int segmentsLength;
  final int currentPage;
  final bool canSubmit;
  final List<bool> completed;
  const PageIndicator({
    Key? key,
    required this.segmentsLength,
    required this.currentPage,
    required this.canSubmit,
    required this.completed,
  }) : super(key: key);

  @override
  _PageIndicatorState createState() => _PageIndicatorState();
}

class _PageIndicatorState extends State<PageIndicator> {
  @override
  Widget build(BuildContext context) {
    ColorScheme colorScheme = Theme.of(context).colorScheme;
    Widget content(int index) {
      return AnimatedScale(
        curve: Curves.bounceIn,
        duration: Duration(milliseconds: 500),
        scale: widget.currentPage == index ? 1 : 0.7,
        child: FaIcon(
          index == 0
              ? FontAwesomeIcons.circle
              : index == widget.segmentsLength + 1
              ? FontAwesomeIcons.paperPlane
              : widget.completed[index - 1] == true
              ? FontAwesomeIcons.solidSquare
              : FontAwesomeIcons.square,
          size: 16,
          color: widget.currentPage == index
              ? colorScheme.onSurface
              : colorScheme.secondary,
        ),
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      spacing: 5,
      children: List.generate(widget.segmentsLength + 2, (index) {
        return AnimatedContainer(
          curve: Curves.bounceIn,
          duration: Duration(milliseconds: 500),
          decoration: BoxDecoration(
            border: Border.all(color: colorScheme.primary),
            borderRadius: BorderRadius.circular(5),
          ),
          padding: EdgeInsets.all(5),
          child: content(index),
        );
      }),
    );
  }
}
