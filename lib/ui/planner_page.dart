part of '../main.dart';

class _PlanPage extends StatefulWidget {
  const _PlanPage({required this.data});

  final AppData data;

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
          const SizedBox(height: 12),
          Text(
            'About ${option.estimatedMinutes} min · estimated',
            style: TextStyle(color: _ink.withValues(alpha: .72), fontSize: 13),
          ),
          Text(
            option.totalFare == null
                ? 'Fare unavailable'
                : 'Total fare: ${option.totalFare!.toStringAsFixed(2)} ${option.currency}',
            style: TextStyle(color: _ink.withValues(alpha: .72), fontSize: 13),
          ),
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
            Text(
              'Route data: ${leg.route.verificationStatus}${leg.route.directionRule == 'unknown' ? ' · direction unverified' : ''}',
              style: TextStyle(
                color: _ink.withValues(alpha: .55),
                fontSize: 11,
              ),
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
