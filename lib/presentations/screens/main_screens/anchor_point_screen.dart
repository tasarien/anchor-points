import 'package:flutter/material.dart';

class AnchorPointScreen extends StatelessWidget {
  const AnchorPointScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Anchor Point')),
      body: const Center(
        child: Text(
          'Welcome to Anchor Point Screen!',
          style: TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}
