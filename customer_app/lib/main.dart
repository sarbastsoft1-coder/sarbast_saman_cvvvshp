import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'boutique/boutique_app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final preferences = await SharedPreferences.getInstance();
  runApp(BoutiqueApp(preferences: preferences));
}
