import 'dart:convert';

import 'package:aurora/feature_flags.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite/sqflite.dart';

const _manifest = '''
{"schemaVersion":1,"features":{"journey_planner":{"enabled":true,"rolloutPercentage":100,"minimumAppVersion":"1.0.0","killSwitch":false}}}
''';

class _ManifestBundle extends CachingAssetBundle {
  @override
  Future<ByteData> load(String key) async {
    expect(key, 'assets/feature_manifest.json');
    return ByteData.sublistView(Uint8List.fromList(utf8.encode(_manifest)));
  }
}

class _MemorySettingsDatabase extends Fake implements Database {
  String? rolloutBucket;
  var inserts = 0;

  @override
  Future<List<Map<String, Object?>>> query(
    String table, {
    bool? distinct,
    List<String>? columns,
    String? where,
    List<Object?>? whereArgs,
    String? groupBy,
    String? having,
    String? orderBy,
    int? limit,
    int? offset,
  }) async {
    expect(table, 'settings');
    if (rolloutBucket == null) return [];
    return [
      <String, Object?>{'value': rolloutBucket},
    ];
  }

  @override
  Future<int> insert(
    String table,
    Map<String, Object?> values, {
    String? nullColumnHack,
    ConflictAlgorithm? conflictAlgorithm,
  }) async {
    expect(table, 'settings');
    rolloutBucket = values['value'] as String;
    inserts++;
    return inserts;
  }
}

void main() {
  test('keeps the rollout bucket stable in the settings database', () async {
    final database = _MemorySettingsDatabase();

    final first = await loadFeatureFlags(
      settingsDatabase: database,
      assets: _ManifestBundle(),
    );
    final second = await loadFeatureFlags(
      settingsDatabase: database,
      assets: _ManifestBundle(),
    );

    expect(first.rolloutBucket, inInclusiveRange(0, 99));
    expect(second.rolloutBucket, first.rolloutBucket);
    expect(database.inserts, 1);
  });

  test('creates a new bucket after the settings are cleared', () async {
    final database = _MemorySettingsDatabase();
    final assets = _ManifestBundle();

    await loadFeatureFlags(settingsDatabase: database, assets: assets);
    database.rolloutBucket = null;
    final reset = await loadFeatureFlags(
      settingsDatabase: database,
      assets: assets,
    );

    expect(reset.rolloutBucket, inInclusiveRange(0, 99));
    expect(database.inserts, 2);
  });

  test('replaces an invalid stored bucket with a valid one', () async {
    final database = _MemorySettingsDatabase()..rolloutBucket = '100';

    final flags = await loadFeatureFlags(
      settingsDatabase: database,
      assets: _ManifestBundle(),
    );

    expect(flags.rolloutBucket, inInclusiveRange(0, 99));
    expect(database.inserts, 1);
  });
}
