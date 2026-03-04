import 'dart:async';

import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class ChecklistDatabase {
  static final ChecklistDatabase instance = ChecklistDatabase._init();
  static Database? _database;

  ChecklistDatabase._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('checklist.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE checklist_template (
        template_id INTEGER PRIMARY KEY,
        section TEXT,
        subsection TEXT,
        item_text TEXT,
        field_type TEXT,
        checkbox_options TEXT,
        measurement_label TEXT,
        measurement_unit TEXT,
        table_columns TEXT,
        group_id INTEGER,
        display_order INTEGER,
        created_at TEXT,
        updated_at TEXT
      )
    ''');
  }

  // ==================== CRUD OPERATIONS ====================

  // Insert a single checklist item
  Future<void> insertItem(Map<String, dynamic> item) async {
    final db = await instance.database;
    await db.insert(
      'checklist_template',
      item,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Bulk insert multiple checklist items
  Future<void> insertItems(List<Map<String, dynamic>> items) async {
    final db = await instance.database;
    final batch = db.batch();
    for (var item in items) {
      batch.insert(
        'checklist_template',
        item,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  // Get all checklist items, sorted by display_order
  Future<List<Map<String, dynamic>>> getAllItems() async {
    final db = await instance.database;
    return await db.query('checklist_template', orderBy: 'display_order ASC');
  }

  // Get checklist items by section
  Future<List<Map<String, dynamic>>> getItemsBySection(String section) async {
    final db = await instance.database;
    return await db.query(
      'checklist_template',
      where: 'section = ?',
      whereArgs: [section],
      orderBy: 'display_order ASC',
    );
  }

  // Get a single checklist item by template_id
  Future<Map<String, dynamic>?> getItemById(int templateId) async {
    final db = await instance.database;
    final results = await db.query(
      'checklist_template',
      where: 'template_id = ?',
      whereArgs: [templateId],
    );
    return results.isNotEmpty ? results.first : null;
  }

  // Update a checklist item
  Future<int> updateItem(int templateId, Map<String, dynamic> updates) async {
    final db = await instance.database;
    updates['updated_at'] = DateTime.now().toIso8601String();
    return await db.update(
      'checklist_template',
      updates,
      where: 'template_id = ?',
      whereArgs: [templateId],
    );
  }

  // Delete a checklist item
  Future<int> deleteItem(int templateId) async {
    final db = await instance.database;
    return await db.delete(
      'checklist_template',
      where: 'template_id = ?',
      whereArgs: [templateId],
    );
  }

  // Delete all checklist items
  Future<void> deleteAllItems() async {
    final db = await instance.database;
    await db.delete('checklist_template');
  }

  // Get checklist count
  Future<int> getItemCount() async {
    final db = await instance.database;
    final result = await db.rawQuery('SELECT COUNT(*) FROM checklist_template');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  // Close database
  Future close() async {
    final db = await instance.database;
    db.close();
  }
}
