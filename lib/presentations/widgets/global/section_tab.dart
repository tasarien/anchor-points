import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

// UI element to separate column sections

class SectionTab extends StatefulWidget {
  final String? text;
  final double fontSize;
  final Widget? content;
  final bool openByDefault;
  const SectionTab({
    super.key,
    this.text,
    this.fontSize = 15,
    this.content,
    this.openByDefault = false,
  });

  @override
  State<SectionTab> createState() => _SectionTabState();
}

class _SectionTabState extends State<SectionTab> {
  late bool isOpen;

  @override
  void initState() {
    super.initState();
    isOpen = widget.openByDefault;
  }

  @override
  Widget build(BuildContext context) {
    ColorScheme colorScheme = Theme.of(context).colorScheme;
    IconData actionIcon = isOpen
        ? FontAwesomeIcons.chevronUp
        : FontAwesomeIcons.chevronDown;

    return Column(
      children: [
        Stack(
          children: [
            Center(
              child: Divider(
                height: widget.fontSize * 2,
                color: colorScheme.secondary,
              ),
            ),
            widget.text != null
                ? Center(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: colorScheme.surface,
                        border: Border.all(color: colorScheme.tertiary),
                      ),
                      padding: EdgeInsets.symmetric(vertical: 5, horizontal: 8),
                      child: Text(
                        widget.text!,
                        style: TextStyle(
                          fontFamily: 'EBGaramond',
                          fontSize: widget.fontSize,
                        ),
                      ),
                    ),
                  )
                : Container(),
            widget.content != null
                ? GestureDetector(
                    onTap: () {
                      setState(() {
                        isOpen = !isOpen;
                      });
                    },
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          vertical: 8,
                          horizontal: 8,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          color: colorScheme.surface,
                          border: Border.all(color: colorScheme.tertiary),
                        ),
                        child: FaIcon(actionIcon, size: 15),
                      ),
                    ),
                  )
                : Container(),
          ],
        ),
        widget.content != null
            ? isOpen
                  ? Padding(
                      padding: const EdgeInsets.only(top: 10.0),
                      child: widget.content!,
                    )
                  : SizedBox.shrink()
            : SizedBox.shrink(),
      ],
    );
  }
}
