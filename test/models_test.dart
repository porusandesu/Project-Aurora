import 'package:flutter_test/flutter_test.dart';
import 'package:aurora/feature_flags.dart';
import 'package:aurora/models.dart';
import 'package:aurora/transit_database.dart';

void main() {
  group('feature rollout gates', () {
    const rule = FeatureRule(
      enabled: true,
      rolloutPercentage: 25,
      minimumAppVersion: '1.2.0',
      killSwitch: false,
    );

    test('keeps a stable bucket in or out of the percentage cohort', () {
      expect(
        const FeatureFlagSnapshot(
          rules: {'journey_planner': rule},
          rolloutBucket: 24,
        ).isEnabled('journey_planner', appVersion: '1.2.0'),
        isTrue,
      );
      expect(
        const FeatureFlagSnapshot(
          rules: {'journey_planner': rule},
          rolloutBucket: 25,
        ).isEnabled('journey_planner', appVersion: '1.2.0'),
        isFalse,
      );
    });

    test('honors kill switches and minimum app versions', () {
      const snapshot = FeatureFlagSnapshot(
        rules: {
          'journey_planner': FeatureRule(
            enabled: true,
            rolloutPercentage: 100,
            minimumAppVersion: '2.0.0',
            killSwitch: true,
          ),
        },
        rolloutBucket: 0,
      );
      expect(
        snapshot.isEnabled('journey_planner', appVersion: '3.0.0'),
        isFalse,
      );
      expect(
        const FeatureFlagSnapshot(
          rules: {'journey_planner': rule},
          rolloutBucket: 0,
        ).isEnabled('journey_planner', appVersion: '1.1.9'),
        isFalse,
      );
    });

    test(
      'refuses unknown feature names even when a manifest declares them',
      () {
        const snapshot = FeatureFlagSnapshot(
          rules: {
            'location_upload': FeatureRule(
              enabled: true,
              rolloutPercentage: 100,
              minimumAppVersion: '1.0.0',
              killSwitch: false,
            ),
          },
          rolloutBucket: 0,
        );
        expect(
          snapshot.isEnabled('location_upload', appVersion: '1.0.0'),
          isFalse,
        );
      },
    );
  });

  group('place search', () {
    const places = [
      Place(
        id: 'library',
        canonicalName: 'North library',
        area: 'North',
        stopId: 'north-stop',
        source: 'Synthetic test data',
        verificationStatus: 'sample',
        aliases: ['old library'],
      ),
    ];

    test('matches a canonical name without changing its title', () {
      final result = searchPlaces(places, '  NORTH   LIBRARY ');
      expect(result, hasLength(1));
      expect(result.single.canonicalName, 'North library');
      expect(result.single.matchedAlias, isNull);
    });

    test('matches aliases and preserves the matched alias for display', () {
      final result = searchPlaces(places, ' OLD library ');
      expect(result, hasLength(1));
      expect(result.single.canonicalName, 'North library');
      expect(result.single.matchedAlias, 'old library');
    });

    test('does not return places for an empty query', () {
      expect(searchPlaces(places, '  '), isEmpty);
    });
  });

  group('journey planning', () {
    const central = TransitStop(
      id: 'central',
      name: 'Central',
      area: 'A',
      source: 'sample',
      verificationStatus: 'sample',
    );
    const market = TransitStop(
      id: 'market',
      name: 'Market',
      area: 'A',
      source: 'sample',
      verificationStatus: 'sample',
    );
    const north = TransitStop(
      id: 'north',
      name: 'North',
      area: 'B',
      source: 'sample',
      verificationStatus: 'sample',
    );
    const south = TransitStop(
      id: 'south',
      name: 'South',
      area: 'C',
      source: 'sample',
      verificationStatus: 'sample',
    );
    const blue = TransitRoute(
      id: 'blue',
      name: 'Blue',
      description: 'sample',
      source: 'sample',
      verificationStatus: 'sample',
    );
    const green = TransitRoute(
      id: 'green',
      name: 'Green',
      description: 'sample',
      source: 'sample',
      verificationStatus: 'sample',
    );
    const routes = [
      RoutePattern(route: blue, stops: [central, market, north]),
      RoutePattern(route: green, stops: [market, south]),
    ];

    test('finds a direct route and keeps boarding order', () {
      final options = planJourneys([routes.first], 'central', 'north');
      expect(options, hasLength(1));
      expect(options.single.legs.single.route.id, 'blue');
      expect(options.single.legs.single.boardingStop.id, 'central');
      expect(options.single.legs.single.alightingStop.id, 'north');
    });

    test('finds a single transfer at a shared stop', () {
      final options = planJourneys(routes, 'central', 'south');
      expect(options, hasLength(1));
      expect(options.single.legs, hasLength(2));
      expect(options.single.legs[0].alightingStop.id, 'market');
      expect(options.single.legs[1].boardingStop.id, 'market');
      expect(options.single.legs[1].alightingStop.id, 'south');
    });

    test('supports a transfer with both legs travelled in reverse', () {
      final option = planJourneys(routes, 'south', 'central').single;
      expect(option.legs[0].boardingStop.id, 'south');
      expect(option.legs[0].alightingStop.id, 'market');
      expect(option.legs[1].boardingStop.id, 'market');
      expect(option.legs[1].alightingStop.id, 'central');
    });

    test('finds travel in reverse stop order on two-way routes', () {
      final option = planJourneys([routes.first], 'north', 'central').single;
      expect(option.legs.single.boardingStop.id, 'north');
      expect(option.legs.single.alightingStop.id, 'central');
    });

    test('enforces one-way rules and treats unknown direction as unverified both ways', () {
      final outbound = RoutePattern(
        route: const TransitRoute(
          id: 'out',
          name: 'Out',
          description: '',
          source: '',
          verificationStatus: 'verified',
          directionRule: 'outbound_only',
        ),
        stops: routes.first.stops,
      );
      expect(planJourneys([outbound], 'north', 'central'), isEmpty);
      final inbound = RoutePattern(
        route: const TransitRoute(
          id: 'in',
          name: 'In',
          description: '',
          source: '',
          verificationStatus: 'verified',
          directionRule: 'inbound_only',
        ),
        stops: routes.first.stops,
      );
      expect(planJourneys([inbound], 'north', 'central'), hasLength(1));
      final unknown = RoutePattern(
        route: const TransitRoute(
          id: 'unknown',
          name: 'Unknown',
          description: '',
          source: '',
          verificationStatus: 'unverified',
          directionRule: 'unknown',
        ),
        stops: routes.first.stops,
      );
      expect(planJourneys([unknown], 'north', 'central'), hasLength(1));
    });

    test('reports an estimated duration and sums fares for every leg', () {
      final priced = RoutePattern(
        route: const TransitRoute(
          id: 'priced',
          name: 'Priced',
          description: '',
          source: '',
          verificationStatus: 'sample',
          fareAmount: 2,
          fareCurrency: 'SAMPLE',
        ),
        stops: routes.first.stops,
      );
      final option = planJourneys([priced], 'central', 'north').single;
      expect(option.estimatedMinutes, 8);
      expect(option.totalFare, 2);
      expect(option.currency, 'SAMPLE');
      expect(option.stopCount, 3);
    });

    test('ranks shorter options before slower transfers', () {
      final direct = RoutePattern(
        route: const TransitRoute(
          id: 'direct',
          name: 'Direct',
          description: '',
          source: '',
          verificationStatus: 'sample',
        ),
        stops: [central, market, south],
      );
      final options = planJourneys([...routes, direct], 'central', 'south');
      expect(options.first.legs.single.route.id, 'direct');
      expect(options.last.changes, 1);
    });

    test('de-duplicates the same route and transfer combination', () {
      final duplicated = [...routes, routes.first];
      expect(planJourneys(duplicated, 'central', 'south'), hasLength(1));
    });

    test('does not create a trip from a stop to itself', () {
      expect(planJourneys(routes, 'central', 'central'), isEmpty);
    });
  });
}
