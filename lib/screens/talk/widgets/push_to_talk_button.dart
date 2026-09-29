import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../theme/walkie_colors.dart';

class PushToTalkButton extends StatefulWidget {
  final bool isConnected;
  final bool isTalking;
  final VoidCallback onTalkStart;
  final VoidCallback onTalkEnd;
  final VoidCallback? onTapDisconnected;

  const PushToTalkButton({
    super.key,
    required this.isConnected,
    required this.isTalking,
    required this.onTalkStart,
    required this.onTalkEnd,
    this.onTapDisconnected,
  });

  @override
  State<PushToTalkButton> createState() => _PushToTalkButtonState();
}

class _PushToTalkButtonState extends State<PushToTalkButton>
    with TickerProviderStateMixin {
  late AnimationController _breathingController;
  late AnimationController _pressController;
  late AnimationController _rippleController;
  late AnimationController _glowController;

  late Animation<double> _breathingAnimation;
  late Animation<double> _pressAnimation;
  late Animation<double> _rippleAnimation;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();

    // Breathing animation — subtle idle pulse
    _breathingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    _breathingAnimation = Tween<double>(begin: 1.0, end: 1.02).animate(
      CurvedAnimation(parent: _breathingController, curve: Curves.easeInOut),
    );

    // Press scale animation
    _pressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _pressAnimation = Tween<double>(begin: 1.0, end: 0.93).animate(
      CurvedAnimation(parent: _pressController, curve: Curves.easeOut),
    );

    // Ripple expansion
    _rippleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _rippleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _rippleController, curve: Curves.easeOut),
    );

    // Glow pulse while talking
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _glowAnimation = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );
  }

  @override
  void didUpdateWidget(covariant PushToTalkButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isTalking && !oldWidget.isTalking) {
      _pressController.forward();
      _rippleController.repeat();
      _glowController.repeat(reverse: true);
      _breathingController.stop();
    } else if (!widget.isTalking && oldWidget.isTalking) {
      _pressController.reverse();
      _rippleController.stop();
      _rippleController.reset();
      _glowController.stop();
      _glowController.reset();
      if (widget.isConnected) {
        _breathingController.repeat(reverse: true);
      }
    }
  }

  @override
  void dispose() {
    _breathingController.dispose();
    _pressController.dispose();
    _rippleController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  void _onPointerDown(PointerDownEvent event) {
    if (!widget.isConnected) {
      widget.onTapDisconnected?.call();
      return;
    }
    HapticFeedback.mediumImpact();
    widget.onTalkStart();
  }

  void _onPointerUp(PointerUpEvent event) {
    if (!widget.isConnected) return;
    HapticFeedback.lightImpact();
    widget.onTalkEnd();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = widget.isConnected
        ? Theme.of(context).colorScheme.primary
        : WalkieColors.disconnectedGray;

    return LayoutBuilder(
      builder: (context, constraints) {
        final size = min(constraints.maxWidth * 0.7, 260.0);

        return SizedBox(
          width: size + 80,
          height: size + 80,
          child: AnimatedBuilder(
            animation: Listenable.merge([
              _breathingAnimation,
              _pressAnimation,
              _rippleAnimation,
              _glowAnimation,
            ]),
            builder: (context, child) {
              final scale = widget.isTalking
                  ? _pressAnimation.value
                  : (widget.isConnected
                      ? _breathingAnimation.value
                      : 1.0);

              return Stack(
                alignment: Alignment.center,
                children: [
                  // Ripple rings
                  if (widget.isTalking)
                    ...List.generate(3, (i) {
                      final delay = i * 0.33;
                      final progress =
                          (_rippleAnimation.value + delay) % 1.0;
                      return _RippleRing(
                        size: size,
                        progress: progress,
                        color: primaryColor,
                      );
                    }),

                  // Glow background
                  if (widget.isTalking)
                    Container(
                      width: size + 30,
                      height: size + 30,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: primaryColor
                                .withAlpha((60 * _glowAnimation.value).round()),
                            blurRadius: 40 * _glowAnimation.value,
                            spreadRadius: 10 * _glowAnimation.value,
                          ),
                        ],
                      ),
                    ),

                  // Main button
                  Transform.scale(
                    scale: scale,
                    child: Listener(
                      onPointerDown: _onPointerDown,
                      onPointerUp: _onPointerUp,
                      onPointerCancel: (_) {
                        if (widget.isConnected) widget.onTalkEnd();
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: size,
                        height: size,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: widget.isTalking
                              ? primaryColor.withAlpha(25)
                              : (isDark
                                  ? WalkieColors.darkSurface
                                  : WalkieColors.lightSurface),
                          border: Border.all(
                            color: primaryColor.withAlpha(
                              widget.isTalking ? 200 : (widget.isConnected ? 120 : 60),
                            ),
                            width: widget.isTalking ? 3 : 2,
                          ),
                          boxShadow: widget.isTalking
                              ? [
                                  BoxShadow(
                                    color: primaryColor.withAlpha(40),
                                    blurRadius: 20,
                                    spreadRadius: 2,
                                  ),
                                ]
                              : null,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 200),
                              child: Icon(
                                widget.isTalking
                                    ? Icons.mic
                                    : (widget.isConnected
                                        ? Icons.mic_none
                                        : Icons.mic_off),
                                key: ValueKey(widget.isTalking),
                                size: size * 0.25,
                                color: widget.isTalking
                                    ? primaryColor
                                    : primaryColor.withAlpha(
                                        widget.isConnected ? 180 : 100),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              widget.isTalking
                                  ? 'TRANSMITTING'
                                  : (widget.isConnected
                                      ? 'HOLD TO TALK'
                                      : 'NOT CONNECTED'),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 2,
                                color: primaryColor.withAlpha(
                                  widget.isTalking ? 230 : (widget.isConnected ? 150 : 80),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }
}

class _RippleRing extends StatelessWidget {
  final double size;
  final double progress;
  final Color color;

  const _RippleRing({
    required this.size,
    required this.progress,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final ringSize = size + (80 * progress);
    final opacity = (1.0 - progress).clamp(0.0, 0.3);

    return Container(
      width: ringSize,
      height: ringSize,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: color.withAlpha((opacity * 255).round()),
          width: 2 * (1.0 - progress),
        ),
      ),
    );
  }
}
