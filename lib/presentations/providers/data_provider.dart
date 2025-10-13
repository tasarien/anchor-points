import 'package:anchor_point_app/data/models/anchor_point_model.dart';
import 'package:anchor_point_app/data/sources/anchor_point_source.dart';
import 'package:flutter/material.dart';

class DataProvider extends ChangeNotifier {
  List<AnchorPoint> _anchorPoints = [];


  List<AnchorPoint> get getAnchorPoints => _anchorPoints;

  DataProvider() {
    _loadOwnedAnchorPoints();
  }

  Future<void> _loadOwnedAnchorPoints() async {
    var response = await SupabaseAnchorPointSource().getAllAnchorPoints();
    if (response != null) {
      response.map((json) => _anchorPoints.add(AnchorPoint.fromJson(json)));
    }
    notifyListeners();
  }

 
}
