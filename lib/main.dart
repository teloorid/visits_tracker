import 'package:flutter/material.dart';
import 'package:visits_tracker_v5/injection_container.dart' as di;
import 'package:visits_tracker_v5/app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await di.init(); // Initialize GetIt
  runApp(const MyApp());
}