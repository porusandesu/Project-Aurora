import 'dart:math' as math;

const _alphabet = '23456789CFGHJMPQRVWX';
const _separator = '+';
const _separatorPosition = 8;
const _pairResolutions = [20.0, 1.0, 0.05, 0.0025, 0.000125];

int _scaledInteger(double value) {
  final nearest = value.roundToDouble();
  return (value - nearest).abs() < 1e-7 ? nearest.toInt() : value.floor();
}

class PlusCodeArea {
  const PlusCodeArea({
    required this.south,
    required this.west,
    required this.north,
    required this.east,
    required this.codeLength,
  });

  final double south;
  final double west;
  final double north;
  final double east;
  final int codeLength;

  double get latitude => (south + north) / 2;
  double get longitude => (west + east) / 2;

  bool contains(double latitude, double longitude) =>
      latitude >= south &&
      latitude <= north &&
      longitude >= west &&
      longitude <= east;
}

class PlusCode {
  PlusCode._();

  static bool isValidFull(String code) {
    final normalized = code.toUpperCase();
    if (normalized.indexOf(_separator) != _separatorPosition ||
        normalized.lastIndexOf(_separator) != _separatorPosition ||
        normalized.length > _separatorPosition + 1 + 7) {
      return false;
    }
    final before = normalized.substring(0, _separatorPosition);
    final after = normalized.substring(_separatorPosition + 1);
    final firstPadding = before.indexOf('0');
    final padded = firstPadding >= 0;
    if (padded) {
      if (after.isNotEmpty ||
          firstPadding < 2 ||
          firstPadding.isOdd ||
          before.substring(0, firstPadding).contains('0') ||
          before.substring(firstPadding).split('').any((c) => c != '0')) {
        return false;
      }
    } else if (after.length + before.length < 8 ||
        after.length + before.length == 9) {
      return false;
    }
    if (before
            .replaceAll('0', '')
            .split('')
            .any((c) => !_alphabet.contains(c)) ||
        after.split('').any((c) => !_alphabet.contains(c))) {
      return false;
    }
    final area = _decodeUnchecked(normalized);
    return area.south >= -90 &&
        area.north <= 90 &&
        area.west >= -180 &&
        area.east <= 180;
  }

  static String? encode(
    double latitude,
    double longitude, {
    int codeLength = 10,
  }) {
    if (!latitude.isFinite || !longitude.isFinite) return null;
    var lat = latitude.clamp(-90.0, 90.0);
    if (lat == 90) lat -= 1e-10;
    final lng = ((longitude + 180) % 360 + 360) % 360;
    final normalizedLongitude = lng - 180;
    final length = math.min(15, math.max(2, codeLength));
    final actualLength = length < 10 ? length + length % 2 : length;

    var latValue = _scaledInteger((lat + 90) * 8000);
    var lngValue = _scaledInteger((normalizedLongitude + 180) * 8000);
    final digits = <String>[];
    for (var i = 0; i < 5; i++) {
      digits.insert(0, _alphabet[lngValue % 20]);
      lngValue ~/= 20;
      digits.insert(0, _alphabet[latValue % 20]);
      latValue ~/= 20;
    }

    if (actualLength > 10) {
      var encodedLatitude = 0;
      var encodedLongitude = 0;
      for (var i = 0; i < 10; i += 2) {
        encodedLatitude = encodedLatitude * 20 + _alphabet.indexOf(digits[i]);
        encodedLongitude =
            encodedLongitude * 20 + _alphabet.indexOf(digits[i + 1]);
      }
      var latRemainder = (lat + 90) * 8000 - encodedLatitude;
      var lngRemainder = (normalizedLongitude + 180) * 8000 - encodedLongitude;
      for (var i = 10; i < actualLength; i++) {
        latRemainder *= 5;
        lngRemainder *= 4;
        final row = (latRemainder + 1e-7).floor().clamp(0, 4);
        final column = (lngRemainder + 1e-7).floor().clamp(0, 3);
        digits.add(_alphabet[row * 4 + column]);
        latRemainder -= row;
        lngRemainder -= column;
      }
    }
    final codeDigits = digits.take(actualLength).join();
    if (actualLength < _separatorPosition) {
      return '${codeDigits.padRight(_separatorPosition, '0')}$_separator';
    }
    return '${codeDigits.substring(0, _separatorPosition)}$_separator${codeDigits.substring(_separatorPosition)}';
  }

  static String? encodeRounded100m(double latitude, double longitude) {
    if (!latitude.isFinite ||
        !longitude.isFinite ||
        latitude < -90 ||
        latitude > 90 ||
        longitude < -180 ||
        longitude > 180) {
      return null;
    }
    final roundedLatitude = (latitude * 1000).roundToDouble() / 1000;
    final roundedLongitude = (longitude * 1000).roundToDouble() / 1000;
    return encode(roundedLatitude, roundedLongitude);
  }

  static PlusCodeArea? decode(String code) {
    final normalized = code.toUpperCase();
    final separator = normalized.indexOf(_separator);
    if (separator != _separatorPosition ||
        normalized.lastIndexOf(_separator) != separator) {
      return null;
    }
    if (normalized
        .replaceAll(_separator, '')
        .split('')
        .any(
          (character) => !_alphabet.contains(character) && character != '0',
        )) {
      return null;
    }
    final truncated = normalized.length > _separatorPosition + 8
        ? normalized.substring(0, _separatorPosition + 8)
        : normalized;
    if (!isValidFull(truncated)) return null;
    return _decodeUnchecked(truncated);
  }

  static PlusCodeArea _decodeUnchecked(String code) {
    final digits = code.replaceAll(_separator, '').replaceAll('0', '');
    var south = -90.0;
    var west = -180.0;
    for (var i = 0; i < math.min(10, digits.length); i++) {
      final value = _alphabet.indexOf(digits[i]);
      final resolution = _pairResolutions[i ~/ 2];
      if (i.isEven) {
        south += value * resolution;
      } else {
        west += value * resolution;
      }
    }
    var height = _pairResolutions[math.min(4, (digits.length - 1) ~/ 2)];
    var width = height;
    if (digits.length > 10) {
      height = _pairResolutions.last / 5;
      width = _pairResolutions.last / 4;
      for (var i = 10; i < digits.length; i++) {
        final value = _alphabet.indexOf(digits[i]);
        south += (value ~/ 4) * height;
        west += (value % 4) * width;
        if (i < digits.length - 1) {
          height /= 5;
          width /= 4;
        }
      }
    } else if (digits.length < 10) {
      final pairCount = digits.length ~/ 2;
      height = _pairResolutions[pairCount - 1];
      width = height;
    }
    return PlusCodeArea(
      south: south,
      west: west,
      north: south + height,
      east: west + width,
      codeLength: digits.length,
    );
  }
}
