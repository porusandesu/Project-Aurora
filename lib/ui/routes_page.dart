part of '../main.dart';

class _RoutesPage extends StatelessWidget {
  const _RoutesPage({required this.data});
  final AppData data;

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
