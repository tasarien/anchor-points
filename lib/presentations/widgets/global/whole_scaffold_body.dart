import 'package:anchor_point_app/presentations/widgets/global/cont_with_bg.dart';
import 'package:flutter/material.dart';

class WholeScaffoldBody extends StatelessWidget {
  final Widget child;
  final String? assetName;

  const WholeScaffoldBody({Key? key, required this.child, this.assetName})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    ThemeData colorScheme = Theme.of(context);
    return SafeArea(
      child: Center(
        child: Container(
          color: colorScheme.scaffoldBackgroundColor,
          constraints: BoxConstraints(
            maxWidth: 600,
            maxHeight: MediaQuery.of(context).size.height,
          ),

          child: ContWithBg(
            assetName: assetName ?? '',
            color: colorScheme.colorScheme.onSurface.withAlpha(70),
            child: child,
          ),
        ),
      ),
    );
  }
}
