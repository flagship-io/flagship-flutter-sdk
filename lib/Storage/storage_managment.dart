import 'dart:convert';
import 'dart:io';

import 'package:flagship/flagship.dart';
import 'package:flagship/utils/logger/log_manager.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

/// Trying to add database import

String lastModfiedKey = "FSLastModifiedScript";
String hitCacheFolder = "/flagship/cache/hits/";
String fileName = "cacheHits.json";

// class StorageManagment {
//   // Store the json that represent the entire hits
//   static void storeJson(String jsonToStore) async {
//     final directory = await getApplicationDocumentsDirectory();
//     Directory bucketingDirectory =
//         await Directory.fromUri(Uri.file(directory.path + hitCacheFolder))
//             .create(recursive: true)
//             .catchError((error) {
//       Flagship.logger(Level.DEBUG,
//           "Enable to create the directory to save the cache hits file ");
//     });
//     // We got the path to save the json file
//     File jsonFile = File(bucketingDirectory.path + fileName);
//     jsonFile.writeAsString(jsonToStore);
//   }

// // Read the file where we store the hits as json and convert to map before returning it
//   static Future<Map<String, Map<String, Object>>> readHisJson() async {
//     final directory = await getApplicationDocumentsDirectory();
//     File jsonFile = File(directory.path + hitCacheFolder + fileName);
//     if (jsonFile.existsSync() == true) {
//       // Convert to json
//       String jsonResult = jsonFile.readAsStringSync();
//       return JsonDecoder().convert(jsonResult);
//     } else {
//       throw Exception('Flagship, Failed to read bucketing script');
//     }
//   }

//   // Delete the file where we store all the hits
//   static deleteFile(String pathForFile) {
//     File jsonFile = File(pathForFile);
//     // Delete the file
//     if (jsonFile.existsSync() == true) {
//       jsonFile.delete(recursive: true);
//     }
//   }
// }

class DataBaseManagment {
  late Database database;

  DataBaseManagment();

  openDb() async {
    String pathToDataBase = join(await getDatabasesPath(), 'hits_database.db');
    database = await openDatabase(pathToDataBase, onCreate: (db, version) {
      print(
          "########### Run the CREATE TABLE statement on the database. ############### ");
      return db.execute(
        'CREATE TABLE table_hits(id TEXT PRIMARY KEY, data_hit JSON)',
      );
    }, version: 1);
  }

  // Define a function that inserts dogs into the database
  Future<void> insertHitMap(Map<String, Object> hitMap) async {
    await database.insert(
      'table_hits',
      hitMap,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Delete item with id
  Future<void> deleteHitWithId(String id) async {
    // Get a reference to the database.
    final db = database;
    // Remove the Dog from the database.
    await db.delete(
      'table_hits',
      // Use a `where` clause to delete a specific dog.
      where: 'id = ?',
      // Pass the hit's id as a whereArg to prevent SQL injection.
      whereArgs: [id],
    );
  }

  Future<void> deleteAllRecord() async {
    final db = database;
    await db.delete('table_hits');
  }

// To implement later
  Future<List<Map>> readHits(String nameTable) async {
    await openDb();
    // Get the records for the tableHits
    List<Map> list = await database.rawQuery('SELECT * FROM table_hits');
    return list;
  }
}
