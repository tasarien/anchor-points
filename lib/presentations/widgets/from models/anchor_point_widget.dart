import 'package:anchor_point_app/data/models/anchor_point_model.dart';
import 'package:flutter/material.dart';

class AnchorPointWidget extends StatefulWidget {
  final AnchorPoint anchorPoint;
  const AnchorPointWidget({ Key? key, required this.anchorPoint }) : super(key: key);

  @override
  _AnchorPointWidgetState createState() => _AnchorPointWidgetState();
}

class _AnchorPointWidgetState extends State<AnchorPointWidget> {
  @override
  Widget build(BuildContext context) {
    return Text(
      widget.anchorPoint.name ?? "No name"
    );
  }
}