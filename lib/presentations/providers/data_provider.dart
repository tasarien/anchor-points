import 'package:anchor_point_app/data/models/anchor_point_model.dart';
import 'package:anchor_point_app/data/models/user_profile.dart';
import 'package:anchor_point_app/data/sources/anchor_point_source.dart';
import 'package:anchor_point_app/data/sources/user_info_source.dart';
import 'package:flutter/material.dart';
import 'package:persistent_bottom_nav_bar/persistent_bottom_nav_bar.dart';

class DataProvider extends ChangeNotifier {
  bool _reloading = false;
  List<AnchorPoint> _anchorPoints = [];
  UserProfile? _userInfo;
  AnchorPoint? _currentAnchorPoint;
  PersistentTabController _controller = PersistentTabController();

  List<AnchorPoint> get getAnchorPoints => _anchorPoints;
  bool get isReloading => _reloading;
  UserProfile? get userInfo => _userInfo;
  AnchorPoint? get currentAnchorPoint => _currentAnchorPoint;
  PersistentTabController get tabController => _controller;

  pickFirstAnchorPoint() {
    if (_anchorPoints.isEmpty) {
      changeCurrentAnchorPoint(null);
    } else {
      if (userInfo!.pinnedAnchorPointId != null) {
        changeCurrentAnchorPoint(
          getAnchorPoints.firstWhere(
            (element) => element.id == userInfo!.pinnedAnchorPointId,
          ),
        );
      } else {
        changeCurrentAnchorPoint(getAnchorPoints.first);
      }
    }
  }

  changeCurrentAnchorPoint(AnchorPoint? anchorPoint) {
    _currentAnchorPoint = anchorPoint;
    notifyListeners();
  }

  changeCurrentTab(int value) {
    _controller.jumpToTab(value);
    notifyListeners();
  }

  loadAllData() async {
    await loadOwnedAnchorPoints();
    await loadUserInfo();
    pickFirstAnchorPoint();
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
