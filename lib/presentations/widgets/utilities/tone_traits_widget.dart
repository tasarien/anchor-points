import 'package:anchor_point_app/presentations/providers/data_provider.dart';
import 'package:anchor_point_app/presentations/widgets/global/loading_indicator.dart';
import 'package:anchor_point_app/presentations/widgets/global/whole_button.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _ToneAdjustmentState extends State<ToneAdjustment> {
  final List<Map<String, dynamic>> toneStructure = [
    {"leftHand": "Realistic", "rightHand": "Idealistic"},
    {"leftHand": "Friendly", "rightHand": "Professional"},
    {"leftHand": "Fun", "rightHand": "Serious"},
    {"leftHand": "Poetic", "rightHand": "Prosaic"},
    {"leftHand": "Enthusiastic", "rightHand": "Reserved"},
  ];

  List<double> toneTraits = [];
  List<double> previousToneTraits = [];
  bool _changed = false;
  bool _saving = false;

  @override
  void initState() {
    setTones();
    super.initState();
  }

  void setTones() {
    for (int i = 0; i < toneStructure.length; i++) {
      toneTraits.add(2);
      previousToneTraits.add(2);
    }
  }

  @override
  Widget build(BuildContext context) {
    final appData = context.watch<DataProvider>();
    ColorScheme colorScheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        Container(
          width: 400,
          height: 250,
          decoration: BoxDecoration(
            border: Border.all(color: colorScheme.primary),
            borderRadius: BorderRadius.circular(10),
          ),
          child: ListView.builder(
            itemCount: toneStructure.length,
            itemBuilder: (context, index) => SizedBox(
              height: 50,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  SizedBox(
                    width: 80,
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        toneStructure[index]["leftHand"],
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                    ),
                  ),
                  Slider(
                    divisions: 100,
                    activeColor: colorScheme.secondary,
                    thumbColor: colorScheme.tertiary,
                    min: 0,
                    max: 1,
                    value: toneTraits[index],
                    onChanged: (num) {
                      setState(() {
                        toneTraits[index] = num;
                        _changed = true;
                      });
                    },
                  ),
                  SizedBox(
                    width: 80,
                    child: Text(
                      toneStructure[index]["rightHand"],
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(10.0),
          child: SizedBox(
            height: 65,
            child: Row(
              spacing: 10,
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                SizedBox(
                  width: 40,
                  height: 65,
                  child: Center(
                    child: WholeButton(
                      dot: !_changed,
                      icon: Icons.settings_backup_restore,
                      onPressed: () {
                        setState(() {
                          toneTraits = List.from(previousToneTraits);
                          _changed = false;
                        });
                      },
                    ),
                  ),
                ),
                _saving
                    ? LoadingIndicator()
                    : WholeButton(
                        wide: true,
                        text: "save",
                        disabled: !_changed,
                        onPressed: () async {
                          setState(() {
                            _saving = true;
                          });

                          setState(() {
                            _saving = false;
                            previousToneTraits = List.from(toneTraits);
                            _changed = false;
                          });
                        },
                      ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class ToneAdjustment extends StatefulWidget {
  const ToneAdjustment({super.key});

  @override
  _ToneAdjustmentState createState() => _ToneAdjustmentState();
}
