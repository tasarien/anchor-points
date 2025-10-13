import 'package:anchor_point_app/data/sources/anchor_point_source.dart';
import 'package:anchor_point_app/presentations/providers/data_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AnchorPointScreen extends StatelessWidget {
  const AnchorPointScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    DataProvider appData = context.watch<DataProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('Anchor Point')),
      body: appData.getAnchorPoints.first.buildAPWidget()
    );
  }
}
