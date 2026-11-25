import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart';

import 'dataset_update.dart';
import 'models.dart';

Future<void> upgradeTransitSchema(
  DatabaseExecutor db,
  int oldVersion,
  int newVersion,
) async {
  if (oldVersion < 2 && newVersion >= 2) {
    for (final statement in [
      'ALTER TABLE stops ADD COLUMN latitude REAL CHECK (latitude IS NULL OR latitude BETWEEN -90 AND 90)',
      'ALTER TABLE stops ADD COLUMN longitude REAL CHECK (longitude IS NULL OR longitude BETWEEN -180 AND 180)',
      'ALTER TABLE stops ADD COLUMN accuracy_metres REAL CHECK (accuracy_metres IS NULL OR accuracy_metres >= 0)',
      'ALTER TABLE stops ADD COLUMN coordinate_source TEXT',
      'ALTER TABLE landmarks ADD COLUMN latitude REAL CHECK (latitude IS NULL OR latitude BETWEEN -90 AND 90)',
      'ALTER TABLE landmarks ADD COLUMN longitude REAL CHECK (longitude IS NULL OR longitude BETWEEN -180 AND 180)',
      'ALTER TABLE landmarks ADD COLUMN accuracy_metres REAL CHECK (accuracy_metres IS NULL OR accuracy_metres >= 0)',
      'ALTER TABLE landmarks ADD COLUMN coordinate_source TEXT',
      'ALTER TABLE routes ADD COLUMN recognition_hint TEXT',
      'ALTER TABLE routes ADD COLUMN boarding_note TEXT',
      "ALTER TABLE routes ADD COLUMN dropoff_rule TEXT NOT NULL DEFAULT 'unknown' CHECK (dropoff_rule IN ('any_point', 'fixed_stops', 'unknown'))",
      'ALTER TABLE routes ADD COLUMN hint_source TEXT',
      'ALTER TABLE routes ADD COLUMN hint_verified_on TEXT',
      "ALTER TABLE routes ADD COLUMN direction_rule TEXT NOT NULL DEFAULT 'both_ways' CHECK (direction_rule IN ('both_ways', 'outbound_only', 'inbound_only', 'unknown'))",
    ]) {
      await db.execute(statement);
    }
  }
}

class TransitDatabase {
  TransitDatabase({AssetBundle? assets}) : _assets = assets ?? rootBundle;

  final AssetBundle _assets;
  Database? _database;

  Future<Database> get database async {
    if (_database case final value?) return value;
    final directory = await getDatabasesPath();
    final db = await openDatabase(
      path.join(directory, 'aurora_transit.db'),
      version: 2,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE metadata (
            key TEXT PRIMARY KEY,
            value TEXT NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE routes (
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            description TEXT NOT NULL,
            source TEXT NOT NULL,
            verification_status TEXT NOT NULL,
            recognition_hint TEXT,
            boarding_note TEXT,
            dropoff_rule TEXT NOT NULL DEFAULT 'unknown'
              CHECK (dropoff_rule IN ('any_point', 'fixed_stops', 'unknown')),
            hint_source TEXT,
            hint_verified_on TEXT,
            direction_rule TEXT NOT NULL DEFAULT 'both_ways'
              CHECK (direction_rule IN ('both_ways', 'outbound_only', 'inbound_only', 'unknown'))
          )
        ''');
        await db.execute('''
          CREATE TABLE stops (
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            area TEXT NOT NULL,
            source TEXT NOT NULL,
            verification_status TEXT NOT NULL,
            latitude REAL CHECK (latitude IS NULL OR latitude BETWEEN -90 AND 90),
            longitude REAL CHECK (longitude IS NULL OR longitude BETWEEN -180 AND 180),
            accuracy_metres REAL CHECK (accuracy_metres IS NULL OR accuracy_metres >= 0),
            coordinate_source TEXT
          )
        ''');
        await db.execute('''
          CREATE TABLE route_stops (
            route_id TEXT NOT NULL REFERENCES routes(id),
            stop_id TEXT NOT NULL REFERENCES stops(id),
            position INTEGER NOT NULL,
            PRIMARY KEY (route_id, position)
          )
        ''');
        await db.execute('''
          CREATE TABLE landmarks (
            id TEXT PRIMARY KEY,
            canonical_name TEXT NOT NULL,
            area TEXT NOT NULL,
            stop_id TEXT NOT NULL REFERENCES stops(id),
            source TEXT NOT NULL,
            verification_status TEXT NOT NULL,
            latitude REAL CHECK (latitude IS NULL OR latitude BETWEEN -90 AND 90),
            longitude REAL CHECK (longitude IS NULL OR longitude BETWEEN -180 AND 180),
            accuracy_metres REAL CHECK (accuracy_metres IS NULL OR accuracy_metres >= 0),
            coordinate_source TEXT
          )
        ''');
        await db.execute('''
          CREATE TABLE aliases (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            landmark_id TEXT NOT NULL REFERENCES landmarks(id),
            name TEXT NOT NULL,
            approved INTEGER NOT NULL,
            source TEXT NOT NULL
          )
        ''');
        await db.execute('CREATE INDEX aliases_name_idx ON aliases(name)');
        await db.execute('''
          CREATE TABLE fares (
            id TEXT PRIMARY KEY,
            transport_type TEXT NOT NULL,
            amount REAL NOT NULL,
            currency TEXT NOT NULL,
            effective_from TEXT NOT NULL,
            source TEXT NOT NULL,
            verification_status TEXT NOT NULL
          )
        ''');
        await _seed(db);
      },
      onUpgrade: upgradeTransitSchema,
      onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
    );
    _database = db;
    return db;
  }

  Future<void> _seed(Database db) async {
    final data = jsonDecode(
      await _assets.loadString('assets/sample_dataset.json'),
    ) as Map<String, dynamic>;
    await db.transaction((txn) => _writeDataset(txn, data));
  }

  Future<void> _writeDataset(
    DatabaseExecutor db,
    Map<String, dynamic> data,
  ) async {
    final batch = db.batch();
    for (final row in data['routes'] as List) {
      batch.insert('routes', {
        'id': row['id'],
        'name': row['name'],
        'description': row['description'],
        'source': row['source'],
        'verification_status': row['verificationStatus'],
        'recognition_hint': row['recognitionHint'],
        'boarding_note': row['boardingNote'],
        'dropoff_rule': row['dropoffRule'] ?? 'unknown',
        'hint_source': row['hintSource'],
        'hint_verified_on': row['hintVerifiedOn'],
        'direction_rule': row['directionRule'] ?? 'both_ways',
      });
    }
    for (final row in data['stops'] as List) {
      batch.insert('stops', {
        'id': row['id'],
        'name': row['name'],
        'area': row['area'],
        'source': row['source'],
        'verification_status': row['verificationStatus'],
        'latitude': row['latitude'],
        'longitude': row['longitude'],
        'accuracy_metres': row['accuracyMetres'],
        'coordinate_source': row['coordinateSource'],
      });
    }
    for (final row in data['routeStops'] as List) {
      batch.insert('route_stops', {
        'route_id': row['routeId'],
        'stop_id': row['stopId'],
        'position': row['position'],
      });
    }
    for (final row in data['landmarks'] as List) {
      batch.insert('landmarks', {
        'id': row['id'],
        'canonical_name': row['canonicalName'],
        'area': row['area'],
        'stop_id': row['stopId'],
        'source': row['source'],
        'verification_status': row['verificationStatus'],
        'latitude': row['latitude'],
        'longitude': row['longitude'],
        'accuracy_metres': row['accuracyMetres'],
        'coordinate_source': row['coordinateSource'],
      });
    }
    for (final row in data['aliases'] as List) {
      batch.insert('aliases', {
        'landmark_id': row['landmarkId'],
        'name': row['name'],
        'approved': row['approved'],
        'source': row['source'],
      });
    }
    for (final row in data['fares'] as List? ?? const []) {
      batch.insert('fares', {
        'id': row['id'],
        'transport_type': row['transportType'],
        'amount': row['amount'],
        'currency': row['currency'],
        'effective_from': row['effectiveFrom'],
        'source': row['source'],
        'verification_status': row['verificationStatus'],
      });
    }
    batch.insert('metadata', {
      'key': 'dataset_version',
      'value': data['version'],
    });
    batch.insert('metadata', {
      'key': 'dataset_updated_at',
      'value': data['updatedAt'],
    });
    await batch.commit(noResult: true);
  }

  Future<Map<String, dynamic>> exportDataset() async {
    final db = await database;
    final metadata = await db.query('metadata');
    final values = {for (final row in metadata) row['key']: row['value']};
    Map<String, Object?> rename(
      Map<String, Object?> row,
      Map<String, String> keys,
    ) => {
      for (final entry in row.entries)
        keys[entry.key] ?? entry.key: entry.value,
    };
    return {
      'schemaVersion': supportedDatasetSchemaVersion,
      'version': values['dataset_version'],
      'updatedAt': values['dataset_updated_at'],
      'routes': (await db.query('routes'))
          .map(
            (row) => rename(row, {
              'verification_status': 'verificationStatus',
              'recognition_hint': 'recognitionHint',
              'boarding_note': 'boardingNote',
              'dropoff_rule': 'dropoffRule',
              'hint_source': 'hintSource',
              'hint_verified_on': 'hintVerifiedOn',
              'direction_rule': 'directionRule',
            }),
          )
          .toList(),
      'stops': (await db.query('stops'))
          .map(
            (row) => rename(row, {
              'verification_status': 'verificationStatus',
              'accuracy_metres': 'accuracyMetres',
              'coordinate_source': 'coordinateSource',
            }),
          )
          .toList(),
      'routeStops': (await db.query('route_stops'))
          .map(
            (row) => rename(row, {'route_id': 'routeId', 'stop_id': 'stopId'}),
          )
          .toList(),
      'landmarks': (await db.query('landmarks'))
          .map(
            (row) => rename(row, {
              'canonical_name': 'canonicalName',
              'stop_id': 'stopId',
              'verification_status': 'verificationStatus',
              'accuracy_metres': 'accuracyMetres',
              'coordinate_source': 'coordinateSource',
            }),
          )
          .toList(),
      'aliases': (await db.query('aliases'))
          .map(
            (row) => rename(row, {'landmark_id': 'landmarkId'})..remove('id'),
          )
          .toList(),
      'fares': (await db.query('fares'))
          .map(
            (row) => rename(row, {
              'transport_type': 'transportType',
              'effective_from': 'effectiveFrom',
              'verification_status': 'verificationStatus',
            }),
          )
          .toList(),
    };
  }

  Future<void> replaceDataset(Map<String, dynamic> data) async {
    final db = await database;
    await db.transaction((txn) async {
      for (final table in [
        'aliases',
        'landmarks',
        'route_stops',
        'fares',
        'routes',
        'stops',
        'metadata',
      ]) {
        await txn.delete(table);
      }
      await _writeDataset(txn, data);
    });
  }

  Future<void> selfCheck() async {
    final places = await this.places();
    if (places.isEmpty ||
        searchPlaces(places, places.first.canonicalName).isEmpty) {
      throw StateError('Dataset search self-check failed.');
    }
    final routePatterns = await routes();
    for (final route in routePatterns) {
      if (route.stops.length < 2) continue;
      if (planJourneys(
        [route],
        route.stops.first.id,
        route.stops.last.id,
      ).isNotEmpty) {
        return;
      }
    }
    throw StateError('Dataset journey self-check failed.');
  }

  Future<DatasetUpdater> _updater() async => DatasetUpdater(
    directory: Directory(await getDatabasesPath()),
    readCurrentDataset: exportDataset,
    activateDataset: replaceDataset,
    selfCheck: selfCheck,
  );

  Future<void> stageDatasetPackage(List<int> packageBytes) async {
    await (await _updater()).stage(packageBytes);
  }

  Future<void> activateStagedDataset() async {
    await (await _updater()).activateStaged();
  }

  Future<void> updateDatasetPackage(List<int> packageBytes) async {
    await (await _updater()).update(packageBytes);
  }

  Future<void> rollbackDataset() async {
    await (await _updater()).rollback();
  }

  Future<List<Place>> places() async {
    final db = await database;
    final rows = await db.rawQuery('''
      SELECT l.*, GROUP_CONCAT(a.name, '|||') AS alias_list
      FROM landmarks l
      LEFT JOIN aliases a ON a.landmark_id = l.id AND a.approved = 1
      GROUP BY l.id
      ORDER BY l.canonical_name COLLATE NOCASE
    ''');
    return rows.map((row) {
      final aliases =
          (row['alias_list'] as String?)
              ?.split('|||')
              .where((alias) => alias.isNotEmpty)
              .toList() ??
          const <String>[];
      return Place(
        id: row['id'] as String,
        canonicalName: row['canonical_name'] as String,
        area: row['area'] as String,
        stopId: row['stop_id'] as String,
        source: row['source'] as String,
        verificationStatus: row['verification_status'] as String,
        aliases: aliases,
      );
    }).toList();
  }

  Future<List<TransitStop>> stops() async {
    final db = await database;
    final rows = await db.query('stops', orderBy: 'name COLLATE NOCASE');
    return rows
        .map(
          (row) => TransitStop(
            id: row['id'] as String,
            name: row['name'] as String,
            area: row['area'] as String,
            source: row['source'] as String,
            verificationStatus: row['verification_status'] as String,
            latitude: (row['latitude'] as num?)?.toDouble(),
            longitude: (row['longitude'] as num?)?.toDouble(),
            accuracyMetres: (row['accuracy_metres'] as num?)?.toDouble(),
            coordinateSource: row['coordinate_source'] as String?,
          ),
        )
        .toList();
  }

  Future<List<RoutePattern>> routes() async {
    final db = await database;
    final routeRows = await db.query('routes', orderBy: 'name COLLATE NOCASE');
    final patterns = <RoutePattern>[];
    for (final routeRow in routeRows) {
      final stopRows = await db.rawQuery(
        '''
        SELECT s.* FROM route_stops rs
        JOIN stops s ON s.id = rs.stop_id
        WHERE rs.route_id = ? ORDER BY rs.position
      ''',
        [routeRow['id']],
      );
      patterns.add(
        RoutePattern(
          route: TransitRoute(
            id: routeRow['id'] as String,
            name: routeRow['name'] as String,
            description: routeRow['description'] as String,
            source: routeRow['source'] as String,
            verificationStatus: routeRow['verification_status'] as String,
            recognitionHint: routeRow['recognition_hint'] as String?,
            boardingNote: routeRow['boarding_note'] as String?,
            dropoffRule: routeRow['dropoff_rule'] as String,
            hintSource: routeRow['hint_source'] as String?,
            hintVerifiedOn: routeRow['hint_verified_on'] as String?,
            directionRule: routeRow['direction_rule'] as String,
          ),
          stops: stopRows
              .map(
                (row) => TransitStop(
                  id: row['id'] as String,
                  name: row['name'] as String,
                  area: row['area'] as String,
                  source: row['source'] as String,
                  verificationStatus: row['verification_status'] as String,
                  latitude: (row['latitude'] as num?)?.toDouble(),
                  longitude: (row['longitude'] as num?)?.toDouble(),
                  accuracyMetres: (row['accuracy_metres'] as num?)?.toDouble(),
                  coordinateSource: row['coordinate_source'] as String?,
                ),
              )
              .toList(),
        ),
      );
    }
    return patterns;
  }

  Future<String> datasetVersion() async {
    final db = await database;
    final rows = await db.query(
      'metadata',
      where: 'key = ?',
      whereArgs: ['dataset_version'],
    );
    return rows.first['value'] as String;
  }

  Future<void> close() async {
    await _database?.close();
    _database = null;
  }
}

List<JourneyOption> planJourneys(
  List<RoutePattern> routes,
  String originStopId,
  String destinationStopId,
) {
  if (originStopId == destinationStopId) return const [];
  final options = <JourneyOption>[];
  final originRoutes = routes.where(
    (r) => r.stops.any((s) => s.id == originStopId),
  );
  final destinationRoutes = routes.where(
    (r) => r.stops.any((s) => s.id == destinationStopId),
  );

  for (final route in originRoutes) {
    final start = route.stops.indexWhere((s) => s.id == originStopId);
    final end = route.stops.indexWhere((s) => s.id == destinationStopId);
    if (end > start) {
      options.add(
        JourneyOption(
          legs: [
            JourneyLeg(
              route: route.route,
              boardingStop: route.stops[start],
              alightingStop: route.stops[end],
            ),
          ],
        ),
      );
    }
  }

  for (final first in originRoutes) {
    final start = first.stops.indexWhere((s) => s.id == originStopId);
    for (final second in destinationRoutes) {
      if (first.route.id == second.route.id) continue;
      final destination = second.stops.indexWhere(
        (s) => s.id == destinationStopId,
      );
      for (final transfer in first.stops.skip(start + 1)) {
        final transferIndex = second.stops.indexWhere(
          (s) => s.id == transfer.id,
        );
        if (transferIndex >= 0 && destination > transferIndex) {
          options.add(
            JourneyOption(
              legs: [
                JourneyLeg(
                  route: first.route,
                  boardingStop: first.stops[start],
                  alightingStop: transfer,
                ),
                JourneyLeg(
                  route: second.route,
                  boardingStop: second.stops[transferIndex],
                  alightingStop: second.stops[destination],
                ),
              ],
            ),
          );
        }
      }
    }
  }
  return options;
}
