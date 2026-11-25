part of '../main.dart';

class _DiscoverPage extends StatelessWidget {
  const _DiscoverPage({
    required this.data,
    required this.query,
    required this.plannerEnabled,
    required this.onQuery,
    required this.onPlan,
  });

  final AppData data;
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
