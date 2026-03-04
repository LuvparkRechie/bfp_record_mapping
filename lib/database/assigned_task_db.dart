import 'dart:async';

import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class AssignedTaskDatabase {
  static final AssignedTaskDatabase instance = AssignedTaskDatabase._init();
  static Database? _database;

  AssignedTaskDatabase._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('assigned_tasks.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(path, version: 2, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE assigned_tasks (
        id INTEGER PRIMARY KEY,
        assigned_id INTEGER,
        establishment_id INTEGER,
        inspector_id INTEGER,
        schedule_date TEXT,
        status TEXT,
        created_at TEXT,
        business_name TEXT,
        street_address TEXT,
        latitude REAL,
        longitude REAL,
        synced INTEGER DEFAULT 1,
        last_updated TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');
  }

  // ==================== CRUD OPERATIONS ====================

  // Insert a single task
  Future<void> insertTask(Map<String, dynamic> taskData) async {
    final db = await instance.database;

    // Add synced flag (1 since it came from API)
    taskData['synced'] = 1;

    await db.insert(
      'assigned_tasks',
      taskData,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Insert multiple tasks (for bulk sync)
  Future<void> insertTasks(List<Map<String, dynamic>> tasksData) async {
    final db = await instance.database;
    final batch = db.batch();

    for (var task in tasksData) {
      task['synced'] = 1;
      batch.insert(
        'assigned_tasks',
        task,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    await batch.commit(noResult: true);
  }

  // Get all tasks
  Future<List<Map<String, dynamic>>> getAllTasks() async {
    final db = await instance.database;
    return await db.query('assigned_tasks', orderBy: 'schedule_date DESC');
  }

  // Get task by assigned_id
  Future<Map<String, dynamic>?> getTaskById(int assignedId) async {
    final db = await instance.database;
    final results = await db.query(
      'assigned_tasks',
      where: 'assigned_id = ?',
      whereArgs: [assignedId],
    );

    return results.isNotEmpty ? results.first : {};
  }

  // Get tasks by inspector ID
  Future<List<Map<String, dynamic>>> getTasksByInspector(
    int inspectorId,
  ) async {
    final db = await instance.database;
    return await db.query(
      'assigned_tasks',
      where: 'inspector_id = ?',
      whereArgs: [inspectorId],
      orderBy: 'schedule_date DESC',
    );
  }

  // Get tasks by status
  Future<List<Map<String, dynamic>>> getTasksByStatus(String status) async {
    final db = await instance.database;
    return await db.query(
      'assigned_tasks',
      where: 'status = ?',
      whereArgs: [status],
      orderBy: 'schedule_date DESC',
    );
  }

  // Get pending tasks
  Future<List<Map<String, dynamic>>> getPendingTasks() async {
    return await getTasksByStatus('PENDING');
  }

  // Get tasks by date range
  Future<List<Map<String, dynamic>>> getTasksByDateRange(
    String startDate,
    String endDate,
  ) async {
    final db = await instance.database;
    return await db.query(
      'assigned_tasks',
      where: 'schedule_date BETWEEN ? AND ?',
      whereArgs: [startDate, endDate],
      orderBy: 'schedule_date DESC',
    );
  }

  // Update task status
  Future<int> updateTaskStatus(int assignedId, String newStatus) async {
    final db = await instance.database;
    return await db.update(
      'assigned_tasks',
      {'status': newStatus, 'last_updated': DateTime.now().toIso8601String()},
      where: 'assigned_id = ?',
      whereArgs: [assignedId],
    );
  }

  // Update entire task
  Future<int> updateTask(int assignedId, Map<String, dynamic> updates) async {
    final db = await instance.database;
    updates['last_updated'] = DateTime.now().toIso8601String();

    return await db.update(
      'assigned_tasks',
      updates,
      where: 'assigned_id = ?',
      whereArgs: [assignedId],
    );
  }

  // Delete a task
  Future<int> deleteTask(int assignedId) async {
    final db = await instance.database;
    return await db.delete(
      'assigned_tasks',
      where: 'assigned_id = ?',
      whereArgs: [assignedId],
    );
  }

  // Delete all tasks
  Future<void> deleteAllTasks() async {
    final db = await instance.database;
    await db.delete('assigned_tasks');
  }

  // ==================== SYNC METHODS ====================

  // Sync with API data
  Future<void> syncWithApi(List<Map<String, dynamic>> apiTasks) async {
    final db = await instance.database;

    // Get all local tasks
    final localTasks = await db.query('assigned_tasks');
    final localIds = localTasks.map((e) => e['assigned_id'] as int).toList();
    final apiIds = apiTasks.map((e) => e['assigned_id'] as int).toList();

    final batch = db.batch();

    // Insert or update tasks from API
    for (var apiTask in apiTasks) {
      final assignedId = apiTask['assigned_id'] as int;

      // Mark as synced (from API)
      apiTask['synced'] = 1;
      apiTask['last_updated'] = DateTime.now().toIso8601String();

      batch.insert(
        'assigned_tasks',
        apiTask,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    // Delete local tasks that are not in API
    for (var localId in localIds) {
      if (!apiIds.contains(localId)) {
        batch.delete(
          'assigned_tasks',
          where: 'assigned_id = ?',
          whereArgs: [localId],
        );
      }
    }

    await batch.commit(noResult: true);
  }

  // Get unsynced tasks (for uploading to server)
  Future<List<Map<String, dynamic>>> getUnsyncedTasks() async {
    final db = await instance.database;
    return await db.query('assigned_tasks', where: 'synced = 0');
  }

  // Mark task as synced
  Future<int> markTaskAsSynced(int assignedId) async {
    final db = await instance.database;
    return await db.update(
      'assigned_tasks',
      {'synced': 1},
      where: 'assigned_id = ?',
      whereArgs: [assignedId],
    );
  }

  // ==================== UTILITY METHODS ====================

  // Get task count
  Future<int> getTaskCount() async {
    final db = await instance.database;
    final result = await db.rawQuery('SELECT COUNT(*) FROM assigned_tasks');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  // Get tasks for today
  Future<List<Map<String, dynamic>>> getTodaysTasks() async {
    final today = DateTime.now().toString().split(' ')[0];
    final db = await instance.database;

    return await db.query(
      'assigned_tasks',
      where: 'schedule_date LIKE ?',
      whereArgs: ['$today%'],
      orderBy: 'schedule_date ASC',
    );
  }

  // Search tasks by business name
  Future<List<Map<String, dynamic>>> searchTasks(String query) async {
    final db = await instance.database;
    return await db.query(
      'assigned_tasks',
      where: 'business_name LIKE ? OR street_address LIKE ?',
      whereArgs: ['%$query%', '%$query%'],
      orderBy: 'schedule_date DESC',
    );
  }

  // Close database
  Future close() async {
    final db = await instance.database;
    db.close();
  }
}
