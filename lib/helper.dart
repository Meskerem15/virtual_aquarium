import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;

  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'aquarium_settings.db');
    return await openDatabase(path, version: 1, onCreate: _onCreate);
  }

  Future _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE settings (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        fish_count INTEGER,
        fish_speed REAL,
        fish_color TEXT
      )
    ''');
  }

  Future<void> saveSettings(int fishCount, double fishSpeed, String fishColor) async {
    final db = await database;
    await db.insert(
      'settings',
      {
        'fish_count': fishCount,
        'fish_speed': fishSpeed,
        'fish_color': fishColor,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<Map<String, dynamic>?> loadSettings() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('settings', limit: 1);
    if (maps.isNotEmpty) {
      return maps.first;
    }
    return null;
  }
}
