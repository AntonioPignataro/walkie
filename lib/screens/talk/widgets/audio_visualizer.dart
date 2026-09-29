import 'dart:math';
import 'package:flutter/material.dart';

class AudioVisualizer extends StatefulWidget {
  final bool isActive;
  final Color color;

  const AudioVisualizer({
    super.key,
    required this.isActive,
    required this.color,
  });

  @override
  State<AudioVisualizer> createState() => _AudioVisualizerState();
}

class _AudioVisualizerState extends State<AudioVisualizer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    if (widget.isActive) _controller.repeat();
  }

  @override
  void didUpdateWidget(covariant AudioVisualizer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      _controller.repeat();
    } else if (!widget.isActive && oldWidget.isActive) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: widget.isActive ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 300),
      child: SizedBox(
        height: 32,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(7, (i) {
                final height = 8.0 +
                    (_random.nextDouble() * 24.0 * (widget.isActive ? 1.0 : 0.0));
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: 3,
                  height: height,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                    color: widget.color.withAlpha(180),
                    borderRadius: BorderRadius.circular(2),
                  ),
                );
              }),
            );
          },
        ),
      ),
    );
  }
}
