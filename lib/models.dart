class Place {
  const Place({
    required this.id,
    required this.canonicalName,
    required this.area,
    required this.stopId,
    required this.source,
    required this.verificationStatus,
    this.matchedAlias,
    this.aliases = const [],
  });

  final String id;
  final String canonicalName;
  final String area;
  final String stopId;
  final String source;
  final String verificationStatus;
  final String? matchedAlias;
  final List<String> aliases;

  Place withMatch(String? alias) => Place(
    id: id,
    canonicalName: canonicalName,
    area: area,
    stopId: stopId,
    source: source,
    verificationStatus: verificationStatus,
    matchedAlias: alias,
    aliases: aliases,
  );
}

class TransitStop {
  const TransitStop({
    required this.id,
    required this.name,
    required this.area,
    required this.source,
    required this.verificationStatus,
  });

  final String id;
  final String name;
  final String area;
  final String source;
  final String verificationStatus;
}

class TransitRoute {
  const TransitRoute({
    required this.id,
    required this.name,
    required this.description,
    required this.source,
    required this.verificationStatus,
  });

  final String id;
  final String name;
  final String description;
  final String source;
  final String verificationStatus;
}

class JourneyLeg {
  const JourneyLeg({
    required this.route,
    required this.boardingStop,
    required this.alightingStop,
  });

  final TransitRoute route;
  final TransitStop boardingStop;
  final TransitStop alightingStop;
}

class JourneyOption {
  const JourneyOption({required this.legs});

  final List<JourneyLeg> legs;
}

class RoutePattern {
  const RoutePattern({required this.route, required this.stops});

  final TransitRoute route;
  final List<TransitStop> stops;
}

String normalizeSearch(String value) =>
    value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');

List<Place> searchPlaces(Iterable<Place> places, String query) {
  final normalized = normalizeSearch(query);
  if (normalized.isEmpty) return const [];
  final matches = <Place>[];
  for (final place in places) {
    final canonical = normalizeSearch(place.canonicalName);
    if (canonical.contains(normalized)) {
      matches.add(place.withMatch(null));
      continue;
    }
    final alias = place.aliases.cast<String?>().firstWhere(
      (candidate) => normalizeSearch(candidate!).contains(normalized),
      orElse: () => null,
    );
    if (alias != null) matches.add(place.withMatch(alias));
  }
  return matches;
}
