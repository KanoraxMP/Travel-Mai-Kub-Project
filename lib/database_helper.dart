import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:my_first_app_1/main.dart';
import 'weather_data_model.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();

  DatabaseHelper._init();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;

    _database = await _initDB('travel_places.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 7,
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _createDB(Database db, int version) async {
  await db.execute('''
    CREATE TABLE travel_places (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      description TEXT NOT NULL,
      category TEXT NOT NULL,
      rating INTEGER NOT NULL,
      imageUrl TEXT,
      visitDate TEXT,
      isFavorite INTEGER NOT NULL DEFAULT 0
    )
  ''');

  await db.execute('''
    CREATE TABLE weather_data (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      latitude REAL NOT NULL,
      longitude REAL NOT NULL,
      temperature REAL NOT NULL,
      fetchedAt TEXT NOT NULL
    )
  ''');

  for (final place in myTravelList) {
    await db.insert(
      'travel_places',
      place.toMap(),
    );
  }
}

Future<void> _onUpgrade(
  Database db,
  int oldVersion,
  int newVersion,
) async {
  if (oldVersion < 2) {
    await db.execute(
      'ALTER TABLE travel_places ADD COLUMN visitDate TEXT',
    );
  }

  if (oldVersion < 5) {
    await db.execute('''
      CREATE TABLE weather_data (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        latitude REAL NOT NULL,
        longitude REAL NOT NULL,
        temperature REAL NOT NULL,
        fetchedAt TEXT NOT NULL
      )
    ''');
  }

  // ตรวจสอบคอลัมน์จริง ป้องกันกรณีฐานข้อมูลไม่มี isFavorite
  final columns = await db.rawQuery(
    'PRAGMA table_info(travel_places)',
  );

  final hasFavoriteColumn = columns.any(
    (column) => column['name'] == 'isFavorite',
  );

  if (!hasFavoriteColumn) {
    await db.execute(
      'ALTER TABLE travel_places '
      'ADD COLUMN isFavorite INTEGER NOT NULL DEFAULT 0',
    );
  }
}

  Future<int> insert(TravelPlace place) async {
    final db = await database;

    return await db.insert(
      'travel_places',
      place.toMap(),
    );
  }

  Future<int> update(TravelPlace place) async {
    final db = await database;

    return await db.update(
      'travel_places',
      place.toMap(),
      where: 'id = ?',
      whereArgs: [place.id],
    );
  }

  
  Future<int> updateFavorite(int id, bool isFavorite) async {
    final db = await database;

    return await db.update(
      'travel_places',
      {'isFavorite': isFavorite ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }


  Future<int> delete(int id) async {
    final db = await database;

    return await db.delete(
      'travel_places',
      where: 'id = ?',
     whereArgs: [id],
    );
  }

  Future<List<TravelPlace>> getAll() async {
    final db = await database;
    final result = await db.query('travel_places');
    return result.map((map) => TravelPlace.fromMap(map)).toList();
  }

  Future<int> insertWeather(WeatherDataModel weather) async {
  final db = await database;

    return await db.insert(
      'weather_data',
      weather.toMap(),
    );
  }

  Future<List<WeatherDataModel>> getWeatherData() async {
  final db = await database;

  final result = await db.query(
    'weather_data',
    orderBy: 'id DESC',
  );

  return result
      .map((map) => WeatherDataModel.fromMap(map))
      .toList();
  }
}