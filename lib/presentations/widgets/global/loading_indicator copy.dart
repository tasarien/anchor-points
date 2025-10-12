import 'package:flutter/material.dart';

// LoadingIndicator - widget displaying a loading spinner with a specific style

class LoadingIndicator extends StatelessWidget {
  const LoadingIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    ColorScheme colorScheme = Theme.of(context).colorScheme;
    return Container(
      decoration: ShapeDecoration(
        color: colorScheme.surface,
        shape: RoundedSuperellipseBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: colorScheme.onSurface),
        ),
      ),
      width: 50,
      height: 50,
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: CircularProgressIndicator(),
      ),
    );
  }
}
