import 'package:animated_flip_counter/animated_flip_counter.dart';
import 'package:bmc_authenticator/core/utils/styles.dart';
import 'package:flutter/material.dart';

import '../../../core/utils/colors.dart';
import '../../../core/utils/dimens.dart';
import 'timer_painter.dart';

class CircularCountDownTimer extends StatefulWidget {
  final Color fillColor;
  final Gradient? fillGradient;
  final Color ringColor;
  final Gradient? ringGradient;
  final Color? backgroundColor;
  final Gradient? backgroundGradient;
  final VoidCallback? onComplete;
  final VoidCallback? onStart;
  final ValueChanged<String>? onChange;
  final int duration;
  final int initialDuration;
  final double width;
  final double height;
  final double strokeWidth;
  final StrokeCap strokeCap;
  final TextStyle? textStyle;
  final TextAlign textAlign;
  final bool isReverse;
  final bool isReverseAnimation;
  final bool isTimerTextShown;
  final CountDownController? controller;
  final bool autoStart;
  final Function(Function(Duration duration) defaultFormatterFunction,
      Duration duration)? timeFormatterFunction;

  const CircularCountDownTimer({
    required this.width,
    required this.height,
    required this.duration,
    this.fillColor = AppColors.black,
    this.ringColor = AppColors.borderColor,
    this.timeFormatterFunction,
    this.backgroundColor = AppColors.white,
    this.fillGradient,
    this.ringGradient,
    this.backgroundGradient,
    this.initialDuration = 0,
    this.isReverse = true,
    this.isReverseAnimation = true,
    this.onComplete,
    this.onStart,
    this.onChange,
    this.strokeWidth = Dimens.scrollBarWidthNormal,
    this.strokeCap = StrokeCap.round,
    this.textStyle,
    this.textAlign = TextAlign.left,
    super.key,
    this.isTimerTextShown = true,
    this.autoStart = false,
    this.controller,
  }) : assert(initialDuration <= duration);

  @override
  CircularCountDownTimerState createState() => CircularCountDownTimerState();
}

class CircularCountDownTimerState extends State<CircularCountDownTimer>
    with TickerProviderStateMixin {
  AnimationController? _controller;
  Animation<double>? _countDownAnimation;
  CountDownController? countDownController;

  void _setAnimation() {
    if (widget.autoStart) {
      if (widget.isReverse) {
        _controller!.reverse(from: 1);
      } else {
        _controller!.forward();
      }
    }
  }

  void _setAnimationDirection() {
    if ((!widget.isReverse && widget.isReverseAnimation) ||
        (widget.isReverse && !widget.isReverseAnimation)) {
      _countDownAnimation =
          Tween<double>(begin: 1, end: 0).animate(_controller!);
    }
  }

  void _setController() {
    countDownController?._state = this;
    countDownController?._isReverse = widget.isReverse;
    countDownController?._initialDuration = widget.initialDuration;
    countDownController?._duration = widget.duration;
    countDownController?.isStarted.value = widget.autoStart;

    if (widget.initialDuration > 0 && widget.autoStart) {
      if (widget.isReverse) {
        _controller?.value = 1 - (widget.initialDuration / widget.duration);
      } else {
        _controller?.value = (widget.initialDuration / widget.duration);
      }

      countDownController?.start();
    }
  }

  String _getTime(Duration duration) => '${(duration.inSeconds)}';

  void _onStart() {
    if (widget.onStart != null) widget.onStart!();
  }

  void _onComplete() {
    if (widget.onComplete != null) widget.onComplete!();
  }

  @override
  void initState() {
    countDownController = widget.controller ?? CountDownController();
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(seconds: widget.duration),
    );

    _controller!.addStatusListener((status) {
      switch (status) {
        case AnimationStatus.forward:
          _onStart();
          break;

        case AnimationStatus.reverse:
          _onStart();
          break;

        case AnimationStatus.dismissed:
          _onComplete();
          break;
        case AnimationStatus.completed:

          /// [AnimationController]'s value is manually set to [1.0] that's why [AnimationStatus.completed] is invoked here this animation is [isReverse]
          /// Only call the [_onComplete] block when the animation is not reversed.
          if (!widget.isReverse) _onComplete();
          break;
      }
    });

    _setAnimation();
    _setAnimationDirection();
    _setController();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: AnimatedBuilder(
          animation: _controller!,
          builder: (context, child) => Align(
                child: AspectRatio(
                  aspectRatio: 1.0,
                  child: Stack(
                    children: <Widget>[
                      Positioned.fill(
                        child: CustomPaint(
                          painter: CustomTimerPainter(
                              animation: _countDownAnimation ?? _controller,
                              fillColor: widget.fillColor,
                              fillGradient: widget.fillGradient,
                              ringColor: widget.ringColor,
                              ringGradient: widget.ringGradient,
                              strokeWidth: widget.strokeWidth,
                              strokeCap: widget.strokeCap,
                              isReverse: widget.isReverse,
                              isReverseAnimation: widget.isReverseAnimation,
                              backgroundColor: widget.backgroundColor,
                              backgroundGradient: widget.backgroundGradient),
                        ),
                      ),
                      widget.isTimerTextShown
                          ? Align(
                              alignment: FractionalOffset.center,
                              child: AnimatedFlipCounter(
                                value: num.tryParse(
                                        countDownController?.getTime() ??
                                            '${widget.initialDuration}') ??
                                    widget.initialDuration,
                                textStyle: widget.textStyle ??
                                    AppFontTextStyles.textStyleBold(),
                              ),
                            )
                          : Container(),
                    ],
                  ),
                ),
              )),
    );
  }

  @override
  void dispose() {
    _controller!.stop();
    _controller!.dispose();
    super.dispose();
  }
}

/// Controls (i.e Start, Pause, Resume, Restart) the Countdown Timer.
class CountDownController {
  CircularCountDownTimerState? _state;
  bool? _isReverse;
  ValueNotifier<bool> isStarted = ValueNotifier<bool>(false),
      isPaused = ValueNotifier<bool>(false),
      isResumed = ValueNotifier<bool>(false),
      isRestarted = ValueNotifier<bool>(false);
  int? _initialDuration, _duration;

  /// This Method Starts the Countdown Timer
  void start() {
    if (_isReverse != null && _state != null && _state?._controller != null) {
      if (_isReverse!) {
        _state?._controller?.reverse(
            from: _initialDuration == 0
                ? 1
                : 1 - (_initialDuration! / _duration!));
      } else {
        _state?._controller?.forward(
            from: _initialDuration == 0 ? 0 : (_initialDuration! / _duration!));
      }
      isStarted.value = true;
      isPaused.value = false;
      isResumed.value = false;
      isRestarted.value = false;
    }
  }

  /// This Method Pauses the Countdown Timer
  void pause() {
    if (_state != null && _state?._controller != null) {
      _state?._controller?.stop(canceled: false);
      isPaused.value = true;
      isRestarted.value = false;
      isResumed.value = false;
    }
  }

  /// This Method Resumes the Countdown Timer
  void resume() {
    if (_isReverse != null && _state != null && _state?._controller != null) {
      if (_isReverse!) {
        _state?._controller?.reverse(from: _state!._controller!.value);
      } else {
        _state?._controller?.forward(from: _state!._controller!.value);
      }
      isResumed.value = true;
      isRestarted.value = false;
      isPaused.value = false;
    }
  }

  /// This Method Restarts the Countdown Timer,
  /// Here optional int parameter **duration** is the updated duration for countdown timer

  void restart({int? duration}) {
    if (_isReverse != null && _state != null && _state?._controller != null) {
      _state?._controller!.duration = Duration(
          seconds: duration ?? _state!._controller!.duration!.inSeconds);
      if (_isReverse!) {
        _state?._controller?.reverse(from: 1);
      } else {
        _state?._controller?.forward(from: 0);
      }
      isStarted.value = true;
      isRestarted.value = true;
      isPaused.value = false;
      isResumed.value = false;
    }
  }

  /// This Method resets the Countdown Timer
  void reset() {
    if (_state != null && _state?._controller != null) {
      _state?._controller?.reset();
      isStarted.value = _state?.widget.autoStart ?? false;
      isRestarted.value = false;
      isPaused.value = false;
      isResumed.value = false;
    }
  }

  /// This Method returns the **Current Time** of Countdown Timer i.e
  /// Time Used in terms of **Forward Countdown** and Time Left in terms of **Reverse Countdown**

  String? getTime() {
    if (_state != null && _state?._controller != null) {
      return _state?._getTime(
          _state!._controller!.duration! * _state!._controller!.value);
    }
    return "";
  }
}
