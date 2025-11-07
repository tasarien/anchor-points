import 'package:anchor_point_app/data/models/anchor_point_model.dart';
import 'package:anchor_point_app/presentations/providers/data_provider.dart';
import 'package:anchor_point_app/presentations/screens/main_screens/anchor_point_screen.dart';
import 'package:anchor_point_app/presentations/widgets/global/whole_button.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';

class AnchorPointWidgetSmall extends StatefulWidget {
  final AnchorPoint anchorPoint;
  const AnchorPointWidgetSmall({Key? key, required this.anchorPoint})
    : super(key: key);

  @override
  _AnchorPointWidgetSmallState createState() => _AnchorPointWidgetSmallState();
}

class _AnchorPointWidgetSmallState extends State<AnchorPointWidgetSmall> {
  @override
  Widget build(BuildContext context) {
    ColorScheme colorScheme = Theme.of(context).colorScheme;
    DataProvider appData = context.watch<DataProvider>();
    bool pinned =
        widget.anchorPoint.id == appData.userInfo!.pinnedAnchorPointId;
    return Container(
      margin: EdgeInsets.symmetric(vertical: 10),
      child: Stack(
        alignment: Alignment.centerLeft,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: ListTile(
                leading: SizedBox(width: 100, height: 100),
                title: Text(widget.anchorPoint.name!),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    WholeButton(
                      onPressed: () {
                        appData.updatePinnedAnchorPoint(widget.anchorPoint.id);
                      },
                      icon: pinned
                          ? FontAwesomeIcons.solidBookmark
                          : FontAwesomeIcons.bookmark,
                    ),
                    IconButton(
                      onPressed: () {
                        appData.changeCurrentAnchorPoint(widget.anchorPoint);
                        debugPrint(appData.currentAnchorPoint!.name);
                        appData.changeCurrentTab(0);
                      },
                      icon: FaIcon(FontAwesomeIcons.chevronRight),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Container(
            width: 100,
            height: 100,
            clipBehavior: Clip.hardEdge,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: colorScheme.tertiary,
                width: 2,
                strokeAlign: BorderSide.strokeAlignOutside,
              ),
            ),
            child: widget.anchorPoint.imageUrl != null
                ? Image.network(widget.anchorPoint.imageUrl!, fit: BoxFit.fill)
                : Image.asset('assets/images/empty_landscape.png'),
          ),
        ],
      ),
    );
  }
}
