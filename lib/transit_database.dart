import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart';

import 'models.dart';

class TransitDatabase {
  TransitDatabase({AssetBundle? assets}) : _assets = assets ?? rootBundle;

  final AssetBundle _assets;
  Database? _database;

  Future<Database> get database async {
    if (_database case final value?) return value;
    final directory = await getDatabasesPath();
    final db = await openDatabase(
      path.join(directory, 'aurora_transit.db'),
      version: 1,
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
            verification_status TEXT NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE stops (
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            area TEXT NOT NULL,
            source TEXT NOT NULL,
            verification_status TEXT NOT NULL
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
            verification_status TEXT NOT NULL
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
      onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
    );
    _database = db;
    return db;
  }

  Future<void> _seed(Database db) async {
    final data = jsonDecode(
      await _assets.loadString('assets/sample_dataset.json'),
    ) as Map<String, dynamic>;
    await db.transaction((txn) async {
      final batch = txn.batch();
      for (final row in data['routes'] as List) {
        batch.insert('routes', {
          'id': row['id'],
          'name': row['name'],
          'description': row['description'],
          'source': row['source'],
          'verification_status': row['verificationStatus'],
        });
      }
      for (final row in data['stops'] as List) {
        batch.insert('stops', {
          'id': row['id'],
          'name': row['name'],
          'area': row['area'],
          'source': row['source'],
          'verification_status': row['verificationStatus'],
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
      batch.insert('metadata', {
        'key': 'dataset_version',
        'value': data['version'],
      });
      batch.insert('metadata', {
        'key': 'dataset_updated_at',
        'value': data['updatedAt'],
      });
      await batch.commit(noResult: true);
    });
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
          ),
          stops: stopRows
              .map(
                (row) => TransitStop(
                  id: row['id'] as String,
                  name: row['name'] as String,
                  area: row['area'] as String,
                  source: row['source'] as String,
                  verificationStatus: row['verification_status'] as String,
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
