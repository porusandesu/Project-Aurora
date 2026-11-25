import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'feature_flags.dart';
import 'models.dart';
import 'transit_database.dart';

part 'app/aurora_app.dart';
part 'app/aurora_shell.dart';
part 'ui/discover_page.dart';
part 'ui/planner_page.dart';
part 'ui/routes_page.dart';
part 'ui/widgets.dart';

void main() => runApp(const AuroraApp());

const _appVersion = String.fromEnvironment(
  'AURORA_APP_VERSION',
  defaultValue: '1.0.0',
);
const _ink = Color(0xFF17352F);
const _green = Color(0xFF176B54);
const _mint = Color(0xFFDDF2E8);
const _canvas = Color(0xFFF5F7F4);
