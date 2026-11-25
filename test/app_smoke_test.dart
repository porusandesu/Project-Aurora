import 'package:aurora/feature_flags.dart';
import 'package:aurora/main.dart';
import 'package:aurora/models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('opens the journey planner with sample data', (tester) async {
    const central = TransitStop(
      id: 'stop-central',
      name: 'Central stop',
      area: 'Central',
      source: 'Synthetic demonstration data',
      verificationStatus: 'sample',
    );
    const library = TransitStop(
      id: 'stop-library',
      name: 'Library stop',
      area: 'North',
      source: 'Synthetic demonstration data',
      verificationStatus: 'sample',
    );

    await tester.pumpWidget(
      const AuroraApp(
        initialData: AppData(
          places: [],
          stops: [central, library],
          routes: [
            RoutePattern(
              route: TransitRoute(
                id: 'route-blue',
                name: 'Blue line',
                description: 'Sample route · not a real service',
                source: 'Synthetic demonstration data',
                verificationStatus: 'sample',
              ),
              stops: [central, library],
            ),
          ],
          datasetVersion: 'sample-1',
          featureFlags: FeatureFlagSnapshot(
            rules: {
              'journey_planner': FeatureRule(
                enabled: true,
                rolloutPercentage: 100,
                minimumAppVersion: '1.0.0',
                killSwitch: false,
              ),
            },
            rolloutBucket: 0,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Plan').last);
    await tester.pumpAndSettle();

    expect(find.text('Journey planner'), findsOneWidget);
    expect(find.text('Blue line'), findsOneWidget);
  });
}
