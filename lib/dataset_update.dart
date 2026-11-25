import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as path;

const supportedDatasetSchemaVersion = 3;

class DatasetPackage {
  const DatasetPackage({required this.schemaVersion, required this.data});

  final int schemaVersion;
  final Map<String, dynamic> data;

  static List<int> encode(Map<String, dynamic> data) {
    _validateDataset(data);
    final payload = utf8.encode(jsonEncode(data));
    return utf8.encode(
      jsonEncode({
        'schemaVersion': supportedDatasetSchemaVersion,
        'checksum': sha256.convert(payload).toString(),
        'payload': base64Encode(payload),
      }),
    );
  }

  factory DatasetPackage.decode(List<int> bytes) {
    final envelope = jsonDecode(utf8.decode(bytes));
    if (envelope is! Map<String, dynamic>) {
      throw const FormatException('Invalid dataset package.');
    }
    final schemaVersion = envelope['schemaVersion'];
    if (schemaVersion is! int ||
        schemaVersion != supportedDatasetSchemaVersion) {
      throw const FormatException('Unsupported dataset schema version.');
    }
    final encodedPayload = envelope['payload'];
    final checksum = envelope['checksum'];
    if (encodedPayload is! String || checksum is! String) {
      throw const FormatException('Invalid dataset package.');
    }
    final payload = base64Decode(encodedPayload);
    if (!RegExp(r'^[0-9a-f]{64}$').hasMatch(checksum) ||
        sha256.convert(payload).toString() != checksum) {
      throw const FormatException('Dataset package checksum does not match.');
    }
    final data = jsonDecode(utf8.decode(payload));
    if (data is! Map<String, dynamic>) {
      throw const FormatException('Invalid dataset payload.');
    }
    _validateDataset(data);
    return DatasetPackage(schemaVersion: schemaVersion, data: data);
  }
}

void _validateDataset(Map<String, dynamic> data) {
  if (data['schemaVersion'] != supportedDatasetSchemaVersion ||
      data['version'] is! String ||
      (data['version'] as String).isEmpty ||
      data['updatedAt'] is! String) {
    throw const FormatException(
      'Dataset schema, version, or update date is invalid.',
    );
  }
  for (final key in ['routes', 'stops', 'routeStops', 'landmarks', 'aliases']) {
    final rows = data[key];
    if (rows is! List || rows.any((row) => row is! Map<String, dynamic>)) {
      throw FormatException('Dataset $key must be a list of records.');
    }
  }
  if (data['fares'] != null &&
      (data['fares'] is! List ||
          (data['fares'] as List).any((row) => row is! Map<String, dynamic>))) {
    throw const FormatException('Dataset fares must be a list of records.');
  }
  for (final row in data['stops'] as List) {
    _validateCoordinates(row as Map<String, dynamic>, 'stop');
  }
  for (final row in data['landmarks'] as List) {
    _validateCoordinates(row as Map<String, dynamic>, 'landmark');
  }
  for (final row in data['routes'] as List) {
    final dropoffRule = row['dropoffRule'] ?? 'unknown';
    final directionRule = row['directionRule'] ?? 'both_ways';
    if (!{'any_point', 'fixed_stops', 'unknown'}.contains(dropoffRule)) {
      throw const FormatException('Dataset contains an invalid drop-off rule.');
    }
    if (!{
      'both_ways',
      'outbound_only',
      'inbound_only',
      'unknown',
    }.contains(directionRule)) {
      throw const FormatException(
        'Dataset contains an invalid direction rule.',
      );
    }
    for (final field in [
      'recognitionHint',
      'boardingNote',
      'hintSource',
      'hintVerifiedOn',
    ]) {
      if (row[field] != null && row[field] is! String) {
        throw FormatException('Dataset route $field must be text.');
      }
    }
    if (row['transportType'] != null && row['transportType'] is! String) {
      throw const FormatException('Dataset route transportType must be text.');
    }
  }
  for (final row in data['fares'] as List? ?? const []) {
    if (row['amount'] is! num ||
        !(row['amount'] as num).isFinite ||
        (row['amount'] as num) < 0 ||
        row['transportType'] is! String ||
        row['currency'] is! String ||
        row['effectiveFrom'] is! String) {
      throw const FormatException('Dataset contains an invalid fare.');
    }
  }
}

void _validateCoordinates(Map<String, dynamic> row, String entity) {
  final latitude = row['latitude'];
  final longitude = row['longitude'];
  if ((latitude == null) != (longitude == null) ||
      (latitude != null &&
          (latitude is! num ||
              longitude is! num ||
              !latitude.isFinite ||
              !longitude.isFinite ||
              latitude < -90 ||
              latitude > 90 ||
              longitude < -180 ||
              longitude > 180))) {
    throw FormatException('Dataset $entity has invalid coordinates.');
  }
  final accuracy = row['accuracyMetres'];
  if (accuracy != null &&
      (accuracy is! num || !accuracy.isFinite || accuracy < 0)) {
    throw FormatException('Dataset $entity has invalid coordinate accuracy.');
  }
  final source = row['coordinateSource'];
  if (source != null && source is! String) {
    throw FormatException('Dataset $entity coordinate source must be text.');
  }
}

class DatasetUpdater {
  DatasetUpdater({
    required this.directory,
    required this.readCurrentDataset,
    required this.activateDataset,
    required this.selfCheck,
  });

  final Directory directory;
  final Future<Map<String, dynamic>> Function() readCurrentDataset;
  final Future<void> Function(Map<String, dynamic>) activateDataset;
  final Future<void> Function() selfCheck;

  File get _stagedFile =>
      File(path.join(directory.path, 'aurora_transit.staged.json'));
  File get _previousFile =>
      File(path.join(directory.path, 'aurora_transit.previous.json'));

  Future<void> stage(List<int> packageBytes) async {
    DatasetPackage.decode(packageBytes);
    await directory.create(recursive: true);
    await _writeAtomically(_stagedFile, packageBytes);
  }

  Future<void> update(List<int> packageBytes) async {
    await stage(packageBytes);
    await activateStaged();
  }

  Future<void> activateStaged() async {
    if (!await _stagedFile.exists()) {
      throw StateError('No staged dataset package is available.');
    }
    final next = DatasetPackage.decode(await _stagedFile.readAsBytes());
    final previousData = await readCurrentDataset();
    final previousBytes = DatasetPackage.encode(previousData);
    await _writeAtomically(_previousFile, previousBytes);

    try {
      await activateDataset(next.data);
      await selfCheck();
    } catch (error, stackTrace) {
      try {
        await activateDataset(previousData);
        await _stagedFile.delete();
      } catch (rollbackError) {
        throw StateError(
          'Dataset update failed and rollback failed: $rollbackError',
        );
      }
      Error.throwWithStackTrace(error, stackTrace);
    }
    await _stagedFile.delete();
  }

  Future<void> rollback() async {
    if (!await _previousFile.exists()) {
      throw StateError('No previous dataset is available.');
    }
    final previous = DatasetPackage.decode(await _previousFile.readAsBytes());
    final current = await readCurrentDataset();
    await _writeAtomically(_previousFile, DatasetPackage.encode(current));
    try {
      await activateDataset(previous.data);
      await selfCheck();
    } catch (error, stackTrace) {
      await activateDataset(current);
      Error.throwWithStackTrace(error, stackTrace);
    }
  }

  Future<void> _writeAtomically(File destination, List<int> bytes) async {
    final temporary = File('${destination.path}.tmp');
    await temporary.writeAsBytes(bytes, flush: true);
    if (await destination.exists()) await destination.delete();
    await temporary.rename(destination.path);
  }
}
