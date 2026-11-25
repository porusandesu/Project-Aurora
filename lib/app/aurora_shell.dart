part of '../main.dart';

class AuroraShell extends StatefulWidget {
  const AuroraShell({super.key, this.initialData});

  final AppData? initialData;

  @override
  State<AuroraShell> createState() => _AuroraShellState();
}

class _AuroraShellState extends State<AuroraShell> {
  final _database = TransitDatabase();
  late Future<AppData> _data;
  int _tab = 0;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _data = widget.initialData == null
        ? _loadData()
        : Future.value(widget.initialData);
  }

  Future<AppData> _loadData() async {
    final settingsDatabase = await openSettingsDatabase();
    try {
      final values = await Future.wait<Object>([
        _database.places(),
        _database.stops(),
        _database.routes(),
        _database.datasetVersion(),
        loadFeatureFlags(
          settingsDatabase: settingsDatabase,
          assets: rootBundle,
        ),
      ]);
      return AppData(
        places: values[0] as List<Place>,
        stops: values[1] as List<TransitStop>,
        routes: values[2] as List<RoutePattern>,
        datasetVersion: values[3] as String,
        featureFlags: values[4] as FeatureFlagSnapshot,
      );
    } finally {
      await settingsDatabase.close();
    }
  }

  @override
  void dispose() {
    _database.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<AppData>(
    future: _data,
    builder: (context, snapshot) {
      if (snapshot.hasError) {
        return _StartupError(
          onRetry: () => setState(() => _data = _loadData()),
        );
      }
      if (!snapshot.hasData) {
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      }
      final data = snapshot.data!;
      final plannerEnabled = data.featureFlags.isEnabled(
        'journey_planner',
        appVersion: _appVersion,
      );
      final pages = [
        _DiscoverPage(
          data: data,
          query: _query,
          plannerEnabled: plannerEnabled,
          onQuery: (value) => setState(() => _query = value),
          onPlan: () => setState(() => _tab = 1),
        ),
        if (plannerEnabled) _PlanPage(data: data),
        _RoutesPage(data: data),
      ];
      return Scaffold(
        body: SafeArea(
          child: IndexedStack(index: _tab, children: pages),
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _tab,
          onDestinationSelected: (index) => setState(() => _tab = index),
          destinations: [
            NavigationDestination(
              icon: Icon(Icons.explore_outlined),
              selectedIcon: Icon(Icons.explore),
              label: 'Explore',
            ),
            if (plannerEnabled)
              const NavigationDestination(
                icon: Icon(Icons.alt_route_outlined),
                selectedIcon: Icon(Icons.alt_route),
                label: 'Plan',
              ),
            NavigationDestination(
              icon: Icon(Icons.route_outlined),
              selectedIcon: Icon(Icons.route),
              label: 'Routes',
            ),
          ],
        ),
      );
    },
  );
}

class AppData {
  const AppData({
    required this.places,
    required this.stops,
    required this.routes,
    required this.datasetVersion,
    required this.featureFlags,
  });

  final List<Place> places;
  final List<TransitStop> stops;
  final List<RoutePattern> routes;
  final String datasetVersion;
  final FeatureFlagSnapshot featureFlags;
}
