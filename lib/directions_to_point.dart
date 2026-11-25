import 'dart:math' as math;

import 'models.dart';
import 'transit_database.dart' show planJourneys;

const _earthRadiusMetres = 6371000.0;
const _atTheStopMetres = 14.0;
const _walkingMetresPerMinute = 80.0;

class PointDirectionsResult {
  const PointDirectionsResult({
    required this.options,
    required this.nearestStops,
  });

  final List<PointJourneyOption> options;
  final List<NearbyStop> nearestStops;
  bool get hasRoute => options.isNotEmpty;
}

class PointJourneyOption {
  const PointJourneyOption({
    required this.journey,
    required this.dropoffStop,
    required this.approximateWalkMetres,
    required this.estimatedTotalMinutes,
  });

  final JourneyOption journey;
  final TransitStop dropoffStop;
  final double approximateWalkMetres;
  final int estimatedTotalMinutes;

  // Absorb floating-point error for a point exactly on the 14 m boundary.
  bool get atTheStop => approximateWalkMetres <= _atTheStopMetres + 1e-6;
}

class NearbyStop {
  const NearbyStop({
    required this.stop,
    required this.approximateDistanceMetres,
  });

  final TransitStop stop;
  final double approximateDistanceMetres;
}

PointDirectionsResult? directionsToPoint({
  required List<RoutePattern> routes,
  required List<TransitStop> stops,
  required String originStopId,
  required double latitude,
  required double longitude,
}) {
  if (!_validCoordinate(latitude, longitude)) return null;
  final uniqueStops = <String, TransitStop>{};
  for (final stop in stops) {
    uniqueStops.putIfAbsent(stop.id, () => stop);
  }
  final nearby = <NearbyStop>[];
  for (final stop in uniqueStops.values) {
    final distance = _distanceToPoint(stop, latitude, longitude);
    if (distance != null) {
      nearby.add(NearbyStop(stop: stop, approximateDistanceMetres: distance));
    }
  }
  nearby.sort((a, b) {
    final distance = a.approximateDistanceMetres.compareTo(
      b.approximateDistanceMetres,
    );
    if (distance != 0) return distance;
    final name = a.stop.name.toLowerCase().compareTo(b.stop.name.toLowerCase());
    return name != 0 ? name : a.stop.id.compareTo(b.stop.id);
  });

  final options = <PointJourneyOption>[];
  for (final stop in uniqueStops.values) {
    if (stop.id == originStopId) continue;
    final distance = _distanceToPoint(stop, latitude, longitude);
    if (distance == null) continue;
    for (final journey in planJourneys(routes, originStopId, stop.id)) {
      // shortcut: walking time assumes 80 m/min; replace with verified, accessible walking routes.
      final walkMinutes = (distance / _walkingMetresPerMinute).ceil();
      options.add(
        PointJourneyOption(
          journey: journey,
          dropoffStop: stop,
          approximateWalkMetres: distance,
          estimatedTotalMinutes: journey.estimatedMinutes + walkMinutes,
        ),
      );
    }
  }
  options.sort((a, b) {
    final time = a.estimatedTotalMinutes.compareTo(b.estimatedTotalMinutes);
    if (time != 0) return time;
    final changes = a.journey.changes.compareTo(b.journey.changes);
    if (changes != 0) return changes;
    final distance = a.approximateWalkMetres.compareTo(b.approximateWalkMetres);
    return distance != 0
        ? distance
        : a.dropoffStop.id.compareTo(b.dropoffStop.id);
  });
  return PointDirectionsResult(
    options: options,
    nearestStops: options.isEmpty ? nearby : const [],
  );
}

double? haversineDistanceMetres(
  double latitude1,
  double longitude1,
  double latitude2,
  double longitude2,
) {
  if (!_validCoordinate(latitude1, longitude1) ||
      !_validCoordinate(latitude2, longitude2)) {
    return null;
  }
  final lat1 = _radians(latitude1);
  final lat2 = _radians(latitude2);
  final deltaLat = lat2 - lat1;
  final deltaLon = _radians(longitude2 - longitude1);
  final haversine =
      math.pow(math.sin(deltaLat / 2), 2) +
      math.cos(lat1) * math.cos(lat2) * math.pow(math.sin(deltaLon / 2), 2);
  final centralAngle =
      2 * math.asin(math.sqrt((haversine as num).toDouble().clamp(0.0, 1.0)));
  return _earthRadiusMetres * centralAngle;
}

double? _distanceToPoint(TransitStop stop, double latitude, double longitude) {
  if (stop.latitude == null || stop.longitude == null) return null;
  return haversineDistanceMetres(
    stop.latitude!,
    stop.longitude!,
    latitude,
    longitude,
  );
}

bool _validCoordinate(double latitude, double longitude) =>
    latitude.isFinite &&
    longitude.isFinite &&
    latitude >= -90 &&
    latitude <= 90 &&
    longitude >= -180 &&
    longitude <= 180;

double _radians(double degrees) => degrees * math.pi / 180;
