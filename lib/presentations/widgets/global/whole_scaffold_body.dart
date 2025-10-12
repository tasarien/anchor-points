import 'package:flutter/material.dart';

class WholeScaffoldBody extends StatelessWidget {
  final Widget child;
  const WholeScaffoldBody({Key? key, required this.child}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    ThemeData colorScheme = Theme.of(context);
    return SafeArea(
      child: Center(
        child: Container(
          constraints: BoxConstraints(
            maxWidth: 600,
            maxHeight: MediaQuery.of(context).size.height,
          ),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              stops: [0, 0.8],
              colors: [
                colorScheme.colorScheme.surface,
                colorScheme.scaffoldBackgroundColor,
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}
