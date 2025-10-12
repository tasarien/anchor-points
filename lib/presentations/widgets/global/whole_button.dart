import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

// WholeButton - a versatile button widget with various customization options, one of core UI widgets in Rho App

class WholeButton extends StatefulWidget {
  final IconData? icon;
  final String? text;
  final VoidCallback? onPressed;
  final Color? circleColor;
  final bool disabled;
  final bool wide;
  final bool suggested;
  final bool badgeVisible;
  final Widget? label;
  final bool dot;
  final Widget? secondBagde;
  final Color? badgeColor;

  // properties for toggle/switch mode
  final bool switchMode;
  final bool initialSwitchValue;
  final ValueChanged<bool>? onSwitchChanged;

  const WholeButton({
    super.key,
    this.icon,
    this.text = "",
    this.onPressed,
    this.circleColor,
    this.disabled = false,
    this.wide = false,
    this.suggested = true,
    this.badgeVisible = false,
    this.label,
    this.dot = false,
    this.secondBagde,
    this.badgeColor,
    this.switchMode = false,
    this.initialSwitchValue = false,
    this.onSwitchChanged,
  });

  @override
  State<WholeButton> createState() => _WholeButtonState();
}

class _WholeButtonState extends State<WholeButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  // Internal state for toggle mode
  late bool _isSwitchedOn;

  @override
  void initState() {
    super.initState();

    _isSwitchedOn = widget.initialSwitchValue;

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    if (widget.dot) {
      _animationController.reset();
    } else {
      _animationController.forward();
    }
  }

  @override
  void didUpdateWidget(WholeButton oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.dot != widget.dot) {
      if (widget.dot) {
        _animationController.reverse();
      } else {
        _animationController.forward();
      }
    }

    if (oldWidget.initialSwitchValue != widget.initialSwitchValue &&
        widget.switchMode) {
      _isSwitchedOn = widget.initialSwitchValue;
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // Method to trigger reverse animation before unmounting
  Future<void> animateOut() async {
    await _animationController.reverse();
  }

  void _handlePress() {
    if (widget.disabled) return;

    if (widget.switchMode) {
      setState(() {
        _isSwitchedOn = !_isSwitchedOn;
      });
      widget.onSwitchChanged?.call(_isSwitchedOn);
    } else {
      widget.onPressed?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    ThemeData theme = Theme.of(context);

    // If switchMode is on, change the color based on toggle state
    Color stateColor;
    if (widget.disabled) {
      stateColor = theme.colorScheme.tertiary;
    } else if (widget.switchMode) {
      stateColor = _isSwitchedOn
          ? theme.colorScheme.primary
          : theme.colorScheme.secondary;
    } else {
      stateColor = widget.suggested
          ? theme.colorScheme.onSurface
          : theme.colorScheme.secondary;
    }

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        if (widget.dot && _animationController.value == 0.0) {
          return Padding(
            padding: const EdgeInsets.only(top: 20.0),
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: theme.colorScheme.secondary,
                shape: BoxShape.circle,
              ),
            ),
          );
        }

        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Opacity(
            opacity: _opacityAnimation.value,
            child: widget.wide
                ? IntrinsicWidth(
                    child: _buildButtonColumn(context, theme, stateColor),
                  )
                : SizedBox(
                    width: 60,
                    child: _buildButtonColumn(context, theme, stateColor),
                  ),
          ),
        );
      },
    );
  }

  Widget _buildButtonColumn(
    BuildContext context,
    ThemeData theme,
    Color stateColor,
  ) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        FilledButton(
          onPressed: _handlePress,
          style: ButtonStyle(
            foregroundColor: WidgetStateColor.fromMap({
              WidgetState.pressed: theme.colorScheme.onSurface,
              WidgetState.any: stateColor,
            }),
            shadowColor: const WidgetStatePropertyAll(Colors.black),
            elevation: WidgetStateProperty.fromMap({
              WidgetState.pressed: 0,
              WidgetState.any: widget.disabled ? 0 : 3,
            }),
            padding: const WidgetStatePropertyAll(EdgeInsets.zero),
            backgroundColor: WidgetStateColor.fromMap({
              WidgetState.pressed: theme.colorScheme.surface,
              WidgetState.any: theme.colorScheme.surface,
            }),
            minimumSize: const WidgetStatePropertyAll(Size(40, 40)),
            maximumSize: WidgetStatePropertyAll(
              widget.wide
                  ? const Size(double.infinity, 40)
                  : const Size(40, 40),
            ),
            shape: WidgetStatePropertyAll(
              RoundedSuperellipseBorder(
                side: BorderSide(color: stateColor),
                borderRadius: const BorderRadiusGeometry.all(
                  Radius.circular(10),
                ),
              ),
            ),
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: widget.wide ? 10 : 0),
            child: Badge(
              isLabelVisible: widget.secondBagde != null,
              label: widget.secondBagde,
              alignment: Alignment.topLeft,
              backgroundColor: theme.colorScheme.onSurface,
              textColor: theme.scaffoldBackgroundColor,
              child: Badge(
                backgroundColor: widget.badgeColor ?? theme.colorScheme.error,
                isLabelVisible: widget.badgeVisible,
                label: widget.label,
                child: Stack(
                  fit: StackFit.loose,
                  alignment: Alignment.center,
                  children: [
                    widget.wide
                        ? Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Container(
                              width: double.infinity,
                              height: double.infinity,
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color:
                                      widget.circleColor ??
                                      theme.colorScheme.surface,
                                  width: widget.switchMode
                                      ? 4
                                      : 3, // thicker border for toggle mode
                                ),
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                          )
                        : Container(),
                    widget.wide
                        ? Container()
                        : Icon(
                            Icons.circle_outlined,
                            size: 35,
                            color:
                                widget.circleColor ??
                                theme.colorScheme.primary.withAlpha(160),
                          ),

                    // toggle indicator
                    if (widget.switchMode)
                      Positioned(
                        top: 6,
                        right: 6,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: _isSwitchedOn
                                ? theme.colorScheme.tertiary
                                : theme.colorScheme.error,
                            shape: BoxShape.circle,
                            boxShadow: _isSwitchedOn
                                ? [
                                    BoxShadow(
                                      color: theme.colorScheme.primary
                                          .withOpacity(0.6),
                                      blurRadius: 4,
                                      spreadRadius: 1,
                                    ),
                                  ]
                                : [],
                          ),
                        ),
                      ),

                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: widget.wide ? 8.0 : 0,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          widget.icon != null
                              ? FaIcon(widget.icon, size: 20, color: stateColor)
                              : Container(),
                          widget.icon != null && widget.wide == true
                              ? const SizedBox(width: 10)
                              : Container(),
                          widget.wide
                              ? Text(
                                  widget.text!.toUpperCase(),
                                  style: TextStyle(
                                    fontFamily: "EBGaramond",
                                    fontSize: 12,
                                    color: stateColor,
                                  ),
                                )
                              : Container(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (!widget.wide && widget.text != null && widget.text!.isNotEmpty)
          Container(
            width: 60,
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              widget.text!.toUpperCase(),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              softWrap: true,
              style: TextStyle(
                fontFamily: "EBGaramond",
                fontSize: 12,
                color: stateColor,
                height: 1.1,
              ),
            ),
          ),
      ],
    );
  }
}
