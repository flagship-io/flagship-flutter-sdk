import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class ToolsTest {
  /// Read the mock response
  static Future<String?> readFile(String path) async {
    final file = new File(testPath(path));
    final jsonString = await file.readAsString();
    return jsonString;
  }

  /// From : https://github.com/terryx/flutter-muscle/blob/master/github_provider/test/utils/test_path.dart
  static String testPath(String relativePath) {
    //Fix vscode test path
    Directory current = Directory.current;
    String path =
        current.path.endsWith('/test') ? current.path : current.path + '/test';

    return path + '/' + relativePath;
  }

  /// Initialize sqflite for test.
  static void sqfliteTestInit() {
    // Initialize ffi implementation
    sqfliteFfiInit();
    // Set global factory
    databaseFactory = databaseFactoryFfi;
  }
}
