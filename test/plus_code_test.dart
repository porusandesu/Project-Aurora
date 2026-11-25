import 'dart:io';

import 'package:aurora/plus_code.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('matches every published encoding case', () {
    final lines = File('test/fixtures/open_location_code/encoding.csv')
        .readAsLinesSync();
    for (final line in lines) {
      if (line.isEmpty || line.startsWith('#')) continue;
      final fields = line.split(',');
      final latitude = double.parse(fields[0]);
      final longitude = double.parse(fields[1]);
      final length = int.parse(fields[4]);
      expect(
        PlusCode.encode(latitude, longitude, codeLength: length),
        fields[5],
        reason: line,
      );
    }
  });

  test('matches every published decoding boundary', () {
    final lines = File('test/fixtures/open_location_code/decoding.csv')
        .readAsLinesSync();
    for (final line in lines) {
      if (line.isEmpty || line.startsWith('#')) continue;
      final fields = line.split(',');
      final area = PlusCode.decode(fields[0]);
      expect(area, isNotNull, reason: line);
      expect(area!.codeLength, int.parse(fields[1]), reason: line);
      expect(area.south, closeTo(double.parse(fields[2]), 1e-10), reason: line);
      expect(area.west, closeTo(double.parse(fields[3]), 1e-10), reason: line);
      expect(area.north, closeTo(double.parse(fields[4]), 1e-10), reason: line);
      expect(area.east, closeTo(double.parse(fields[5]), 1e-10), reason: line);
    }
  });

  test('has the expected 8 and 10 digit cell sizes', () {
    final eight = PlusCode.decode(PlusCode.encode(0, 0, codeLength: 8)!)!;
    final ten = PlusCode.decode(PlusCode.encode(0, 0)!)!;
    expect((eight.north - eight.south) * 111321, closeTo(278, 1));
    expect((ten.north - ten.south) * 111321, closeTo(13.9, .1));
  });

  test('rounded 100m helper rounds coordinates before encoding', () {
    expect(
      PlusCode.encodeRounded100m(12.3456, 34.5678),
      PlusCode.encode(12.346, 34.568),
    );
  });

  test('round trips a point into a containing cell', () {
    const latitude = -25.7479;
    const longitude = 28.2293;
    final area = PlusCode.decode(PlusCode.encode(latitude, longitude)!)!;
    expect(area.contains(latitude, longitude), isTrue);
  });

  test('invalid and local codes fail without throwing', () {
    for (final code in [
      'CWC8+R9',
      '849VCWCI+R9',
      '849VCWC8R9',
      '849VCWC8+2',
      'ZZ000000+',
      '849V0000+R9',
      '849VGJQF+VX7QR3J!',
    ]) {
      expect(PlusCode.isValidFull(code), isFalse, reason: code);
      expect(PlusCode.decode(code), isNull, reason: code);
    }
    expect(PlusCode.encode(double.nan, 1), isNull);
  });
}
