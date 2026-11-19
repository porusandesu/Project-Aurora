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

    test(
      'returns no route when destination is not reachable in forward order',
      () {
        expect(planJourneys(routes, 'north', 'central'), isEmpty);
      },
    );

    test('does not create a trip from a stop to itself', () {
      expect(planJourneys(routes, 'central', 'central'), isEmpty);
    });
  });
}
