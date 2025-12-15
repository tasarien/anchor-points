import 'package:flutter/material.dart';
import 'package:step_progress/step_progress.dart';
import 'package:anchor_point_app/presentations/providers/data_provider.dart';
import 'package:anchor_point_app/data/sources/anchor_point_source.dart';
import 'package:anchor_point_app/data/models/anchor_point_model.dart';

class AnchorPointController extends ChangeNotifier {
  // UI controllers
  final ScrollController scrollController = ScrollController();
  final StepProgressController progressController = StepProgressController(
    totalSteps: 3,
  );

  // Main data container as model of Anchor Point
  AnchorPoint? _anchorPoint;

  // Flags
  bool _loading = false;
  bool _saveLoading = false;
  bool _editMode = false;
  bool _isAtBottom = true;
  bool _progressCardOpened = true;
  bool _step1Present = false;
  bool _step2Present = false;
  bool _step3Present = false;
  bool _statusArchived = false;
  bool _isInitialized = false;

  // Section keys
  final GlobalKey draftingSectionKey = GlobalKey();
  final GlobalKey craftingSectionKey = GlobalKey();
  final GlobalKey readySectionKey = GlobalKey();
  final GlobalKey progressCardKey = GlobalKey();

  // Inputs
  final TextEditingController titleController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  String? _imageUrl;

  // Getters
  AnchorPoint? get currentAnchorPoint => _anchorPoint;
  bool get loading => _loading;
  bool get saveLoading => _saveLoading;
  bool get editMode => _editMode;
  bool get isAtBottom => _isAtBottom;
  bool get isProgressCardOpened => _progressCardOpened;
  bool get step1Present => _step1Present;
  bool get step2Present => _step2Present;
  bool get step3Present => _step3Present;
  bool get statusArchived => _statusArchived;
  String? get imageUrl => _imageUrl;

  void setLoading(bool newState) {
    _loading = newState;
    notifyListeners();
  }

  /// Sets a new anchor point and initializes the controller
  Future<void> setNewAnchorPoint(AnchorPoint? newAnchorPoint) async {
    _clearData();
    _anchorPoint = newAnchorPoint;
    scrollTo(progressCardKey);
    if (_anchorPoint != null) {
      await _initialize();
    }

    notifyListeners();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initProgressFromStatus();
    });
  }

  /// Initializes the controller with the current anchor point data
  Future<void> _initialize() async {
    if (_anchorPoint == null || _isInitialized) return;

    _fillFields();
    _setProgressSteps();
    _setupScrollListener();

    _isInitialized = true;
  }

  /// Fills the input fields with anchor point data
  void _fillFields() {
    if (_anchorPoint == null) return;

    titleController.text = _anchorPoint!.name ?? '';
    descriptionController.text = _anchorPoint!.description ?? '';
    _imageUrl = _anchorPoint!.imageUrl;
  }

  /// Sets up the scroll listener (removes existing one first to prevent duplicates)
  void _setupScrollListener() {
    scrollController.removeListener(_scrollListener);
    scrollController.addListener(_scrollListener);
  }

  /// Listens to scroll position to determine if at bottom
  void _scrollListener() {
    if (!scrollController.hasClients) return;

    final atBottom =
        scrollController.position.pixels >=
        scrollController.position.maxScrollExtent;

    if (atBottom != _isAtBottom) {
      _isAtBottom = atBottom;
      notifyListeners();
    }
  }

  // Set progress steps basing on status
  void _setProgressSteps() {
    if (_anchorPoint == null) return;

    final status = _anchorPoint!.status;

    switch (status) {
      case AnchorPointStatus.created:
        _step1Present = true;
        _step2Present = false;
        _step3Present = false;
        _statusArchived = false;
        break;
      case AnchorPointStatus.drafted:
        _step1Present = true;
        _step2Present = true;
        _step3Present = false;
        _statusArchived = false;
        break;
      case AnchorPointStatus.crafted:
        _step1Present = true;
        _step2Present = true;
        _step3Present = true;
        _statusArchived = false;
        break;
      case AnchorPointStatus.archived:
        _statusArchived = true;
        return; // Don't animate for archived
    }
  }

  /// Initializes progress indicators based on anchor point status
  Future<void> _initProgressFromStatus() async {
    // Wait a bit before starting
    await Future.delayed(const Duration(milliseconds: 500));
    if (!_progressCardOpened) {
      changeProgressCardState(true);
    }

    // Animate the progress steps
    await _animateProgressSteps();

    // Show final state
    await Future.delayed(const Duration(milliseconds: 2000));

    // Close the card
    changeProgressCardState(false);
  }

  /// Animates the progress steps based on current status
  Future<void> _animateProgressSteps() async {
    final stepsToShow =
        (_step1Present ? 1 : 0) +
        (_step2Present ? 1 : 0) +
        (_step3Present ? 1 : 0);

    // Start from step 0, animate to the current step
    for (int i = 1; i < stepsToShow; i++) {
      await Future.delayed(const Duration(milliseconds: 500));
      progressController.nextStep();
      notifyListeners();
    }
  }

  /// Toggles edit mode on/off
  void toggleEditMode() {
    _editMode = !_editMode;
    notifyListeners();
  }

  /// Saves changes to the anchor point
  Future<void> saveChanges(BuildContext context) async {
    if (_anchorPoint == null) return;

    _saveLoading = true;
    notifyListeners();

    try {
      final Map<String, dynamic> updates = {};

      // Check for changes and build update map
      if (_anchorPoint!.name != titleController.text) {
        updates['name'] = titleController.text;
      }
      if (_anchorPoint!.description != descriptionController.text) {
        updates['description'] = descriptionController.text;
      }
      if (_anchorPoint!.imageUrl != _imageUrl) {
        updates['image_url'] = _imageUrl;
      }

      // Only update if there are changes
      if (updates.isNotEmpty) {
        await SupabaseAnchorPointSource().updateAnchorPoint(
          _anchorPoint!.id,
          updates,
        );

        // Update local model with new values
        _anchorPoint = _anchorPoint!.copyWith(
          name: titleController.text,
          description: descriptionController.text,
          imageUrl: _imageUrl,
        );
      }

      _editMode = false;
    } catch (e) {
      // Handle error - you might want to show a snackbar or dialog
      debugPrint('Error saving changes: $e');
      rethrow;
    } finally {
      _saveLoading = false;
      notifyListeners();
    }
  }

  /// Reverts changes and exits edit mode
  void revertChanges() {
    _fillFields();
    _editMode = false;
    notifyListeners();
  }

  /// Sets the image URL
  void setImageUrl(String? url) {
    _imageUrl = url;
    notifyListeners();
  }

  /// Scrolls to a specific section using its global key
  void scrollTo(GlobalKey key) {
    if (key.currentContext == null) return;

    Scrollable.ensureVisible(
      key.currentContext!,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
      alignment: 0.5,
    );
  }

  /// Changes the progress card state (opened/closed)
  void changeProgressCardState(bool state) {
    _progressCardOpened = state;
    notifyListeners();
  }

  /// Clears all data and resets to initial state
  void _clearData() {
    titleController.clear();
    descriptionController.clear();
    progressController.setCurrentStep(0);

    _loading = false;
    _saveLoading = false;
    _editMode = false;
    _isAtBottom = true;
    _progressCardOpened = true;
    _step1Present = false;
    _step2Present = false;
    _step3Present = false;
    _statusArchived = false;
    _isInitialized = false;
    _imageUrl = null;
    _anchorPoint = null;
  }

  /// Public method to manually clear data if needed
  void clearData() {
    _clearData();
    notifyListeners();
  }

  @override
  void dispose() {
    scrollController.removeListener(_scrollListener);
    scrollController.dispose();
    titleController.dispose();
    descriptionController.dispose();
    progressController.dispose();
    super.dispose();
  }
}
