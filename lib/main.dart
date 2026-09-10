import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app/app.dart';
import 'data/database/database_helper.dart';
import 'features/auth/auth_provider.dart';
import 'features/documents/document_provider.dart';
import 'features/settings/theme_provider.dart';
import 'features/students/student_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize SQLite database instance
  await DatabaseHelper.instance.database;

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => StudentProvider()),
        ChangeNotifierProvider(create: (_) => DocumentProvider()),
      ],
      child: const EduVaultApp(),
    ),
  );
}
