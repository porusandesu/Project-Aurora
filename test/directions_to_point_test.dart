import 'dart:math' as math;

import 'package:aurora/directions_to_point.dart';
import 'package:aurora/models.dart';
import 'package:flutter_test/flutter_test.dart';

TransitStop _stop(
  String id, {
  double? latitude,
  double? longitude,
  String verificationStatus = 'verified',
}) => TransitStop(
  id: id,
  name: id,
  area: 'Test area',
  source: 'Synthetic test data',
  verificationStatus: verificationStatus,
  latitude: latitude,
  longitude: longitude,
  coordinateSource: latitude == null ? null : 'Synthetic test coordinate',
);

TransitRoute _route(String id, {String verificationStatus = 'verified'}) =>
    TransitRoute(
      id: id,
      name: id,
      description: 'Synthetic test route',
      source: 'Synthetic test data',
      verificationStatus: verificationStatus,
    );

void main() {
  test('haversine distance is approximate and validates coordinates', () {
    expect(haversineDistanceMetres(0, 0, 1, 0), closeTo(111195, 5));
    expect(haversineDistanceMetres(91, 0, 0, 0), isNull);
    expect(haversineDistanceMetres(0, 0, double.nan, 0), isNull);
  });

  test('flags 14.0 metres at the stop and 14.1 metres as a walk', () {
    double latitudeFor(double metres) =>
        2 * math.asin(metres / (2 * 6371000)) * 180 / math.pi;
    final origin = _stop('origin', latitude: 0, longitude: 0);
    final at14 = _stop('at-14', latitude: latitudeFor(14), longitude: 0);
    final at14_1 = _stop('at-14-1', latitude: latitudeFor(14.1), longitude: 0);
    final result = directionsToPoint(
      routes: [
        RoutePattern(route: _route('bus'), stops: [origin, at14, at14_1]),
      ],
      stops: [origin, at14, at14_1],
      originStopId: origin.id,
      latitude: 0,
      longitude: 0,
    )!;
    final options = {
      for (final option in result.options) option.dropoffStop.id: option,
    };
    expect(options['at-14']!.approximateWalkMetres, closeTo(14, 1e-9));
    expect(options['at-14']!.atTheStop, isTrue);
    expect(options['at-14-1']!.approximateWalkMetres, closeTo(14.1, 1e-9));
    expect(options['at-14-1']!.atTheStop, isFalse);
  });

  test(
    'returns direct and one-change directions with each leg verification',
    () {
      final origin = _stop('origin', latitude: 0, longitude: 0);
      final transfer = _stop('transfer', latitude: .01, longitude: 0);
      final destination = _stop('destination', latitude: 0, longitude: 0);
      final directDestination = _stop('direct', latitude: 0, longitude: .01);
      final routes = [
        RoutePattern(
          route: _route('first', verificationStatus: 'verified'),
          stops: [origin, transfer],
        ),
        RoutePattern(
          route: _route('second', verificationStatus: 'unverified'),
          stops: [transfer, destination],
        ),
        RoutePattern(
          route: _route('direct', verificationStatus: 'sample'),
          stops: [origin, directDestination],
        ),
      ];
      final result = directionsToPoint(
        routes: routes,
        stops: [origin, transfer, destination, directDestination],
        originStopId: origin.id,
        latitude: 0,
        longitude: 0,
      )!;

      expect(result.hasRoute, isTrue);
      final transferOption = result.options.firstWhere(
        (option) => option.dropoffStop.id == destination.id,
      );
      expect(transferOption.journey.legs, hasLength(2));
      expect(
        transferOption.journey.legs.map((leg) => leg.route.verificationStatus),
        ['verified', 'unverified'],
      );
      expect(
        result.options.every((option) => option.journey.legs.length <= 2),
        isTrue,
      );
    },
  );

  test(
    'ranks by total estimate, then changes, then shorter walking distance',
    () {
      final origin = _stop('origin', latitude: 0, longitude: 0);
      final midpoint = _stop('midpoint', latitude: .001, longitude: 0);
      final fartherDirect = _stop('far-direct', latitude: .00288, longitude: 0);
      final hub = _stop('hub', latitude: .01, longitude: 0);
      final transferDestination = _stop(
        'transfer-destination',
        latitude: 0,
        longitude: 0,
      );
      final shortWalk = _stop(
        'short-walk',
        latitude: 20 / 111195,
        longitude: 0,
      );
      final longWalk = _stop('long-walk', latitude: 70 / 111195, longitude: 0);
      final routes = [
        RoutePattern(
          route: _route('direct'),
          stops: [origin, midpoint, fartherDirect],
        ),
        RoutePattern(route: _route('first'), stops: [origin, hub]),
        RoutePattern(
          route: _route('second'),
          stops: [hub, transferDestination],
        ),
        RoutePattern(
          route: _route('walks'),
          stops: [origin, shortWalk, longWalk],
        ),
      ];
      final result = directionsToPoint(
        routes: routes,
        stops: [
          origin,
          midpoint,
          fartherDirect,
          hub,
          transferDestination,
          shortWalk,
          longWalk,
        ],
        originStopId: origin.id,
        latitude: 0,
        longitude: 0,
      )!;
      final directAtTie = result.options.indexWhere(
        (option) => option.dropoffStop.id == fartherDirect.id,
      );
      final transferAtTie = result.options.indexWhere(
        (option) => option.dropoffStop.id == transferDestination.id,
      );
      expect(result.options[directAtTie].estimatedTotalMinutes, 13);
      expect(result.options[transferAtTie].estimatedTotalMinutes, 13);
      expect(directAtTie, lessThan(transferAtTie));

      final closeOptions = result.options
          .where(
            (option) =>
                {'short-walk', 'long-walk'}.contains(option.dropoffStop.id),
          )
          .toList();
      expect(closeOptions.first.dropoffStop.id, 'short-walk');
    },
  );

  test('shows all nearby stops if no route connects, including far stops', () {
    final origin = _stop('origin', latitude: 0, longitude: 0);
    final unservedNear = _stop('near', latitude: 0, longitude: .001);
    final unservedFar = _stop('far', latitude: 0, longitude: 1);
    final noCoordinates = _stop('unknown');
    final disconnected = RoutePattern(
      route: _route('disconnected'),
      stops: [unservedNear, unservedFar],
    );
    final result = directionsToPoint(
      routes: [disconnected],
      stops: [origin, unservedFar, noCoordinates, unservedNear],
      originStopId: origin.id,
      latitude: 0,
      longitude: 0,
    )!;

    expect(result.hasRoute, isFalse);
    expect(result.options, isEmpty);
    expect(result.nearestStops.map((item) => item.stop.id), [
      'origin',
      'near',
      'far',
    ]);
    expect(
      result.nearestStops.last.approximateDistanceMetres,
      greaterThan(100000),
    );
    expect(result.nearestStops.any((item) => item.stop.id == 'far'), isTrue);
  });

  test('rejects invalid point coordinates', () {
    expect(
      directionsToPoint(
        routes: const [],
        stops: const [],
        originStopId: 'origin',
        latitude: 91,
        longitude: 0,
      ),
      isNull,
    );
  });
}
