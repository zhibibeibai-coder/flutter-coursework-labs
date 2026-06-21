import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import 'contact.dart';

class ContactDatabase {
  ContactDatabase._();

  static final ContactDatabase instance = ContactDatabase._();

  Database? _database;

  Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }
    final String dbPath = await getDatabasesPath();
    _database = await openDatabase(
      p.join(dbPath, 'mini_contacts.db'),
      version: 1,
      onCreate: (Database db, int version) async {
        await db.execute('''
            CREATE TABLE contacts(
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              studentId TEXT NOT NULL,
              name TEXT NOT NULL,
              phone TEXT NOT NULL,
              avatar TEXT NOT NULL
            )
          ''');
      },
    );
    return _database!;
  }

  Future<void> seedFromAssetIfEmpty() async {
    final Database db = await database;
    final List<Map<String, Object?>> rows = await db.rawQuery(
      'SELECT COUNT(*) AS count FROM contacts',
    );
    final int count = rows.first['count'] as int;
    if (count > 0) {
      return;
    }
    final String jsonText = await rootBundle.loadString(
      'assets/json/contacts.json',
    );
    final List<dynamic> contacts = json.decode(jsonText) as List<dynamic>;
    final Batch batch = db.batch();
    for (final dynamic item in contacts) {
      batch.insert(
        'contacts',
        Contact.fromJson(item as Map<String, dynamic>).toMap(),
      );
    }
    await batch.commit(noResult: true);
  }

  Future<List<Contact>> readAll() async {
    final Database db = await database;
    final List<Map<String, Object?>> rows = await db.query(
      'contacts',
      orderBy: 'studentId ASC',
    );
    return rows.map(Contact.fromMap).toList();
  }

  Future<void> insert(Contact contact) async {
    final Database db = await database;
    await db.insert('contacts', contact.toMap());
  }

  Future<void> update(Contact contact) async {
    final Database db = await database;
    await db.update(
      'contacts',
      contact.toMap(),
      where: 'id = ?',
      whereArgs: <Object?>[contact.id],
    );
  }

  Future<void> delete(int id) async {
    final Database db = await database;
    await db.delete('contacts', where: 'id = ?', whereArgs: <Object?>[id]);
  }
}
