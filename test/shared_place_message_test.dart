import 'package:aurora/plus_code.dart';
import 'package:aurora/shared_place_message.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final today = DateTime.utc(2026, 11, 25);

  test('builds the default 100m message with a seven-day validity', () {
    final message = buildSharedPlaceMessage(
      latitude: 12.3456,
      longitude: 34.5678,
      now: today,
    )!;
    expect(message, contains('A place shared from Aurora:'));
    expect(message, contains('AURORA_PLACE|'));
    expect(message, contains('|2026-12-02|100m'));
    final parsed = parseSharedPlaceMessage(message, today: today)!;
    expect(parsed.precision, SharedPlacePrecision.around100m);
    expect(parsed.lastValidDate, DateTime.utc(2026, 12, 2));
    expect(PlusCode.decode(parsed.plusCode)?.codeLength, 10);
  });

  test('supports the three precisions and allowed validity periods', () {
    for (final choice in [
      (SharedPlacePrecision.around100m, 10),
      (SharedPlacePrecision.around14m, 10),
      (SharedPlacePrecision.around275m, 8),
    ]) {
      final message = buildSharedPlaceMessage(
        latitude: 12.3456,
        longitude: 34.5678,
        precision: choice.$1,
        validityDays: 1,
        now: today,
      )!;
      expect(message, contains('|2026-11-26|${choice.$1.label}'));
      expect(
        PlusCode.decode(
          parseSharedPlaceMessage(message, today: today)!.plusCode,
        )?.codeLength,
        choice.$2,
      );
    }
    for (final days in [1, 7, 30]) {
      expect(
        buildSharedPlaceMessage(
          latitude: 0,
          longitude: 0,
          validityDays: days,
          now: today,
        ),
        isNotNull,
      );
    }
    expect(
      buildSharedPlaceMessage(
        latitude: 0,
        longitude: 0,
        validityDays: 2,
        now: today,
      ),
      isNull,
    );
  });

  test('parses the first valid marker in surrounding multiline text', () {
    final code = PlusCode.encode(12.345, 34.568)!;
    final message = '''🚌 AURORA_PLACE|invalid|2026-12-02|14m
Shared by a friend: AURORA_PLACE|$code|2026-11-25|14m thanks!''';
    final marker = parseSharedPlaceMessage(message, today: today)!;
    expect(marker.plusCode, code);
    expect(marker.precision, SharedPlacePrecision.around14m);
  });

  test('rejects malformed, expired, and precision-mismatched markers', () {
    final code10 = PlusCode.encode(12.345, 34.568)!;
    final code8 = PlusCode.encode(12.345, 34.568, codeLength: 8)!;
    for (final marker in [
      'AURORA_PLACE|CWC8+R9|2026-12-02|14m',
      'AURORA_PLACE|$code10|2026-02-30|14m',
      'AURORA_PLACE|$code10|2026-11-24|14m',
      'AURORA_PLACE|$code10|2026-12-02|unknown',
      'AURORA_PLACE|$code10|2026-12-02|14m|extra',
      'AURORA_PLACE|$code8|2026-12-02|14m',
    ]) {
      expect(
        parseSharedPlaceMessage(marker, today: today),
        isNull,
        reason: marker,
      );
    }
    expect(
      parseSharedPlaceMessage(
        'AURORA_PLACE|$code10|2026-11-25|14m',
        today: today,
      ),
      isNotNull,
    );
  });

  test('sanitizes note controls and links and caps it at 60 code points', () {
    final message = buildSharedPlaceMessage(
      latitude: 0,
      longitude: 0,
      now: today,
      note: 'Gate\u0001 near https://example.com 🚍 ${'x' * 61}',
    )!;
    final note = message.split('Note: ').last;
    expect(note, isNot(contains('http')));
    expect(note, isNot(contains('\u0001')));
    expect(note.runes.length, 60);
  });

  test('rejects coordinates outside the sharing range', () {
    expect(buildSharedPlaceMessage(latitude: 91, longitude: 0), isNull);
    expect(
      buildSharedPlaceMessage(latitude: 0, longitude: double.infinity),
      isNull,
    );
  });
}
