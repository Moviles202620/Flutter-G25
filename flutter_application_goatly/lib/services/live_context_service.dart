import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:proximity_sensor/proximity_sensor.dart';
import 'package:sensors_plus/sensors_plus.dart';

enum StabilityStatus { stable, moving, unavailable }

class LiveContextService {
  static bool get isSupportedMobilePlatform {
    if (kIsWeb) return false;
    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
  }

  static Stream<StabilityStatus> watchStability() {
    if (!isSupportedMobilePlatform) {
      return const Stream<StabilityStatus>.empty();
    }

    return gyroscopeEventStream().map((event) {
      final intensity = math.sqrt(
        (event.x * event.x) + (event.y * event.y) + (event.z * event.z),
      );
      return intensity < 1.2 ? StabilityStatus.stable : StabilityStatus.moving;
    }).distinct();
  }

  static Stream<Object?> watchProximityEvents() {
    if (!isSupportedMobilePlatform) {
      return const Stream<Object?>.empty();
    }
    return ProximitySensor.events;
  }
}
