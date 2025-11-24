import 'package:flutter/material.dart';
import 'package:anchor_point_app/presentations/providers/data_provider.dart';

class DemoAnchorPointScreen extends StatelessWidget {
  final DataProvider appData;
  const DemoAnchorPointScreen({Key? key, required this.appData}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Text("Demo anchor point"),
    );
  }
}
