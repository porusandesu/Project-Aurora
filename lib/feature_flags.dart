import 'dart:convert';
import 'dart:math';

import 'package:flutter/services.dart';
import 'package:sqflite/sqflite.dart';

class FeatureRule {
  const FeatureRule({
    required this.enabled,
    required this.rolloutPercentage,
    required this.minimumAppVersion,
    required this.killSwitch,
  });

  final bool enabled;
  final int rolloutPercentage;
  final String minimumAppVersion;
  final bool killSwitch;

  factory FeatureRule.fromJson(Map<String, dynamic> json) {
    final percentage = json['rolloutPercentage'];
    if (json['enabled'] is! bool ||
        percentage is! int ||
        percentage < 0 ||
        percentage > 100 ||
        json['minimumAppVersion'] is! String ||
        json['killSwitch'] is! bool) {
      throw const FormatException('Invalid feature rule.');
    }
    return FeatureRule(
      enabled: json['enabled'] as bool,
      rolloutPercentage: percentage,
      minimumAppVersion: json['minimumAppVersion'] as String,
      killSwitch: json['killSwitch'] as bool,
    );
  }
}

class FeatureFlagSnapshot {
  const FeatureFlagSnapshot({required this.rules, required this.rolloutBucket});

  final Map<String, FeatureRule> rules;
  final int rolloutBucket;

  bool isEnabled(String name, {required String appVersion}) {
    // Only capabilities compiled into this client can be enabled by a manifest.
    if (name != 'journey_planner') return false;
    final rule = rules[name];
    if (rule == null || rule.killSwitch || !rule.enabled) return false;
    if (!isVersionAtLeast(appVersion, rule.minimumAppVersion)) return false;
    return rolloutBucket < rule.rolloutPercentage;
  }
}

Future<FeatureFlagSnapshot> loadFeatureFlags({
  required Database database,
  required AssetBundle assets,
}) async {
  final manifest = jsonDecode(
    await assets.loadString('assets/feature_manifest.json'),
  );
  if (manifest is! Map<String, dynamic> ||
      manifest['schemaVersion'] != 1 ||
      manifest['features'] is! Map<String, dynamic>) {
    throw const FormatException('Unsupported feature manifest.');
  }
  final rules = <String, FeatureRule>{};
  final jsonRules = manifest['features'] as Map<String, dynamic>;
  for (final entry in jsonRules.entries) {
    if (entry.value is! Map<String, dynamic>) {
      throw const FormatException('Invalid feature manifest entry.');
    }
    rules[entry.key] = FeatureRule.fromJson(
      entry.value as Map<String, dynamic>,
    );
  }
  final bucket = await _getOrCreateRolloutBucket(database);
  return FeatureFlagSnapshot(rules: rules, rolloutBucket: bucket);
}

Future<int> _getOrCreateRolloutBucket(Database database) async {
  final rows = await database.query(
    'metadata',
    columns: ['value'],
    where: 'key = ?',
    whereArgs: ['rollout_bucket'],
    limit: 1,
  );
  if (rows.isNotEmpty) {
    final bucket = int.tryParse(rows.single['value'] as String? ?? '');
    if (bucket != null && bucket >= 0 && bucket < 100) return bucket;
  }
  final bucket = Random.secure().nextInt(100);
  await database.insert('metadata', {
    'key': 'rollout_bucket',
    'value': '$bucket',
  }, conflictAlgorithm: ConflictAlgorithm.replace);
  return bucket;
}

bool isVersionAtLeast(String current, String minimum) {
  final currentParts = _parseVersion(current);
  final minimumParts = _parseVersion(minimum);
  if (currentParts == null || minimumParts == null) return false;
  for (var i = 0; i < 3; i++) {
    if (currentParts[i] != minimumParts[i]) {
      return currentParts[i] > minimumParts[i];
    }
  }
  return true;
}

List<int>? _parseVersion(String value) {
  final core = value.split('+').first.split('-').first;
  final parts = core.split('.');
  if (parts.length != 3) return null;
  final numbers = parts.map(int.tryParse).toList();
  if (numbers.any((part) => part == null || part < 0)) return null;
  return numbers.cast<int>();
}
