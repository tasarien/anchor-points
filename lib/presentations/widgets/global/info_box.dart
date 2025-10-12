import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

// InfoBox - widget displaying information in a box with an icon and text

class InfoBox extends StatelessWidget {
  final List<String> text;
  const InfoBox({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    ColorScheme colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border.all(color: colorScheme.tertiary),
        borderRadius: BorderRadius.circular(10),
      ),
      width: double.infinity,
      child: Row(
        children: [
          FaIcon(FontAwesomeIcons.circleInfo, color: colorScheme.tertiary),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: text
                  .map(
                    (t) => Text(
                      '• $t',
                      style: TextStyle(color: colorScheme.tertiary),
                    ),
                  )
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}
