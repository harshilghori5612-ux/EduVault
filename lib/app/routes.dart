import 'package:flutter/material.dart';

import '../data/models/document_model.dart';
import '../data/models/student_model.dart';
import '../features/auth/login_screen.dart';
import '../features/dashboard/dashboard_screen.dart';
import '../features/documents/add_document_screen.dart';
import '../features/documents/document_list_screen.dart';
import '../features/documents/document_scanner_screen.dart';
import '../features/documents/document_viewer_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/splash/splash_screen.dart';
import '../features/students/add_student_screen.dart';
import '../features/students/edit_student_screen.dart';
import '../features/students/student_list_screen.dart';
import '../features/students/student_profile_screen.dart';
import '../shared/widgets/main_scaffold.dart';

class Routes {
  static const String splash = '/';
  static const String login = '/login';
  static const String dashboard = '/dashboard';
  static const String studentList = '/student-list';
  static const String addStudent = '/add-student';
  static const String editStudent = '/edit-student';
  static const String studentProfile = '/student-profile';
  static const String documentList = '/document-list';
  static const String addDocument = '/add-document';
  static const String documentScanner = '/document-scanner';
  static const String documentViewer = '/document-viewer';
  static const String settings = '/settings';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case splash:
        return MaterialPageRoute(builder: (_) => const SplashScreen());
      case login:
        return MaterialPageRoute(builder: (_) => const LoginScreen());
      case dashboard:
        return MaterialPageRoute(builder: (_) => const MainScaffold(initialIndex: 0));
      case studentList:
        return MaterialPageRoute(builder: (_) => const MainScaffold(initialIndex: 1));
      case addStudent:
        return MaterialPageRoute(builder: (_) => const AddStudentScreen());
      case editStudent:
        final student = settings.arguments as StudentModel;
        return MaterialPageRoute(builder: (_) => EditStudentScreen(student: student));
      case studentProfile:
        final studentId = settings.arguments as String;
        return MaterialPageRoute(builder: (_) => StudentProfileScreen(studentId: studentId));
      case documentList:
        return MaterialPageRoute(builder: (_) => const MainScaffold(initialIndex: 2));
      case addDocument:
        String? studentId;
        String? category;
        if (settings.arguments is String) {
          studentId = settings.arguments as String;
        } else if (settings.arguments is Map) {
          final args = settings.arguments as Map<String, dynamic>;
          studentId = args['studentId'] as String?;
          category = args['category'] as String?;
        }
        return MaterialPageRoute(
          builder: (_) => AddDocumentScreen(
            initialStudentId: studentId,
            initialCategory: category,
          ),
        );
      case documentScanner:
        String? studentId;
        String? category;
        if (settings.arguments is String) {
          studentId = settings.arguments as String;
        } else if (settings.arguments is Map) {
          final args = settings.arguments as Map<String, dynamic>;
          studentId = args['studentId'] as String?;
          category = args['category'] as String?;
        }
        return MaterialPageRoute(
          builder: (_) => DocumentScannerScreen(
            initialStudentId: studentId,
            initialCategory: category,
          ),
        );
      case documentViewer:
        final doc = settings.arguments as DocumentModel;
        return MaterialPageRoute(builder: (_) => DocumentViewerScreen(document: doc));
      case Routes.settings:
        return MaterialPageRoute(builder: (_) => const MainScaffold(initialIndex: 3));
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(
              child: Text('No route defined for ${settings.name}'),
            ),
          ),
        );
    }
  }
}
