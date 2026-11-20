import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'feature_flags.dart';
import 'models.dart';
import 'transit_database.dart';

void main() => runApp(const AuroraApp());

const _appVersion = String.fromEnvironment(
  'AURORA_APP_VERSION',
  defaultValue: '1.0.0',
);
const _ink = Color(0xFF17352F);
const _green = Color(0xFF176B54);
const _mint = Color(0xFFDDF2E8);
const _canvas = Color(0xFFF5F7F4);

class AuroraApp extends StatelessWidget {
  const AuroraApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Aurora',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: _canvas,
      colorScheme: ColorScheme.fromSeed(
        seedColor: _green,
        brightness: Brightness.light,
      ),
      fontFamily: 'Roboto',
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
    ),
    home: const AuroraShell(),
  );
}

class AuroraShell extends StatefulWidget {
  const AuroraShell({super.key});

  @override
  State<AuroraShell> createState() => _AuroraShellState();
}

class _AuroraShellState extends State<AuroraShell> {
  final _database = TransitDatabase();
  late Future<_AppData> _data;
  int _tab = 0;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _data = _loadData();
  }

  Future<_AppData> _loadData() async {
    final database = await _database.database;
    final values = await Future.wait<Object>([
      _database.places(),
      _database.stops(),
      _database.routes(),
      _database.datasetVersion(),
      loadFeatureFlags(database: database, assets: rootBundle),
    ]);
    return _AppData(
      places: values[0] as List<Place>,
      stops: values[1] as List<TransitStop>,
      routes: values[2] as List<RoutePattern>,
      datasetVersion: values[3] as String,
      featureFlags: values[4] as FeatureFlagSnapshot,
    );
  }

  @override
  void dispose() {
    _database.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<_AppData>(
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

class _AppData {
  const _AppData({
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

class _DiscoverPage extends StatelessWidget {
  const _DiscoverPage({
    required this.data,
    required this.query,
    required this.plannerEnabled,
    required this.onQuery,
    required this.onPlan,
  });

  final _AppData data;
  final String query;
  final bool plannerEnabled;
  final ValueChanged<String> onQuery;
  final VoidCallback onPlan;

  @override
  Widget build(BuildContext context) {
    final results = searchPlaces(data.places, query);
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
          sliver: SliverList.list(
            children: [
              Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: _green,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: const Icon(
                      Icons.wb_twilight_rounded,
                      color: Colors.white,
                      size: 27,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Aurora',
                      style: TextStyle(
                        color: _ink,
                        fontSize: 23,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                  const _StatusPill(),
                ],
              ),
              const SizedBox(height: 35),
              const Text(
                'Move with a little more\nconfidence.',
                style: TextStyle(
                  color: _ink,
                  fontSize: 32,
                  height: 1.12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -1.1,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Find a place or plan a route. Your guide works offline.',
                style: TextStyle(
                  color: _ink.withValues(alpha: .67),
                  fontSize: 15,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 22),
              TextField(
                key: const ValueKey('place-search'),
                onChanged: onQuery,
                decoration: const InputDecoration(
                  hintText: 'Search a place or nickname',
                  prefixIcon: Icon(Icons.search_rounded),
                  suffixIcon: Icon(Icons.tune_rounded),
                ),
              ),
              const SizedBox(height: 18),
              if (query.trim().isNotEmpty) ...[
                Text(
                  '${results.length} ${results.length == 1 ? 'place' : 'places'} found',
                  style: const TextStyle(
                    color: _ink,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                if (results.isEmpty)
                  const _EmptyMessage(
                    text: 'No matching places in this sample guide yet.',
                  )
                else
                  ...results.map(
                    (place) => _PlaceCard(
                      place: place,
                      onTap: () => _showPlace(context, place),
                    ),
                  ),
              ] else ...[
                if (plannerEnabled) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Plan a journey',
                        style: TextStyle(
                          color: _ink,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      TextButton(
                        onPressed: onPlan,
                        child: const Text('Open planner'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _PlannerPromo(onTap: onPlan),
                ] else ...[
                  const _EmptyMessage(
                    text: 'Journey planning is not available in this rollout.',
                  ),
                ],
                const SizedBox(height: 25),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Places to explore',
                      style: TextStyle(
                        color: _ink,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      '${data.places.length} samples',
                      style: TextStyle(
                        color: _ink.withValues(alpha: .55),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ...data.places
                    .take(3)
                    .map(
                      (place) => _PlaceCard(
                        place: place,
                        onTap: () => _showPlace(context, place),
                      ),
                    ),
                const SizedBox(height: 10),
                const _SampleNotice(),
              ],
              const SizedBox(height: 22),
              Text(
                'Dataset ${data.datasetVersion} · stored on this device',
                style: TextStyle(
                  color: _ink.withValues(alpha: .5),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showPlace(BuildContext context, Place place) =>
      showModalBottomSheet<void>(
        context: context,
        showDragHandle: true,
        backgroundColor: _canvas,
        builder: (context) => Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                place.canonicalName,
                style: const TextStyle(
                  color: _ink,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                place.area,
                style: TextStyle(color: _ink.withValues(alpha: .65)),
              ),
              if (place.aliases.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text(
                  'Also called',
                  style: TextStyle(color: _ink, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 5),
                Text(place.aliases.join(' · ')),
              ],
              const SizedBox(height: 16),
              Text(
                'Sample information · ${place.source}',
                style: TextStyle(
                  color: _ink.withValues(alpha: .65),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      );
}

class _PlanPage extends StatefulWidget {
  const _PlanPage({required this.data});

  final _AppData data;

  @override
  State<_PlanPage> createState() => _PlanPageState();
}

class _PlanPageState extends State<_PlanPage> {
  late String _origin = widget.data.stops.first.id;
  late String _destination =
      widget.data.stops[min(2, widget.data.stops.length - 1)].id;

  @override
  Widget build(BuildContext context) {
    final choices = planJourneys(widget.data.routes, _origin, _destination);
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 32),
      children: [
        const Text(
          'Journey planner',
          style: TextStyle(
            color: _ink,
            fontSize: 29,
            fontWeight: FontWeight.w800,
            letterSpacing: -.8,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Choose stops manually. No location access needed.',
          style: TextStyle(color: _ink.withValues(alpha: .65), fontSize: 14),
        ),
        const SizedBox(height: 24),
        _StopDropdown(
          label: 'Starting point',
          value: _origin,
          stops: widget.data.stops,
          onChanged: (value) => setState(() => _origin = value),
        ),
        const SizedBox(height: 12),
        Center(
          child: Icon(Icons.south_rounded, color: _green.withValues(alpha: .8)),
        ),
        const SizedBox(height: 12),
        _StopDropdown(
          label: 'Destination',
          value: _destination,
          stops: widget.data.stops,
          onChanged: (value) => setState(() => _destination = value),
        ),
        const SizedBox(height: 24),
        const Text(
          'Your options',
          style: TextStyle(
            color: _ink,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 10),
        if (_origin == _destination)
          const _EmptyMessage(
            text: 'Choose two different stops to see a journey.',
          )
        else if (choices.isEmpty)
          const _EmptyMessage(text: 'No sample route connects these stops yet.')
        else
          ...choices.map((option) => _JourneyCard(option: option)),
        const SizedBox(height: 12),
        const _SampleNotice(),
      ],
    );
  }
}

int min(int a, int b) => a < b ? a : b;

class _StopDropdown extends StatelessWidget {
  const _StopDropdown({
    required this.label,
    required this.value,
    required this.stops,
    required this.onChanged,
  });

  final String label;
  final String value;
  final List<TransitStop> stops;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) => DropdownButtonFormField<String>(
    key: ValueKey(label),
    initialValue: value,
    isExpanded: true,
    decoration: InputDecoration(
      labelText: label,
      prefixIcon: const Icon(Icons.place_outlined),
    ),
    items: stops
        .map(
          (stop) => DropdownMenuItem(
            value: stop.id,
            child: Text(
              '${stop.name} · ${stop.area}',
              overflow: TextOverflow.ellipsis,
            ),
          ),
        )
        .toList(),
    onChanged: (next) {
      if (next != null) onChanged(next);
    },
  );
}

class _JourneyCard extends StatelessWidget {
  const _JourneyCard({required this.option});

  final JourneyOption option;

  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: 10),
    color: Colors.white,
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(18),
      side: const BorderSide(color: Color(0xFFE6ECE7)),
    ),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.directions_transit_rounded, color: _green),
              const SizedBox(width: 8),
              Text(
                option.legs.length == 1 ? 'Direct route' : '1 transfer',
                style: const TextStyle(
                  color: _ink,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              const _SampleTag(),
            ],
          ),
          const SizedBox(height: 12),
          for (var i = 0; i < option.legs.length; i++) ...[
            if (i > 0)
              const Padding(
                padding: EdgeInsets.only(left: 8, top: 4, bottom: 4),
                child: Icon(Icons.swap_vert_rounded, size: 18, color: _green),
              ),
            _JourneyLegRow(leg: option.legs[i]),
          ],
        ],
      ),
    ),
  );
}

class _JourneyLegRow extends StatelessWidget {
  const _JourneyLegRow({required this.leg});
  final JourneyLeg leg;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Container(
        width: 28,
        height: 28,
        alignment: Alignment.center,
        decoration: const BoxDecoration(color: _mint, shape: BoxShape.circle),
        child: const Icon(
          Icons.directions_bus_outlined,
          size: 16,
          color: _green,
        ),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              leg.route.name,
              style: const TextStyle(color: _ink, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 3),
            Text(
              '${leg.boardingStop.name} → ${leg.alightingStop.name}',
              style: TextStyle(
                color: _ink.withValues(alpha: .67),
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    ],
  );
}

class _RoutesPage extends StatelessWidget {
  const _RoutesPage({required this.data});
  final _AppData data;

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.fromLTRB(20, 22, 20, 32),
    children: [
      const Text(
        'Routes',
        style: TextStyle(
          color: _ink,
          fontSize: 29,
          fontWeight: FontWeight.w800,
          letterSpacing: -.8,
        ),
      ),
      const SizedBox(height: 8),
      Text(
        'Browse the routes included in this offline sample.',
        style: TextStyle(color: _ink.withValues(alpha: .65), fontSize: 14),
      ),
      const SizedBox(height: 20),
      ...data.routes.map(
        (pattern) => Card(
          color: Colors.white,
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: const BorderSide(color: Color(0xFFE6ECE7)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.route_rounded, color: _green),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Text(
                        pattern.route.name,
                        style: const TextStyle(
                          color: _ink,
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const _SampleTag(),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  pattern.stops.map((stop) => stop.name).join('  ·  '),
                  style: TextStyle(
                    color: _ink.withValues(alpha: .68),
                    height: 1.55,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      const _SampleNotice(),
    ],
  );
}

class _PlaceCard extends StatelessWidget {
  const _PlaceCard({required this.place, required this.onTap});
  final Place place;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Card(
    color: Colors.white,
    elevation: 0,
    margin: const EdgeInsets.only(bottom: 8),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
      side: const BorderSide(color: Color(0xFFE6ECE7)),
    ),
    child: ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 3),
      leading: Container(
        width: 40,
        height: 40,
        decoration: const BoxDecoration(color: _mint, shape: BoxShape.circle),
        child: const Icon(Icons.place_rounded, color: _green, size: 20),
      ),
      title: Text(
        place.canonicalName,
        style: const TextStyle(color: _ink, fontWeight: FontWeight.w700),
      ),
      subtitle: Text(
        place.matchedAlias == null
            ? place.area
            : 'Also called: ${place.matchedAlias} · ${place.area}',
        style: TextStyle(color: _ink.withValues(alpha: .62)),
      ),
      trailing: const Icon(Icons.chevron_right_rounded, color: _green),
    ),
  );
}

class _PlannerPromo extends StatelessWidget {
  const _PlannerPromo({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: _ink,
    borderRadius: BorderRadius.circular(22),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Padding(
        padding: const EdgeInsets.all(19),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: .12),
                borderRadius: BorderRadius.circular(15),
              ),
              child: const Icon(
                Icons.alt_route_rounded,
                color: Color(0xFFA7E6C6),
              ),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'From here to there',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Choose stops and compare routes',
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_rounded, color: Colors.white),
          ],
        ),
      ),
    ),
  );
}

class _StatusPill extends StatelessWidget {
  const _StatusPill();
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
    decoration: BoxDecoration(
      color: _mint,
      borderRadius: BorderRadius.circular(20),
    ),
    child: const Row(
      children: [
        Icon(Icons.wifi_off_rounded, size: 14, color: _green),
        SizedBox(width: 5),
        Text(
          'OFFLINE READY',
          style: TextStyle(
            color: _green,
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: .35,
          ),
        ),
      ],
    ),
  );
}

class _SampleTag extends StatelessWidget {
  const _SampleTag();
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: const Color(0xFFFFF0CF),
      borderRadius: BorderRadius.circular(20),
    ),
    child: const Text(
      'SAMPLE',
      style: TextStyle(
        color: Color(0xFF755313),
        fontSize: 9,
        fontWeight: FontWeight.w800,
        letterSpacing: .4,
      ),
    ),
  );
}

class _SampleNotice extends StatelessWidget {
  const _SampleNotice();
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(13),
    decoration: BoxDecoration(
      color: const Color(0xFFFFF8E8),
      borderRadius: BorderRadius.circular(14),
    ),
    child: const Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.info_outline_rounded, size: 18, color: Color(0xFF755313)),
        SizedBox(width: 9),
        Expanded(
          child: Text(
            'Demonstration data only. Stops and routes shown here are fictional and are not travel advice.',
            style: TextStyle(
              color: Color(0xFF624D24),
              fontSize: 12,
              height: 1.4,
            ),
          ),
        ),
      ],
    ),
  );
}

class _EmptyMessage extends StatelessWidget {
  const _EmptyMessage({required this.text});
  final String text;
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
    ),
    child: Text(text, style: TextStyle(color: _ink.withValues(alpha: .66))),
  );
}

class _StartupError extends StatelessWidget {
  const _StartupError({required this.onRetry});
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.storage_rounded, color: _green, size: 44),
            const SizedBox(height: 14),
            const Text(
              'Could not open the local guide',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _ink,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your device data is still private. Try opening the guide again.',
              textAlign: TextAlign.center,
              style: TextStyle(color: _ink.withValues(alpha: .67)),
            ),
            const SizedBox(height: 16),
            FilledButton(onPressed: onRetry, child: const Text('Try again')),
          ],
        ),
      ),
    ),
  );
}
