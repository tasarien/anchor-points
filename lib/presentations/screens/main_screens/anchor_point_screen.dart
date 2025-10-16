import 'package:anchor_point_app/core/localizations/app_localizations.dart';
import 'package:anchor_point_app/core/utils/anchor_point_icons.dart';
import 'package:anchor_point_app/data/models/anchor_point_model.dart';
import 'package:anchor_point_app/data/sources/anchor_point_source.dart';
import 'package:anchor_point_app/presentations/providers/data_provider.dart';
import 'package:anchor_point_app/presentations/screens/create_anchor_point_screen.dart';
import 'package:anchor_point_app/presentations/screens/main_screens/other_AP_screens.dart';
import 'package:anchor_point_app/presentations/widgets/global/loading_indicator%20copy.dart';
import 'package:anchor_point_app/presentations/widgets/global/whole_button.dart';
import 'package:anchor_point_app/presentations/widgets/global/whole_popup.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';

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

  TextEditingController _titleController = TextEditingController();
  TextEditingController _descriptionController = TextEditingController();

  String getText(String text) {
    return AppLocalizations.of(context).translate(text);
  }

  @override
  void initState() {
    fillInputFields();
    super.initState();
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

  @override
  Widget build(BuildContext context) {
    final appData = context.watch<DataProvider>();

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
            : SingleChildScrollView(
                child: Column(
                  spacing: 20,
                  children: [
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
                    Container(
                      width: 300,
                      constraints: BoxConstraints(minHeight: 100),
                      child: Card(
                        child: SizedBox(
                          child: TextField(
                            controller: _descriptionController,
                            textAlign: TextAlign.center,
                            readOnly: !_editMode,
                            minLines: 1,
                            maxLines: 10,
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
      ),
    );
  }
}
