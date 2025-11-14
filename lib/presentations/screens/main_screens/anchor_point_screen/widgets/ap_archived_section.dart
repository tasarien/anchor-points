import 'package:flutter/material.dart';

class ApArchivedSection extends StatelessWidget {
  const ApArchivedSection({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Text('Archived'),
        ),
      ),
    );
  }
}
