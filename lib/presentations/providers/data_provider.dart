import 'package:anchor_point_app/data/models/anchor_point_model.dart';
import 'package:anchor_point_app/data/sources/anchor_point_source.dart';
import 'package:flutter/material.dart';

class DataProvider extends ChangeNotifier {
  bool _reloading = false;
  List<AnchorPoint> _anchorPoints = [];

  List<AnchorPoint> get getAnchorPoints => _anchorPoints;
  bool get isReloading => _reloading;

  DataProvider() {
    loadOwnedAnchorPoints();
  }

  reloadAnchorPoints() {
    loadOwnedAnchorPoints();
  }

  Future<void> loadOwnedAnchorPoints() async {
    _reloading = true;
    notifyListeners();
    debugPrint('1');
    var response = await SupabaseAnchorPointSource().getAllAnchorPoints();
    debugPrint(response.toString());
    response
        .map((json) => _anchorPoints.add(AnchorPoint.fromJson(json)))
        .toList();

    debugPrint(_anchorPoints.toString());
    _reloading = false;
    notifyListeners();
  }
}
