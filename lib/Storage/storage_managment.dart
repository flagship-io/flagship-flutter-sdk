import 'dart:convert';
import 'package:flagship/flagship.dart';
import 'package:flagship/utils/logger/log_manager.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

// Trying to add database import

String lastModfiedKey = "FSLastModifiedScript";
String fileName = "cacheHits.json";

class DataBaseManagment {
  Database? _database;
  Database? _cacheVisitorDB;

  DataBaseManagment();

  Future<void> openDb() async {
    String pathToDataBase = join(await getDatabasesPath(), 'hits_database.db');

    String pathToDataBaseVisitor =
        join(await getDatabasesPath(), 'visitor_database.db');

    _database = await openDatabase(pathToDataBase, onCreate: (db, version) {
      Flagship.logger(
          Level.DEBUG, " Run the CREATE TABLE hits on the database.");
      return db.execute(
        'CREATE TABLE table_hits(id TEXT PRIMARY KEY, data_hit TEXT)',
      );
    }, version: 1);

    _cacheVisitorDB =
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
    await _database?.insert(
      'table_hits',
      hitMap,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Delete item with id
  Future<void> deleteHitWithId(String id, String nameTable) async {
    // Get a reference to the database.
    final db = _database;
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
    final db = _database;
    await db?.delete(nameTable);
  }

// Read all hit saved
  Future<List<Map>> readHits(String nameTable) async {
    //   await openDb();
    // Get the records for the tableHits
    return await _database?.rawQuery('SELECT * FROM $nameTable') ?? [];
  }

//////////////////
//// Visitor ////
//////////////////

  // Insert visitor Map data Visitor
  Future<void> insertVisitorData(Map<String, Object> visitoMap) async {
    await _cacheVisitorDB?.insert(
      'table_visitors',
      visitoMap,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Delete all reocrd
  // Delete item with id
  Future<void> deleteVisitorWithId(String id, String nameTable) async {
    // Get a reference to the database.
    final db = _cacheVisitorDB;
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
    List<Map> result = await _cacheVisitorDB
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
