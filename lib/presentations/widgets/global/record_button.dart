import 'package:flutter/material.dart';

class RecordButton extends StatefulWidget {
  final bool isRecording;
  final VoidCallback onPressed;
  const RecordButton({
    Key? key,
    required this.isRecording,
    required this.onPressed,
  }) : super(key: key);

  @override
  State<RecordButton> createState() => _RecordButtonState();
}

class _RecordButtonState extends State<RecordButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.3,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ColorScheme colorScheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: widget.onPressed,
      child: SizedBox(
        height: 120,
        width: 120,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Animated blob background
            if (widget.isRecording)
              AnimatedBuilder(
                animation: _scaleAnimation,
                builder: (context, child) {
                  return Container(
                    width: 80 * _scaleAnimation.value,
                    height: 80 * _scaleAnimation.value,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: colorScheme.error.withAlpha(120),
                    ),
                  );
                },
              ),
            // Main button
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.isRecording
                    ? colorScheme.error
                    : colorScheme.secondary,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Center(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: widget.isRecording ? 24 : 32,
                  height: widget.isRecording ? 24 : 32,
                  decoration: BoxDecoration(
                    color: widget.isRecording
                        ? colorScheme.secondary
                        : colorScheme.error,
                    borderRadius: BorderRadius.circular(
                      widget.isRecording ? 4 : 16,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
