import 'package:anchor_point_app/data/models/anchor_point_model.dart';
import 'package:anchor_point_app/presentations/widgets/global/section_tab.dart';
import 'package:anchor_point_app/presentations/widgets/global/whole_button.dart';
import 'package:flutter/material.dart';

class AnchorPointWidget extends StatefulWidget {
  final AnchorPoint anchorPoint;
  const AnchorPointWidget({ Key? key, required this.anchorPoint }) : super(key: key);

  @override
  _AnchorPointWidgetState createState() => _AnchorPointWidgetState();
}

class _AnchorPointWidgetState extends State<AnchorPointWidget> {
  @override
  Widget build(BuildContext context) {
    ColorScheme colorScheme = Theme.of(context).colorScheme;
    return Center(
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
                    child: Container(
                      width: 270,
                      height: 270,
                    ),
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
                   child: Container(
                        width: 220,
                        height: 50,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: colorScheme.surface,
                          border: Border.all(color: colorScheme.tertiary),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          widget.anchorPoint.name!,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                 ),
              ],
            ),
          ),
          Container(
            width: 300,
            
            child: Card(child: Column(
              children: [
                SectionTab(
                  text: "Segments",
                  content: Row(
                    children: [
                      WholeButton(),
                      WholeButton(),
                      WholeButton()
                    ],
                  ),
                )
              ],
            ),),
          )
        ],
      ),
    );
  }
   
  
}