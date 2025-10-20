import 'package:anchor_point_app/core/localizations/app_localizations.dart';
import 'package:anchor_point_app/core/utils/anchor_point_icons.dart';
import 'package:anchor_point_app/data/models/anchor_point_model.dart';
import 'package:anchor_point_app/data/sources/anchor_point_source.dart';
import 'package:anchor_point_app/presentations/providers/data_provider.dart';
import 'package:anchor_point_app/presentations/screens/create_anchor_point_screen.dart';
import 'package:anchor_point_app/presentations/screens/main_screens/other_AP_screens.dart';
import 'package:anchor_point_app/presentations/widgets/global/info_box.dart';
import 'package:anchor_point_app/presentations/widgets/global/loading_indicator%20copy.dart';
import 'package:anchor_point_app/presentations/widgets/global/whole_button.dart';
import 'package:anchor_point_app/presentations/widgets/global/whole_popup.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'package:step_progress/step_progress.dart';

class AnchorPointScreen extends StatefulWidget {
  final AnchorPoint anchorPoint;
  const AnchorPointScreen({Key? key, required this.anchorPoint})
    : super(key: key);

  @override
  State<AnchorPointScreen> createState() => _AnchorPointScreenState();
}

class _AnchorPointScreenState extends State<AnchorPointScreen> {
  bool _loading = false;
  bool _saveLoading = false;
  bool _editMode = false;
  bool _isAtBottom = true;
  bool _progressCardOpened = true;
  StepProgressController _progressController = StepProgressController(totalSteps: 3);
  ScrollController _scrollController = ScrollController();

  TextEditingController _titleController = TextEditingController();
  TextEditingController _descriptionController = TextEditingController();

  String getText(String text) {
    return AppLocalizations.of(context).translate(text);
  }

  @override
  void initState() {
    super.initState();
    fillInputFields();
    _scrollController.addListener(_scrollListener);

    // Check initial state after layout
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _checkIfAtBottom();
      await Future.delayed(Duration(milliseconds: 500));
      stepByStatus();
    });
  }

  void _checkIfAtBottom() {
    if (!_scrollController.hasClients) return;

    if (_scrollController.position.maxScrollExtent == 0) {
      // Not scrollable - already at "bottom"
      setState(() {
        _isAtBottom = true;
      });
    } else {
      _scrollListener();
    }
  }

  void _scrollListener() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent) {
      setState(() {
        _isAtBottom = true;
      });
    } else {
      setState(() {
        _isAtBottom = false;
      });
    }
  }

  fillInputFields() {
    _titleController.text = widget.anchorPoint.name!;
    _descriptionController.text = widget.anchorPoint.description ?? "";
  }

  void turnOnEditMode() {
    setState(() {
      _editMode = true;
    });
  }

  void saveEditedChanges(DataProvider appData) async {
    setState(() {
      _saveLoading = true;
    });

    Map<String, dynamic> updatedAnchorPoint = {};

    if (widget.anchorPoint.name != _titleController.text) {
      updatedAnchorPoint['name'] = _titleController.text;
    }

    if (widget.anchorPoint.description != _descriptionController.text) {
      updatedAnchorPoint['description'] = _descriptionController.text;
    }

    await SupabaseAnchorPointSource().updateAnchorPoint(
      widget.anchorPoint.id,
      updatedAnchorPoint,
    );

    setState(() {
      _editMode = false;
      _saveLoading = false;
    });

    appData.loadOwnedAnchorPoints();
    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (context) => OtherAPScreen()));

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(getText('anchor_point_succesfully_updated'))),
    );
  }

  void revertChanges() {
    fillInputFields();
    setState(() {
      _editMode = false;
    });
  }

  void stepByStatus() async {
   
    int getIterationsFromProgress() {
      switch (widget.anchorPoint.status) {
        case AnchorPointStatus.created:
          return 0;
        case AnchorPointStatus.drafted:
          return 1;
        case AnchorPointStatus.crafted:
          return 2;
        case AnchorPointStatus.archived:
          return -1;
      }
    }

    int iterations = getIterationsFromProgress();

    setState(() {
      _progressCardOpened = true;
    });
    for(int i = 0; i <= iterations; i++) {
      await Future.delayed(Durations.medium1);
      setState(() {
        _progressController.nextStep();
      });
    }
await Future.delayed(Duration(seconds: 2));
    setState(() {
      _progressCardOpened = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final appData = context.watch<DataProvider>();

    Widget draftingSection() {
      return Card(child: Text("Time to draft"));
    }

    Widget craftingSection() {
      return Card();
    }

    Widget readySection() {
      return Card();
    }

    Widget archivedSection() {
      return Card();
    }

    ColorScheme colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        actions: [
          if (_editMode)
            WholeButton(
              onPressed: () {
                revertChanges();
              },
              text: getText('cancel'),
              suggested: false,
              wide: true,
            ),
          SizedBox(width: 10),
          if (_editMode)
            WholeButton(
              onPressed: () {
                saveEditedChanges(appData);
              },
              icon: FontAwesomeIcons.floppyDisk,
              text: getText('save_changes'),

              wide: true,
            ),
          if (!_editMode)
            WholePopup(
              content: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  WholeButton(
                    icon: FontAwesomeIcons.pen,
                    text: getText('edit'),
                    onPressed: () {
                      turnOnEditMode();
                      Navigator.of(context).pop();
                    },
                  ),
                  WholeButton(
                    icon: FontAwesomeIcons.trash,
                    text: getText('delete'),
                    onPressed: () {
                      Navigator.of(context).pop();
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          content: Text(
                            getText('anchor_point_screen_delete_dialog'),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () {
                                Navigator.of(context).pop();
                              },
                              child: Text(getText('cancel')),
                            ),
                            _loading
                                ? LoadingIndicator()
                                : TextButton(
                                    onPressed: () async {
                                      setState(() {
                                        _loading = true;
                                      });
                                      await SupabaseAnchorPointSource()
                                          .deleteAnchorPoint(
                                            widget.anchorPoint.id,
                                          );
                                      setState(() {
                                        _loading = false;
                                      });
                                      Navigator.of(context).pop();
                                      appData.loadOwnedAnchorPoints();
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            getText('anchor_point_deleted'),
                                          ),
                                        ),
                                      );
                                    },
                                    child: Text(getText('sure_delete')),
                                  ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
              child: SizedBox(
                width: 60,
                height: 60,
                child: Icon(FontAwesomeIcons.ellipsisVertical),
              ),
            ),
        ],
      ),
      body: Center(
        child: _saveLoading
            ? LoadingIndicator()
            : Stack(
                children: [
                  SingleChildScrollView(
                    controller: _scrollController,
                    child: Column(
                      spacing: 0,
                      children: [
                         GestureDetector(
                          onTap: () {
                            setState(() {
                              _progressCardOpened = !_progressCardOpened;
                            });
                          },
                           child: Card(
                            
                             child: Padding(
                               padding: const EdgeInsets.all(8.0),
                               child: AnimatedCrossFade(
                                
                                duration: Durations.long1,
                                crossFadeState: _progressCardOpened ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                                  firstChild: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      FaIcon(AnchorPointIcons.anchor_point_step1),
                                      FaIcon(AnchorPointIcons.anchor_point_step2),
                                      FaIcon(AnchorPointIcons.anchor_point_step3),
                                    ],
                                  ),
                                 secondChild: Column(
                                   children: [
                                     StepProgress(
                                              totalSteps: 3,
                                              controller: _progressController,
                                              
                                              width: 240,
                                              stepNodeSize: 40,
                                              theme: StepProgressThemeData(
                                               
                                                // stepNodeStyle: StepNodeStyle(
                                                //   activeForegroundColor: Colors.transparent,
                                                //   defaultForegroundColor: Colors.transparent
                                                // ),
                                                stepAnimationDuration: Durations.long1,
                                                defaultForegroundColor: 
                                                    Theme.of(context).scaffoldBackgroundColor,
                                                activeForegroundColor:
                                                    colorScheme.tertiary,
                                              ),
                                              
                                              nodeLabelBuilder: (index, completedStepIndex) {
                                            
                                                  String title ()  {
                                                    switch (index) {
                                                  case 0:
                                                   return getText('ap_status_1');
                                                    
                                                  case 1:
                                                    return getText('ap_status_2');
                                                    
                                                  case 2:
                                                   return getText('ap_status_3');
                                                  default: return "";

                                                 
                                                }
                                                  }

                                                  return Text(title(), style: TextStyle(color: index > completedStepIndex ? colorScheme.tertiary : colorScheme.onSurface),);
                                                
                                              },
                                              nodeIconBuilder: (index, completedStepIndex) {
                                                icon() {
                                                  switch (index) {
                                                  case 0:
                                                   return AnchorPointIcons.anchor_point_step1;
                                                    
                                                  case 1:
                                                    return AnchorPointIcons.anchor_point_step2;
                                                    
                                                  case 2:
                                                   return AnchorPointIcons.anchor_point_step3;
                                                 
                                                }
                                                }
                                                return SizedBox(
                                                  height: 80,
                                                  child: Center(
                                                    child: WholeButton(icon: icon(), disabled: index > completedStepIndex)
                                                  
                                                  ),
                                                );
                                              },
                                            ),
                                   ],
                                 ),
                               ),
                             ),
                           ),
                         ),
                        Container(
                          width: 300,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(30),
                                child: Card(
                                  child: Container(width: 270, height: 270),
                                ),
                              ),
                              ClipOval(
                                child: Image.asset(
                                  'assets/images/auth_gate.png', // <-- Replace with your image asset
                                  width: 280,
                                  height: 280,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              Transform.translate(
                                offset: Offset(0, 100),
                                child: SizedBox(
                                  width: 220,
                                  child: TextField(
                                    controller: _titleController,
                                    textAlign: TextAlign.center,
                                    readOnly: !_editMode,
                                    enableInteractiveSelection: _editMode,

                                    maxLength: _editMode ? 24 : null,
                                    decoration: InputDecoration(
                                      fillColor: colorScheme.surface,
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                        borderSide: BorderSide(
                                          color: _editMode
                                              ? colorScheme.error
                                              : colorScheme.tertiary,
                                          width: _editMode ? 2 : 1,
                                        ),
                                      ),
                                      focusColor: _editMode
                                          ? colorScheme.error
                                          : colorScheme.tertiary,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        if (widget.anchorPoint.status ==
                            AnchorPointStatus.created)
                          draftingSection(),
                        if (widget.anchorPoint.status ==
                            AnchorPointStatus.drafted)
                          craftingSection(),
                        if (widget.anchorPoint.status ==
                            AnchorPointStatus.crafted)
                          readySection(),
                        if (widget.anchorPoint.status ==
                            AnchorPointStatus.archived)
                          archivedSection(),
                        Container(
                          margin: EdgeInsets.symmetric(horizontal: 20),
                          child: Card(
                            child: SizedBox(
                              child: TextField(
                                controller: _descriptionController,
                                textAlign: TextAlign.center,
                                readOnly: !_editMode,
                                minLines: 1,
                                maxLines: 10,
                                enableInteractiveSelection: _editMode,
                                decoration: InputDecoration(
                                  fillColor: colorScheme.surface,
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: BorderSide(
                                      color: _editMode
                                          ? colorScheme.error
                                          : colorScheme.tertiary,
                                      width: _editMode ? 2 : 1,
                                    ),
                                  ),
                                  focusColor: _editMode
                                      ? colorScheme.error
                                      : colorScheme.tertiary,
                                  hintText: _descriptionController.text.isEmpty
                                      ? getText('no_desc_provided')
                                      : _descriptionController.text,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  Align(
                    alignment: Alignment.bottomCenter,
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: AnimatedOpacity(
                        duration: Duration(milliseconds: 800),
                        opacity: _isAtBottom ? 0 : 1,
                        child: FaIcon(FontAwesomeIcons.chevronDown)
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
