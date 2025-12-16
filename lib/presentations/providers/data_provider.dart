import 'package:anchor_point_app/data/models/anchor_point_model.dart';
import 'package:anchor_point_app/data/models/request_model.dart';
import 'package:anchor_point_app/data/models/user_profile.dart';
import 'package:anchor_point_app/data/sources/anchor_point_source.dart';
import 'package:anchor_point_app/data/sources/request_source.dart';
import 'package:anchor_point_app/data/sources/user_info_source.dart';
import 'package:anchor_point_app/presentations/screens/main_screens/anchor_point_screen/controllers/anchor_point_controller.dart';
import 'package:flutter/material.dart';
import 'package:persistent_bottom_nav_bar/persistent_bottom_nav_bar.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DataProvider extends ChangeNotifier {
  bool _reloading = false;
  List<AnchorPoint> _anchorPoints = [];
  UserProfile? _userInfo;
  AnchorPointController? _currentAPController;
  final PersistentTabController _tabController = PersistentTabController();
  bool _tabVisible = true;
  String? _error;
  List<RequestModel> _requestsForUser = [];

  // Getters
  List<AnchorPoint> get anchorPoints => List.unmodifiable(_anchorPoints);
  bool get isReloading => _reloading;
  UserProfile? get userInfo => _userInfo;
  AnchorPointController get currentAPController {
    _currentAPController ??= AnchorPointController();
    return _currentAPController!;
  }

  PersistentTabController get tabController => _tabController;
  bool get tabVisible => _tabVisible;
  String? get error => _error;
  List<RequestModel> get requestsForUser => _requestsForUser;

  /// Loads all necessary data for the app
  Future<void> loadAllData() async {
    try {
      _setReloading(true);
      _error = null;

      await loadOwnedAnchorPoints();
      await loadUserInfo();
      await pickFirstAnchorPoint();
      debugPrint("req");
      await loadRequests();
      debugPrint("req1");
    } catch (e) {
      _error = 'Failed to load data: $e';
      debugPrint('Error loading all data: $e');
    } finally {
      _setReloading(false);
    }
  }

  /// Picks the first anchor point to display (pinned or first in list)
  Future<void> pickFirstAnchorPoint() async {
    if (_anchorPoints.isEmpty) {
      await setNewCurrentAnchorPoint(null);
      return;
    }

    // Try to use pinned anchor point if available
    if (_userInfo?.pinnedAnchorPointId != null) {
      try {
        final pinnedAP = _anchorPoints.firstWhere(
          (ap) => ap.id == _userInfo!.pinnedAnchorPointId,
          orElse: () => _anchorPoints.first,
        );
        await setNewCurrentAnchorPoint(pinnedAP);
      } catch (e) {
        debugPrint('Error finding pinned anchor point: $e');
        await setNewCurrentAnchorPoint(_anchorPoints.first);
      }
    } else {
      await setNewCurrentAnchorPoint(_anchorPoints.first);
    }
  }

  /// Sets a new current anchor point and waits for initialization
  Future<void> setNewCurrentAnchorPoint(AnchorPoint? newAnchorPoint) async {
    try {
      await currentAPController.setNewAnchorPoint(newAnchorPoint);
      notifyListeners();
    } catch (e) {
      _error = 'Failed to set anchor point: $e';
      debugPrint('Error setting new anchor point: $e');
      notifyListeners();
    }
  }

  /// Changes the current tab
  void changeCurrentTab(int value) {
    _tabController.jumpToTab(value);
    notifyListeners();
  }

  Future<void> updateOnlyCurrentAnchorPoint() async {
    await loadOwnedAnchorPoints();
    int currentId = _currentAPController!.currentAnchorPoint!.id;
    await setNewCurrentAnchorPoint(
      _anchorPoints.firstWhere((ap) => ap.id == currentId),
    );
  }

  /// Updates the pinned anchor point for the user
  Future<void> updatePinnedAnchorPoint(int anchorPointId) async {
    try {
      await SupabaseUserInfoSource().updatePinnedAp(anchorPointId);
      await loadUserInfo();
    } catch (e) {
      _error = 'Failed to update pinned anchor point: $e';
      debugPrint('Error updating pinned anchor point: $e');
      notifyListeners();
    }
  }

  Future<void> loadRequests() async {
    List<RequestModel> requests = [];
    final response = await SupabaseRequestSource().getRequestsForUser(
      Supabase.instance.client.auth.currentUser!.id,
    );

    requests = response.map((json) => RequestModel.fromJson(json)).toList();
    requests.forEach((request) {
      request.getRequesterAndAnchorPoint();
      request.textRequest.getUserName();
      request.audioRequest.getUserName();
    });
    _requestsForUser = requests;

    notifyListeners();
  }

  /// Loads user profile information
  Future<void> loadUserInfo() async {
    try {
      final response = await SupabaseUserInfoSource().getUserInfo();
      _userInfo = UserProfile.fromJson(response);
      notifyListeners();
    } catch (e) {
      _error = 'Failed to load user info: $e';
      debugPrint('Error loading user info: $e');
      notifyListeners();
    }
  }

  /// Loads all anchor points owned by the user
  Future<void> loadOwnedAnchorPoints() async {
    try {
      final response = await SupabaseAnchorPointSource().getAllAnchorPoints();
      _anchorPoints = await Future.wait(
        response.map((json) => AnchorPoint.fromJsonAsync(json)),
      );
      notifyListeners();
    } catch (e) {
      _error = 'Failed to load anchor points: $e';
      debugPrint('Error loading anchor points: $e');
      notifyListeners();
    }
  }

  /// Refreshes a specific anchor point in the list
  Future<void> refreshAnchorPoint(int anchorPointId) async {
    try {
      final response = await SupabaseAnchorPointSource().getAnchorPoint(
        anchorPointId,
      );
      final updatedAP = await AnchorPoint.fromJsonAsync(response);

      final index = _anchorPoints.indexWhere((ap) => ap.id == anchorPointId);
      if (index != -1) {
        _anchorPoints[index] = updatedAP;

        // Update current controller if this is the active anchor point
        if (currentAPController.currentAnchorPoint?.id == anchorPointId) {
          await setNewCurrentAnchorPoint(updatedAP);
        } else {
          notifyListeners();
        }
      }
    } catch (e) {
      _error = 'Failed to refresh anchor point: $e';
      debugPrint('Error refreshing anchor point: $e');
      notifyListeners();
    }
  }

  /// Changes tab bar visibility
  void changeTabVisibility(bool newState) {
    if (_tabVisible != newState) {
      _tabVisible = newState;
      notifyListeners();
    }
  }

  /// Clears all data (e.g., on logout)
  void clearData() {
    _anchorPoints.clear();
    _userInfo = null;
    _error = null;
    _reloading = false;
    _tabVisible = true;
    _currentAPController?.clearData();
    notifyListeners();
  }

  /// Internal method to set reloading state
  void _setReloading(bool state) {
    if (_reloading != state) {
      _reloading = state;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _currentAPController?.dispose();
    _tabController.dispose();
    super.dispose();
  }
}
