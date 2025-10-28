import 'package:anchor_point_app/presentations/widgets/global/whole_button.dart';
import 'package:anchor_point_app/presentations/widgets/global/whole_symbol.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

Future<T?> showCraftingBottomSheet<T>(
  BuildContext context, {

  bool isDismissible = true,
  bool enableDrag = true,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    isDismissible: isDismissible,
    enableDrag: enableDrag,
    showDragHandle: true,
    builder: (ctx) => _CraftingBottomSheetContainer(),
  );
}

class _CraftingBottomSheetContainer extends StatelessWidget {
  const _CraftingBottomSheetContainer({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    ColorScheme colorScheme = Theme.of(context).colorScheme;
    Widget choiceCard(String text, Widget leading, Function? onTap) {
      return GestureDetector(
        onTap: () {},
        child: Card(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: Row(
              spacing: 20,
              children: [
                leading,
                Expanded(
                  child: Text(
                    text,
                    softWrap: true,
                    overflow: TextOverflow.visible,
                  ),
                ),
                FaIcon(FontAwesomeIcons.chevronRight),
              ],
            ),
          ),
        ),
      );
    }

    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      width: double.infinity,
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: SingleChildScrollView(
          child: Column(
            spacing: 10,
            children: [
              Text(
                "Now it is time to finish crafting of Anchor Point by someone else. You can: ",
              ),
              choiceCard(
                "Ask a companion for writing & recording Anchor Point body.",

                Row(
                  children: [
                    WholeSymbol(symbol: "🧍", size: Size(60, 60)),
                    Column(
                      children: [
                        WholeSymbol(
                          icon: FontAwesomeIcons.pencil,
                          size: Size(30, 30),
                        ),
                        WholeSymbol(
                          icon: FontAwesomeIcons.microphone,
                          size: Size(30, 30),
                        ),
                      ],
                    ),
                  ],
                ),
                null,
              ),
              Text("or"),
              choiceCard(
                "Ask companion only for writing. Artificial companion will do the rest.",
                Row(
                  children: [
                    WholeSymbol(symbol: "🧍", size: Size(60, 60)),
                    Column(
                      children: [
                        WholeSymbol(
                          icon: FontAwesomeIcons.pencil,
                          size: Size(30, 30),
                        ),
                        WholeSymbol(
                          icon: FontAwesomeIcons.wind,
                          size: Size(30, 30),
                        ),
                      ],
                    ),
                  ],
                ),
                null,
              ),
              Text("or"),
              choiceCard(
                "Ask human companion to record, what artificial companion will prepare.",

                Row(
                  children: [
                    WholeSymbol(symbol: "🧍", size: Size(60, 60)),
                    Column(
                      children: [
                        WholeSymbol(
                          icon: FontAwesomeIcons.wind,
                          size: Size(30, 30),
                        ),
                        WholeSymbol(
                          icon: FontAwesomeIcons.microphone,
                          size: Size(30, 30),
                        ),
                      ],
                    ),
                  ],
                ),
                null,
              ),
              Text("or"),
              choiceCard(
                "Rely entirely on artifical companion. It's quicker, but less humane.",
                Row(
                  children: [
                    WholeSymbol(
                      icon: FontAwesomeIcons.wind,
                      size: Size(60, 60),
                    ),
                  ],
                ),
                null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
