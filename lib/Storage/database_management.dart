import 'dart:convert';
import 'dart:io';
import 'package:flagship/flagship.dart';
import 'package:flagship/utils/logger/log_manager.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

// Trying to add database import

String lastModfiedKey = "FSLastModifiedScript";
String fileName = "cacheHits.json";
String fsDirectory = "/Flagship";

class DatabaseManagement {
  Database? _hitDatabase;
  Database? _visitorDatabase;

  bool get isHDatabaseOpen {
    return _hitDatabase?.isOpen ?? false;
  }

  bool get isVDatabaseOpen {
    return _visitorDatabase?.isOpen ?? false;
  }

  DatabaseManagement();

  Future<void> openDb() async {
    // Get the document path
    final directory = await getApplicationDocumentsDirectory();

    // Get path for flagship directory or create if not exist
    Directory fsFlagshipDir =
        await Directory.fromUri(Uri.file(directory.path + fsDirectory))
            .create(recursive: true)
            .catchError((error) {
      Flagship.logger(Level.DEBUG,
          "Enable to create the flagship directory to save hit and visitor data ");
      throw Exception('Flagship, Failed to create directory flagship');
    });

    // Format the path of the hit database
    String pathToDataBase = join(fsFlagshipDir.path, 'hits_database.db');

    // Format the path for the visitor database
    String pathToDataBaseVisitor =
        join(fsFlagshipDir.path, 'visitor_database.db');

    // Open database for hits
    _hitDatabase = await openDatabase(pathToDataBase, onCreate: (db, version) {
      Flagship.logger(
          Level.DEBUG, " Run the CREATE TABLE hits on the database.");
      return db.execute(
        'CREATE TABLE table_hits(id TEXT PRIMARY KEY, data_hit TEXT)',
      );
    }, version: 1);

    // Open database for visitor data
    _visitorDatabase =
        await openDatabase(pathToDataBaseVisitor, onCreate: (db, version) {
      Flagship.logger(
          Level.DEBUG, "Run the CREATE TABLE visitor on the database");
      return db.execute(
        'CREATE TABLE table_visitors(id TEXT PRIMARY KEY, visitor TEXT)',
      );
    }, version: 1);

    return;
  }

  // Define a function that inserts dogs into the database
  Future<void> insertHitMap(Map<String, Object> hitMap) async {
    try {
      await _hitDatabase?.insert(
        'table_hits',
        hitMap,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } on Exception catch (e) {
      Flagship.logger(Level.EXCEPTIONS, e.toString());
    }
  }

  // Delete item with id
  Future<void> deleteHitWithId(String id, String nameTable) async {
    // Get a reference to the database.
    final db = _hitDatabase;
    // Remove the Dog from the database.
    await db?.delete(
      '$nameTable',
      // Use a `where` clause to delete a specific dog.
      where: 'id = ?',
      // Pass the hit's id as a whereArg to prevent SQL injection.
      whereArgs: [id],
    );
  }

// Delete all reocrd
  Future<void> deleteAllRecord(String nameTable) async {
    final db = _hitDatabase;
    await db?.delete(nameTable);
  }

// Read all hit saved
  Future<List<Map>> readHits(String nameTable) async {
    //   await openDb();
    // Get the records for the tableHits
    return await _hitDatabase?.rawQuery('SELECT * FROM $nameTable') ?? [];
  }

//////////////////
//// Visitor ////
//////////////////

  // Insert visitor Map data Visitor
  Future<void> insertVisitorData(Map<String, Object> visitoMap) async {
    try {
      await _visitorDatabase?.insert(
        'table_visitors',
        visitoMap,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } on Exception catch (e) {
      Flagship.logger(Level.EXCEPTIONS, e.toString());
    }
  }

  // Delete all reocrd
  // Delete item with id
  Future<void> deleteVisitorWithId(String id, String nameTable) async {
    // Get a reference to the database.
    final db = _visitorDatabase;
    // Remove the Dog from the database.
    await db?.delete(
      '$nameTable',
      // Use a `where` clause to delete a specific dog.
      where: 'id = ?',
      // Pass the hit's id as a whereArg to prevent SQL injection.
      whereArgs: [id],
    );
  }

  // Read all hit saved
  Future<String> readVisitor(String visitorId, String nameTable) async {
    // await openDb();
    // Get the records for the tableHits
    List<Map> result = await _visitorDatabase
            ?.rawQuery('SELECT * FROM $nameTable WHERE id = ?', [visitorId]) ??
        [];

    if (result.isNotEmpty) {
      Flagship.logger(Level.INFO,
          "The visitor: $visitorId have already a stored data in cache");
      return jsonEncode(result.last);
    } else {
      Flagship.logger(
          Level.INFO, "The visitor: $visitorId have no data stored in cache");
      return '';
    }
  }
}
