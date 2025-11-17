import 'package:flutter/material.dart';

// Show intro circles - displays a sequence of animated circles with images
// TODO: Give more images, push some variation

Future<void> showIntroCircles(BuildContext context) async {
  final overlay = Overlay.of(context);
  final overlayEntry = OverlayEntry(
    builder: (context) => _IntroOverlayVertical(),
  );

  overlay.insert(overlayEntry);

  // Wait for the animation to finish before removing the overlay
  await Future.delayed(Duration(seconds: 5));
  overlayEntry.remove();
}

class _IntroOverlayVertical extends StatefulWidget {
  @override
  State<_IntroOverlayVertical> createState() => _IntroOverlayVerticalState();
}

class _IntroOverlayVerticalState extends State<_IntroOverlayVertical>
    with TickerProviderStateMixin {
  late final AnimationController _fadeController;
  late final AnimationController _circle1Controller;
  late final AnimationController _circle2Controller;
  late final AnimationController _circle3Controller;

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 500),
    )..forward();

    _circle1Controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 400),
    );
    _circle2Controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 400),
    );
    _circle3Controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 400),
    );

    _startSequence();
  }

  Future<void> _startSequence() async {
    await Future.delayed(Duration(milliseconds: 600));
    await _circle1Controller.forward();
    await Future.delayed(Duration(milliseconds: 800));
    await _circle2Controller.forward();
    await Future.delayed(Duration(milliseconds: 800));
    await _circle3Controller.forward();
    await Future.delayed(Duration(milliseconds: 900));
    await _fadeController.reverse();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _circle1Controller.dispose();
    _circle2Controller.dispose();
    _circle3Controller.dispose();
    super.dispose();
  }

  Widget _animatedCircle(AnimationController controller, String assetPath) {
    return ScaleTransition(
      scale: controller,
      child: Opacity(
        opacity: controller.value,
        child: CircleAvatar(
          radius: 100,
          backgroundImage: AssetImage(assetPath),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeController,
      child: Container(
        color: Colors.black.withOpacity(0.6),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedBuilder(
                animation: _circle1Controller,
                builder: (_, __) => _animatedCircle(
                    _circle1Controller, 'assets/images/intro_image1.png'),
              ),
              SizedBox(height: 20),
              AnimatedBuilder(
                animation: _circle2Controller,
                builder: (_, __) => _animatedCircle(
                    _circle2Controller, 'assets/images/intro_image2.png'),
              ),
              SizedBox(height: 20),
              AnimatedBuilder(
                animation: _circle3Controller,
                builder: (_, __) => _animatedCircle(
                    _circle3Controller, 'assets/images/intro_image3.png'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
