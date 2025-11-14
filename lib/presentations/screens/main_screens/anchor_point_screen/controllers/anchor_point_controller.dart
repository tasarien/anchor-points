import 'package:flutter/material.dart';
import 'package:step_progress/step_progress.dart';
import 'package:anchor_point_app/presentations/providers/data_provider.dart';
import 'package:anchor_point_app/data/sources/anchor_point_source.dart';
import 'package:anchor_point_app/data/models/anchor_point_model.dart';
import 'package:flutter/widgets.dart';

class AnchorPointController extends ChangeNotifier {
  final DataProvider appData;

  // UI controllers
  final ScrollController scrollController = ScrollController();
  final StepProgressController progressController = StepProgressController(
    totalSteps: 3,
  );

  // Flags
  bool loading = false;
  bool saveLoading = false;
  bool editMode = false;
  bool isAtBottom = true;
  bool progressCardOpened = true;
  bool step1Present = false;
  bool step2Present = false;
  bool step3Present = false;
  bool statusArchived = false;

  // Section keys
  GlobalKey draftingSectionKey = GlobalKey();
  GlobalKey craftingSectionKey = GlobalKey();
  GlobalKey readySectionKey = GlobalKey();
  // Inputs
  final TextEditingController titleController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  String? imageUrl;

  AnchorPointController(this.appData) {
    _init();
  }

  // Exposed getters with idiomatic names
  bool get saveLoadingFlag => saveLoading;

  void _init() {
    _fillFields();
    scrollController.addListener(_scrollListener);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _initProgressFromStatus();
    });
  }

  void _fillFields() {
    final ap = appData.currentAnchorPoint!;
    titleController.text = ap.name ?? '';
    descriptionController.text = ap.description ?? '';
    imageUrl = ap.imageUrl;
  }

  void toggleEditMode() {
    editMode = !editMode;
    notifyListeners();
  }

  void _scrollListener() {
    if (!scrollController.hasClients) return;

    final atBottom =
        scrollController.position.pixels >=
        scrollController.position.maxScrollExtent;
    if (atBottom != isAtBottom) {
      isAtBottom = atBottom;
      notifyListeners();
    }
  }

  Future<void> _initProgressFromStatus() async {
    final status = appData.currentAnchorPoint!.status;

    switch (status) {
      case AnchorPointStatus.created:
        step1Present = true;
        step2Present = false;
        step3Present = false;
        statusArchived = false;
        break;
      case AnchorPointStatus.drafted:
        step1Present = true;
        step2Present = true;
        step3Present = false;
        statusArchived = false;
        break;
      case AnchorPointStatus.crafted:
        step1Present = true;
        step2Present = true;
        step3Present = true;
        statusArchived = false;
        break;
      case AnchorPointStatus.archived:
        step1Present = true;
        step2Present = true;
        step3Present = true;
        statusArchived = true;
        break;
    }

    notifyListeners();

    // animate progress
    int stepsToShow =
        (step1Present ? 1 : 0) +
        (step2Present ? 1 : 0) +
        (step3Present ? 1 : 0);
    for (int i = 0; i < stepsToShow; i++) {
      await Future.delayed(const Duration(milliseconds: 350));
      progressController.nextStep();
      notifyListeners();
    }

    await Future.delayed(const Duration(milliseconds: 300));
    progressCardOpened = false;
    notifyListeners();
  }

  Future<void> saveChanges(BuildContext context) async {
    saveLoading = true;
    notifyListeners();

    final current = appData.currentAnchorPoint!;
    final Map<String, dynamic> updates = {};

    if (current.name != titleController.text)
      updates['name'] = titleController.text;
    if (current.description != descriptionController.text)
      updates['description'] = descriptionController.text;
    if (current.imageUrl != imageUrl) updates['image_url'] = imageUrl;

    if (updates.isNotEmpty) {
      await SupabaseAnchorPointSource().updateAnchorPoint(current.id, updates);
      await appData.loadOwnedAnchorPoints();
    }

    saveLoading = false;
    editMode = false;
    notifyListeners();
  }

  void revertChanges() {
    _fillFields();
    editMode = false;
    notifyListeners();
  }

  void setImageUrl(String? url) {
    imageUrl = url;
    notifyListeners();
  }

  // helpers for UI consumption
  void scrollTo(GlobalKey key) {
    if (key.currentContext == null) return;
    Scrollable.ensureVisible(
      key.currentContext!,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
      alignment: 0.5,
    );
  }

  void changeProgressCardState(bool state) {
    progressCardOpened = state;
    notifyListeners();
  }
}
