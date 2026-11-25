import 'plus_code.dart';
import 'l10n/shared_place_en.dart';

const sharedPlaceMarkerWord = 'AURORA_PLACE';
const sharedPlaceAppName = 'Aurora';

enum SharedPlacePrecision {
  around100m('100m', 10),
  around14m('14m', 10),
  around275m('275m', 8);

  const SharedPlacePrecision(this.label, this.codeLength);

  final String label;
  final int codeLength;

  static SharedPlacePrecision? parse(String value) => SharedPlacePrecision
      .values
      .where((item) => item.label == value)
      .firstOrNull;
}

class SharedPlaceMarker {
  const SharedPlaceMarker({
    required this.plusCode,
    required this.lastValidDate,
    required this.precision,
  });

  final String plusCode;
  final DateTime lastValidDate;
  final SharedPlacePrecision precision;
}

String? buildSharedPlaceMessage({
  required double latitude,
  required double longitude,
  SharedPlacePrecision precision = SharedPlacePrecision.around100m,
  int validityDays = 7,
  String note = '',
  DateTime? now,
}) {
  if (![1, 7, 30].contains(validityDays)) return null;
  final code = switch (precision) {
    SharedPlacePrecision.around100m => PlusCode.encodeRounded100m(
      latitude,
      longitude,
    ),
    _ => PlusCode.encode(latitude, longitude, codeLength: precision.codeLength),
  };
  if (code == null) return null;

  final current = now ?? DateTime.now();
  final expiry = current.isUtc
      ? DateTime.utc(current.year, current.month, current.day + validityDays)
      : DateTime(current.year, current.month, current.day + validityDays);
  final marker = _format(sharedPlaceEnglish['marker']!, {
    'markerWord': sharedPlaceMarkerWord,
    'plusCode': code,
    'lastValidDate': _date(expiry),
    'precision': precision.label,
  });
  final cleanNote = sanitizeSharedPlaceNote(note);
  final noteLine = cleanNote.isEmpty
      ? ''
      : '\n${_format(sharedPlaceEnglish['note']!, {'note': cleanNote})}';
  return _format(sharedPlaceEnglish['message']!, {
    'appName': sharedPlaceAppName,
    'marker': marker,
    'noteLine': noteLine,
  });
}

SharedPlaceMarker? parseSharedPlaceMessage(String message, {DateTime? today}) {
  final pattern = RegExp(
    '(?:^|[^A-Za-z0-9_])$sharedPlaceMarkerWord\\|([^|\\s]+)\\|(\\d{4}-\\d{2}-\\d{2})\\|(100m|14m|275m)(?![|A-Za-z0-9_])',
  );
  final current = today ?? DateTime.now();
  final currentDate = DateTime.utc(current.year, current.month, current.day);
  for (final match in pattern.allMatches(message)) {
    final code = match.group(1)!;
    final date = _parseDate(match.group(2)!);
    final precision = SharedPlacePrecision.parse(match.group(3)!);
    if (date == null ||
        date.isBefore(currentDate) ||
        precision == null ||
        !PlusCode.isValidFull(code) ||
        PlusCode.decode(code)?.codeLength != precision.codeLength) {
      continue;
    }
    return SharedPlaceMarker(
      plusCode: code.toUpperCase(),
      lastValidDate: date,
      precision: precision,
    );
  }
  return null;
}

String sanitizeSharedPlaceNote(String note) {
  final plain = note
      .replaceAll(RegExp(r'[\u0000-\u001F\u007F-\u009F]'), '')
      .replaceAll(
        RegExp(r'(?:https?://|www\.|mailto:)\S+', caseSensitive: false),
        '',
      )
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
  return String.fromCharCodes(plain.runes.take(60));
}

String _format(String template, Map<String, String> values) =>
    values.entries.fold(
      template,
      (result, entry) => result.replaceAll('{${entry.key}}', entry.value),
    );

String _date(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

DateTime? _parseDate(String value) {
  final parts = value.split('-').map(int.tryParse).toList();
  if (parts.length != 3 || parts.any((part) => part == null)) return null;
  final year = parts[0]!;
  final month = parts[1]!;
  final day = parts[2]!;
  if (year < 1 ||
      year > 9999 ||
      month < 1 ||
      month > 12 ||
      day < 1 ||
      day > 31) {
    return null;
  }
  final date = DateTime.utc(year, month, day);
  if (date.year != year || date.month != month || date.day != day) return null;
  return date;
}
