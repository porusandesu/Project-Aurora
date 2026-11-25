import 'dart:convert';
import 'dart:io';

import 'package:aurora/dataset_update.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite/sqflite.dart';

import 'package:aurora/transit_database.dart';

class _RecordingDatabase extends Fake implements DatabaseExecutor {
  final statements = <String>[];

  @override
  Future<void> execute(String sql, [List<Object?>? arguments]) async {
    statements.add(sql);
  }
}

Map<String, dynamic> _dataset(String version) => {
  'schemaVersion': supportedDatasetSchemaVersion,
  'version': version,
  'updatedAt': '2026-11-25',
  'routes': [
    {
      'id': 'route-blue',
      'name': 'Blue line',
      'description': 'Sample route',
      'source': 'Synthetic data',
      'verificationStatus': 'sample',
    },
  ],
  'stops': [
    {
      'id': 'stop-central',
      'name': 'Central stop',
      'area': 'Central',
      'source': 'Synthetic data',
      'verificationStatus': 'sample',
    },
    {
      'id': 'stop-library',
      'name': 'Library stop',
      'area': 'North',
      'source': 'Synthetic data',
      'verificationStatus': 'sample',
    },
  ],
  'routeStops': [
    {'routeId': 'route-blue', 'stopId': 'stop-central', 'position': 1},
    {'routeId': 'route-blue', 'stopId': 'stop-library', 'position': 2},
  ],
  'landmarks': [
    {
      'id': 'place-hall',
      'canonicalName': 'Community hall',
      'area': 'Central',
      'stopId': 'stop-central',
      'source': 'Synthetic data',
      'verificationStatus': 'sample',
    },
  ],
  'aliases': <Map<String, Object?>>[],
  'fares': <Map<String, Object?>>[],
};

Future<Directory> _temporaryDirectory() async =>
    Directory.systemTemp.createTemp('aurora-dataset-test-');

DatasetUpdater _updater(
  Directory directory,
  Map<String, dynamic> Function() current, {
  required Future<void> Function(Map<String, dynamic>) activate,
  Future<void> Function()? check,
}) => DatasetUpdater(
  directory: directory,
  readCurrentDataset: () async => current(),
  activateDataset: activate,
  selfCheck: check ?? () async {},
);

void main() {
  test('rejects a bad checksum and leaves the active dataset intact', () async {
    final directory = await _temporaryDirectory();
    addTearDown(() => directory.delete(recursive: true));
    var active = _dataset('sample-1');
    final updater = _updater(
      directory,
      () => active,
      activate: (data) async {
        active = data;
      },
    );
    final envelope = jsonDecode(
      utf8.decode(DatasetPackage.encode(_dataset('sample-2'))),
    ) as Map<String, dynamic>;
    envelope['checksum'] = List.filled(64, '0').join();

    await expectLater(
      updater.update(utf8.encode(jsonEncode(envelope))),
      throwsFormatException,
    );
    expect(active['version'], 'sample-1');
  });

  test('rejects a package with a newer schema version', () {
    final payload = utf8.encode(jsonEncode(_dataset('sample-2')));
    final envelope = {
      'schemaVersion': supportedDatasetSchemaVersion + 1,
      'checksum': sha256.convert(payload).toString(),
      'payload': base64Encode(payload),
    };

    expect(
      () => DatasetPackage.decode(utf8.encode(jsonEncode(envelope))),
      throwsFormatException,
    );
  });

  test('accepts records without coordinates', () {
    final dataset = _dataset('sample-2');

    expect(DatasetPackage.decode(DatasetPackage.encode(dataset)).data, dataset);
  });

  test('rejects invalid coordinates and drop-off rules', () {
    final invalidCoordinates = _dataset('sample-2');
    final badStop = Map<String, dynamic>.from(
      (invalidCoordinates['stops'] as List).first as Map<String, dynamic>,
    )..['latitude'] = 91;
    invalidCoordinates['stops'] = [badStop];
    expect(
      () => DatasetPackage.encode(invalidCoordinates),
      throwsFormatException,
    );

    final invalidRule = _dataset('sample-2');
    (invalidRule['routes'] as List).first['dropoffRule'] = 'anywhere';
    expect(() => DatasetPackage.encode(invalidRule), throwsFormatException);
  });

  test('sample dataset has coordinates for every fictional stop', () async {
    final sample = jsonDecode(
      await File('assets/sample_dataset.json').readAsString(),
    ) as Map<String, dynamic>;
    final stops = sample['stops'] as List;

    expect(stops, isNotEmpty);
    expect(
      stops.every(
        (stop) =>
            stop['latitude'] is num &&
            stop['longitude'] is num &&
            (stop['coordinateSource'] as String).contains(
              'Synthetic fixture coordinates',
            ),
      ),
      isTrue,
    );
    expect(
      DatasetPackage.decode(DatasetPackage.encode(sample)).schemaVersion,
      supportedDatasetSchemaVersion,
    );
  });

  test('v1 migration only adds columns with safe defaults', () async {
    final database = _RecordingDatabase();

    await upgradeTransitSchema(database, 1, 2);

    expect(database.statements, hasLength(14));
    expect(
      database.statements.every(
        (sql) => sql.startsWith('ALTER TABLE') && sql.contains(' ADD COLUMN '),
      ),
      isTrue,
    );
    expect(database.statements.join(' '), contains("DEFAULT 'unknown'"));
    expect(database.statements.join(' '), contains("DEFAULT 'both_ways'"));
  });

  test('v2 migration connects routes to fare types', () async {
    final database = _RecordingDatabase();
    await upgradeTransitSchema(database, 2, 3);
    expect(database.statements, [
      'ALTER TABLE routes ADD COLUMN transport_type TEXT',
    ]);
  });

  test('rejects negative or non-finite fares at the package boundary', () {
    final invalid = _dataset('bad-fare')
      ..['fares'] = [
        {
          'transportType': 'bus',
          'amount': -1,
          'currency': 'USD',
          'effectiveFrom': '2026-01-01',
        },
      ];
    expect(() => DatasetPackage.encode(invalid), throwsFormatException);
  });

  test(
    'staging leaves the active dataset unchanged until activation',
    () async {
      final directory = await _temporaryDirectory();
      addTearDown(() => directory.delete(recursive: true));
      var active = _dataset('sample-1');
      final updater = _updater(
        directory,
        () => active,
        activate: (data) async {
          active = data;
        },
      );

      await updater.stage(DatasetPackage.encode(_dataset('sample-2')));

      expect(active['version'], 'sample-1');
      expect(
        File('${directory.path}/aurora_transit.staged.json').existsSync(),
        isTrue,
      );
    },
  );

  test('activates a valid dataset and retains a rollback copy', () async {
    final directory = await _temporaryDirectory();
    addTearDown(() => directory.delete(recursive: true));
    var active = _dataset('sample-1');
    final settings = {'rolloutBucket': 27};
    final updater = _updater(
      directory,
      () => active,
      activate: (data) async {
        active = data;
      },
    );

    await updater.update(DatasetPackage.encode(_dataset('sample-2')));

    expect(active['version'], 'sample-2');
    expect(settings['rolloutBucket'], 27);
    expect(
      File('${directory.path}/aurora_transit.previous.json').existsSync(),
      isTrue,
    );
    await updater.rollback();
    expect(active['version'], 'sample-1');
  });

  test('restores the previous dataset when the self-check fails', () async {
    final directory = await _temporaryDirectory();
    addTearDown(() => directory.delete(recursive: true));
    var active = _dataset('sample-1');
    final updater = _updater(
      directory,
      () => active,
      activate: (data) async {
        active = data;
      },
      check: () async {
        if (active['version'] == 'sample-2') {
          throw StateError('simulated self-check failure');
        }
      },
    );

    await expectLater(
      updater.update(DatasetPackage.encode(_dataset('sample-2'))),
      throwsStateError,
    );
    expect(active['version'], 'sample-1');
  });
}
