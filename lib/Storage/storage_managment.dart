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

class DataBaseManagment {
  late Database database;
  late Database cacheVisitorDB;

  DataBaseManagment();

  openDb() async {
    String pathToDataBase = join(await getDatabasesPath(), 'hits_database.db');
    String pathToDataBaseVisitor =
        join(await getDatabasesPath(), 'visitor_database.db');

    database = await openDatabase(pathToDataBase, onCreate: (db, version) {
      print(
          "########### Run the CREATE TABLE statement on the database. ############### ");
      return db.execute(
        'CREATE TABLE table_hits(id TEXT PRIMARY KEY, data_hit TEXT)',
      );
    }, version: 1);

    cacheVisitorDB =
        await openDatabase(pathToDataBaseVisitor, onCreate: (db, version) {
      print(
          "########### Run the CREATE TABLE statement on the database. ############### ");
      return db.execute(
        'CREATE TABLE table_visitors(id TEXT PRIMARY KEY, data TEXT)',
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
  Future<void> deleteHitWithId(String id, String nameTable) async {
    // Get a reference to the database.
    final db = database;
    // Remove the Dog from the database.
    await db.delete(
      '$nameTable',
      // Use a `where` clause to delete a specific dog.
      where: 'id = ?',
      // Pass the hit's id as a whereArg to prevent SQL injection.
      whereArgs: [id],
    );
  }

// Delete all reocrd
  Future<void> deleteAllRecord(String nameTable) async {
    final db = database;
    await db.delete(nameTable);
  }

// Read all hit saved
  Future<List<Map>> readHits(String nameTable) async {
    await openDb();
    // Get the records for the tableHits
    return await database.rawQuery('SELECT * FROM $nameTable');
  }

//////////////////
//// Visitor ////
//////////////////

  // Insert visitor Map data Visitor
  Future<void> insertVisitorData(Map<String, Object> visitoMap) async {
    await cacheVisitorDB.insert(
      'table_visitors',
      visitoMap,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Delete all reocrd
  // Delete item with id
  // TODO refractor this function
  Future<void> deleteVisitorWithId(String id, String nameTable) async {
    // Get a reference to the database.
    final db = cacheVisitorDB;
    // Remove the Dog from the database.
    await db.delete(
      '$nameTable',
      // Use a `where` clause to delete a specific dog.
      where: 'id = ?',
      // Pass the hit's id as a whereArg to prevent SQL injection.
      whereArgs: [id],
    );
  }

  // Read all hit saved
  Future<String> readVisitor(String nameTable) async {
    await openDb();
    // Get the records for the tableHits
    List<Map> result =
        await cacheVisitorDB.rawQuery('SELECT * FROM $nameTable');

    return jsonEncode(result.last);
  }
}
