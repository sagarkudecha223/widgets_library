import 'dart:async';

import 'package:flip_board/flip_widget.dart';
import 'package:flutter/material.dart';

class FlipCountdownClock extends StatelessWidget {
  FlipCountdownClock({
    super.key,
    required this.duration,
    required double digitSize,
    required double width,
    required double height,
    AxisDirection flipDirection = AxisDirection.up,
    Curve? flipCurve,
    Color? digitColor,
    Color? backgroundColor,
    double? separatorWidth,
    Color? separatorColor,
    Color? separatorBackgroundColor,
    bool? showBorder,
    double? borderWidth,
    Color? borderColor,
    BorderRadius borderRadius = const BorderRadius.all(Radius.circular(4.0)),
    double hingeWidth = 0.8,
    double? hingeLength,
    Color? hingeColor,
    EdgeInsets digitSpacing = const EdgeInsets.symmetric(horizontal: 2.0),
    this.onDone,
  }) : _displayBuilder = FlipClockBuilder(
          digitSize: digitSize,
          width: width,
          height: height,
          flipDirection: flipDirection,
          flipCurve: flipCurve,
          digitColor: digitColor,
          backgroundColor: backgroundColor,
          separatorWidth: separatorWidth ?? width / 3.0,
          separatorColor: separatorColor,
          separatorBackgroundColor: separatorBackgroundColor,
          showBorder:
              showBorder ?? (borderColor != null || borderWidth != null),
          borderWidth: borderWidth,
          borderColor: borderColor,
          borderRadius: borderRadius,
          hingeWidth: hingeWidth,
          hingeLength: hingeWidth == 0.0
              ? 0.0
              : hingeLength ??
                  (flipDirection == AxisDirection.down ||
                          flipDirection == AxisDirection.up
                      ? width
                      : height),
          hingeColor: hingeColor,
          digitSpacing: digitSpacing,
        );

  /// Duration of the countdown.
  final Duration duration;

  /// Optional callback when the countdown is done.
  final VoidCallback? onDone;

  /// Builder with common code for all FlipClock types.
  ///
  /// This builder is created with most of my constructor parameters
  final FlipClockBuilder _displayBuilder;

  @override
  Widget build(BuildContext context) {
    const step = Duration(seconds: 1);
    final startTime = DateTime.now();
    final endTime = startTime.add(duration).add(step);

    var done = false;
    final periodicStream = Stream<Duration>.periodic(step, (_) {
      final now = DateTime.now();
      if (now.isBefore(endTime)) {
        return endTime.difference(now);
      }
      if (!done && onDone != null) {
        onDone!();
      }
      done = true;
      return Duration.zero;
    });

    // Take up to (including) Duration.zero
    var fetchedZero = false;
    final durationStream = periodicStream.takeWhile((timeLeft) {
      final waitingZero = !fetchedZero;
      fetchedZero |= timeLeft.inSeconds == 0;
      return waitingZero;
    }).asBroadcastStream();

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildSecondsDisplay(durationStream, duration),
      ],
    );
  }

  Widget _buildSecondsDisplay(Stream<Duration> stream, Duration initValue) =>
      _displayBuilder.buildTimePartDisplay(
        stream.map((time) => time.inSeconds % 60),
        initValue.inSeconds % 60,
      );
}

class FlipClockBuilder {
  const FlipClockBuilder({
    required this.digitSize,
    required this.width,
    required this.height,
    required this.flipDirection,
    this.flipCurve,
    this.digitColor,
    this.backgroundColor,
    required this.separatorWidth,
    this.separatorColor,
    this.separatorBackgroundColor,
    required this.showBorder,
    this.borderWidth,
    this.borderColor,
    required this.borderRadius,
    required this.hingeWidth,
    required this.hingeLength,
    this.hingeColor,
    required this.digitSpacing,
  });

  /// FontSize for clock digits.
  final double digitSize;

  /// Width of each digit panel.
  final double width;

  /// Height of each digit panel.
  final double height;

  /// Animation flip direction.
  final AxisDirection flipDirection;

  /// Animation curve.
  ///
  /// If null FlipWidget.defaultAnimation will be used
  final Curve? flipCurve;

  /// Digit color.
  ///
  /// Defaults to colorScheme.onPrimary
  final Color? digitColor;

  /// Digit panel color (background color).
  ///
  /// Defauts to colorScheme.primary
  final Color? backgroundColor;

  /// Separator width to display a ":" between digit groups.
  ///
  /// Defaults to digit width / 3
  final double separatorWidth;

  /// Separator color to display a ":" between digit groups.
  ///
  /// Defaults to colorScheme.onPrimary
  final Color? separatorColor;

  /// Separator background color where we display a ":" between digit groups.
  ///
  /// Defaults to null (transparent)
  final Color? separatorBackgroundColor;

  /// Flag to define if there will be a border for each digit panel.
  final bool showBorder;

  /// Border width for each digit panel.
  ///
  /// Defaults to 1.0
  final double? borderWidth;

  /// Border color for each digit panel.
  ///
  /// Defaults to colorScheme.onPrimary when showBorder is true
  final Color? borderColor;

  /// Border radius for each digit panel.
  final BorderRadius borderRadius;

  /// Hinge width for each digit panel.
  final double hingeWidth;

  /// Hinge length for each digit panel.
  final double hingeLength;

  /// Hinge color for each digit panel.
  ///
  /// Defaults to null (transparent)
  final Color? hingeColor;

  /// Spacing betwen digit panels.
  final EdgeInsets digitSpacing;

  Widget buildTimePartDisplay(Stream<int> timePartStream, int initValue) => Row(
        children: [
          _buildTensDisplay(timePartStream, initValue),
          _buildUnitsDisplay(timePartStream, initValue),
        ],
      );

  Widget _buildTensDisplay(Stream<int> timePartStream, int initialValue) =>
      _buildDisplay(
        timePartStream.map<int>((value) => value ~/ 10),
        initialValue ~/ 10,
      );

  Widget _buildUnitsDisplay(Stream<int> timePartStream, int initialValue) =>
      _buildDisplay(
        timePartStream.map<int>((value) => value % 10),
        initialValue % 10,
      );

  Widget _buildDisplay(Stream<int> digitStream, int initialValue) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: digitSpacing,
            child: FlipWidget<int>(
              flipType: FlipType.middleFlip,
              itemStream: digitStream,
              itemBuilder: _digitBuilder,
              initialValue: initialValue,
              hingeWidth: hingeWidth,
              hingeLength: hingeLength,
              hingeColor: hingeColor,
              flipDirection: flipDirection,
              flipCurve: flipCurve ?? FlipWidget.defaultFlip,
            ),
          ),
        ],
      );

  Widget _digitBuilder(BuildContext context, int? digit) => Container(
        decoration: BoxDecoration(
          color: backgroundColor ?? Theme.of(context).colorScheme.primary,
          borderRadius: borderRadius,
          border: showBorder
              ? Border.all(
                  color: borderColor ?? Theme.of(context).colorScheme.onPrimary,
                  width: borderWidth ?? 1.0,
                )
              : null,
        ),
        width: width,
        height: height,
        alignment: Alignment.center,
        child: Text(
          digit == null ? ' ' : digit.toString(),
          textAlign: TextAlign.center,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: digitSize,
            color: digitColor ?? Theme.of(context).colorScheme.onPrimary,
          ),
        ),
      );
}
