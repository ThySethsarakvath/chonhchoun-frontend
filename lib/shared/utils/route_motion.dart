import 'dart:math' as math;

import 'package:latlong2/latlong.dart';

class RouteMotionSnapshot {
  const RouteMotionSnapshot({
    required this.position,
    required this.bearingRadians,
  });

  final LatLng position;
  final double bearingRadians;
}

class SmoothRouteProgress {
  final Stopwatch _clock = Stopwatch()..start();
  Duration _lastTick = Duration.zero;
  String? _phaseKey;
  double _value = 0;

  double update({
    required String phaseKey,
    required double serverProgress,
    required int durationSeconds,
    bool completed = false,
    bool paused = false,
  }) {
    final now = _clock.elapsed;
    if (_phaseKey != phaseKey) {
      _phaseKey = phaseKey;
      _value = completed ? 1 : serverProgress.clamp(0.0, 1.0);
      _lastTick = now;
      return _value;
    }

    final elapsedSeconds =
        (now - _lastTick).inMicroseconds / Duration.microsecondsPerSecond;
    _lastTick = now;
    if (completed) {
      _value = 1;
      return _value;
    }

    final frameSeconds = elapsedSeconds.clamp(0.0, 0.1);
    final duration = durationSeconds <= 0 ? 1 : durationSeconds;
    var next = _value + (paused ? 0 : frameSeconds / duration);

    final serverTarget = serverProgress.clamp(0.0, 1.0);
    final correction = serverTarget - next;
    if (correction > 0) {
      final blend = 1 - math.exp(-frameSeconds * 4);
      next += correction * blend;
    }
    _value = next.clamp(0.0, 1.0);
    return _value;
  }
}

final Expando<_RouteMetrics> _routeMetricsCache = Expando<_RouteMetrics>(
  'routeMotionMetrics',
);

RouteMotionSnapshot? sampleRouteMotion(List<LatLng> points, double progress) {
  if (points.isEmpty) return null;
  if (points.length == 1) {
    return RouteMotionSnapshot(position: points.first, bearingRadians: 0);
  }

  final metrics = _routeMetricsCache[points] ??= _RouteMetrics.from(points);

  if (metrics.totalLength <= 0) {
    return RouteMotionSnapshot(
      position: points.first,
      bearingRadians: _bearingRadians(points.first, points.last),
    );
  }

  final targetDistance = progress.clamp(0.0, 1.0) * metrics.totalLength;
  final position = metrics.positionAt(points, targetDistance);
  const headingWindowMeters = 7.0;
  final headingFrom = metrics.positionAt(
    points,
    math.max(0, targetDistance - headingWindowMeters),
  );
  final headingTo = metrics.positionAt(
    points,
    math.min(metrics.totalLength, targetDistance + headingWindowMeters),
  );
  return RouteMotionSnapshot(
    position: position,
    bearingRadians: _bearingRadians(headingFrom, headingTo),
  );
}

class _RouteMetrics {
  const _RouteMetrics({
    required this.segmentLengths,
    required this.cumulativeLengths,
    required this.totalLength,
  });

  factory _RouteMetrics.from(List<LatLng> points) {
    final segmentLengths = <double>[];
    final cumulativeLengths = <double>[];
    var totalLength = 0.0;
    for (var index = 0; index < points.length - 1; index++) {
      final length = _distanceMeters(points[index], points[index + 1]);
      segmentLengths.add(length);
      totalLength += length;
      cumulativeLengths.add(totalLength);
    }
    return _RouteMetrics(
      segmentLengths: segmentLengths,
      cumulativeLengths: cumulativeLengths,
      totalLength: totalLength,
    );
  }

  final List<double> segmentLengths;
  final List<double> cumulativeLengths;
  final double totalLength;

  int segmentIndexAt(double distance) {
    var lower = 0;
    var upper = cumulativeLengths.length - 1;
    while (lower < upper) {
      final middle = (lower + upper) ~/ 2;
      if (distance <= cumulativeLengths[middle]) {
        upper = middle;
      } else {
        lower = middle + 1;
      }
    }
    return lower;
  }

  LatLng positionAt(List<LatLng> points, double distance) {
    final safeDistance = distance.clamp(0.0, totalLength);
    final segmentIndex = segmentIndexAt(safeDistance);
    final segmentStart = segmentIndex == 0
        ? 0.0
        : cumulativeLengths[segmentIndex - 1];
    final segmentLength = segmentLengths[segmentIndex];
    final fraction = segmentLength <= 0
        ? 0.0
        : ((safeDistance - segmentStart) / segmentLength).clamp(0.0, 1.0);
    final from = points[segmentIndex];
    final to = points[segmentIndex + 1];
    return LatLng(
      from.latitude + (to.latitude - from.latitude) * fraction,
      from.longitude + (to.longitude - from.longitude) * fraction,
    );
  }
}

double _distanceMeters(LatLng from, LatLng to) {
  const earthRadiusMeters = 6371000.0;
  final latitudeDelta = _radians(to.latitude - from.latitude);
  final longitudeDelta = _radians(to.longitude - from.longitude);
  final fromLatitude = _radians(from.latitude);
  final toLatitude = _radians(to.latitude);
  final haversine =
      math.sin(latitudeDelta / 2) * math.sin(latitudeDelta / 2) +
      math.cos(fromLatitude) *
          math.cos(toLatitude) *
          math.sin(longitudeDelta / 2) *
          math.sin(longitudeDelta / 2);
  return earthRadiusMeters *
      2 *
      math.atan2(math.sqrt(haversine), math.sqrt(1 - haversine));
}

double _bearingRadians(LatLng from, LatLng to) {
  final fromLatitude = _radians(from.latitude);
  final toLatitude = _radians(to.latitude);
  final longitudeDelta = _radians(to.longitude - from.longitude);
  final y = math.sin(longitudeDelta) * math.cos(toLatitude);
  final x =
      math.cos(fromLatitude) * math.sin(toLatitude) -
      math.sin(fromLatitude) * math.cos(toLatitude) * math.cos(longitudeDelta);
  return math.atan2(y, x);
}

double _radians(double degrees) => degrees * math.pi / 180;
