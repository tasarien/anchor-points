import 'package:flutter/material.dart';

class OtherAPScreen extends StatelessWidget {
  const OtherAPScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Other AP Screen')),
      body: const Center(
        child: Text(
          'Welcome to Other AP Screen!',
          style: TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}
