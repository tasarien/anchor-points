import 'package:anchor_point_app/data/models/anchor_point_model.dart';
import 'package:anchor_point_app/data/models/user_profile.dart';
import 'package:anchor_point_app/data/sources/anchor_point_source.dart';
import 'package:anchor_point_app/data/sources/user_info_source.dart';
import 'package:flutter/material.dart';

class DataProvider extends ChangeNotifier {
  bool _reloading = false;
  List<AnchorPoint> _anchorPoints = [];
  UserProfile? _userInfo;

  List<AnchorPoint> get getAnchorPoints => _anchorPoints;
  bool get isReloading => _reloading;
  UserProfile? get userInfo => _userInfo;

  loadAllData() async {
    await loadOwnedAnchorPoints();
    await loadUserInfo();
  }

  Future<void> updatePinnedAnchorPoint(int anchorPointId) async {
    await SupabaseUserInfoSource().updatePinnedAp(anchorPointId);
    await loadUserInfo();
  }

  Future<void> loadUserInfo() async {
    _reloading = true;
    notifyListeners();
    var response = await SupabaseUserInfoSource().getUserInfo();

    _userInfo = UserProfile.fromJson(response);

    _reloading = false;
    notifyListeners();
  }

  void clearData() {
    _reloading = false;
    _anchorPoints = [];
    _userInfo = null;
    notifyListeners();
  }

  Future<void> loadOwnedAnchorPoints() async {
    _reloading = true;

    notifyListeners();

    var response = await SupabaseAnchorPointSource().getAllAnchorPoints();
    _anchorPoints = [];
    response
        .map((json) => _anchorPoints.add(AnchorPoint.fromJson(json)))
        .toList();
    _reloading = false;
    notifyListeners();
  }
}
