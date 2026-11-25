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
    this.latitude,
    this.longitude,
    this.accuracyMetres,
    this.coordinateSource,
  });

  final String id;
  final String name;
  final String area;
  final String source;
  final String verificationStatus;
  final double? latitude;
  final double? longitude;
  final double? accuracyMetres;
  final String? coordinateSource;
}

class TransitRoute {
  const TransitRoute({
    required this.id,
    required this.name,
    required this.description,
    required this.source,
    required this.verificationStatus,
    this.recognitionHint,
    this.boardingNote,
    this.dropoffRule = 'unknown',
    this.hintSource,
    this.hintVerifiedOn,
    this.directionRule = 'both_ways',
    this.transportType,
    this.fareAmount,
    this.fareCurrency,
  });

  final String id;
  final String name;
  final String description;
  final String source;
  final String verificationStatus;
  final String? recognitionHint;
  final String? boardingNote;
  final String dropoffRule;
  final String? hintSource;
  final String? hintVerifiedOn;
  final String directionRule;
  final String? transportType;
  final double? fareAmount;
  final String? fareCurrency;
}

class JourneyLeg {
  const JourneyLeg({
    required this.route,
    required this.boardingStop,
    required this.alightingStop,
    required this.stopCount,
  });

  final TransitRoute route;
  final TransitStop boardingStop;
  final TransitStop alightingStop;
  final int stopCount;
}

class JourneyOption {
  const JourneyOption({required this.legs, required this.estimatedMinutes});

  final List<JourneyLeg> legs;
  final int estimatedMinutes;
  int get changes => legs.length - 1;
  int get stopCount =>
      legs.fold(0, (total, leg) => total + leg.stopCount) - changes;
  double? get totalFare {
    if (legs.any((leg) => leg.route.fareAmount == null)) return null;
    final currencies = legs.map((leg) => leg.route.fareCurrency).toSet();
    if (currencies.length != 1) return null;
    return legs.fold(0.0, (total, leg) => total + leg.route.fareAmount!);
  }

  String? get currency =>
      totalFare == null ? null : legs.first.route.fareCurrency;
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
