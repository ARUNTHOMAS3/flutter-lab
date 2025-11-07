// lib/database_helper.dart
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:latlong2/latlong.dart';
import 'place_model.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('places.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE places(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT,
        country TEXT,
        image TEXT,
        latitude REAL,
        longitude REAL
      )
    ''');
  }

  Future<int> insertPlace(Place place) async {
    final db = await instance.database;
    return await db.insert('places', {
      'name': place.name,
      'country': place.country,
      'image': place.image,
      'latitude': place.latLng.latitude,
      'longitude': place.latLng.longitude,
    });
  }

  Future<List<Place>> getAllPlaces() async {
    final db = await instance.database;
    final result = await db.query('places');
    return result.map((row) {
      return Place(
        name: row['name'] as String,
        country: row['country'] as String,
        image: row['image'] as String,
        latLng: LatLng(
          row['latitude'] as double,
          row['longitude'] as double,
        ),
      );
    }).toList();
  }

  Future<int> updatePlace(Place place) async {
    final db = await instance.database;
    return await db.update(
      'places',
      {
        'name': place.name,
        'country': place.country,
        'image': place.image,
        'latitude': place.latLng.latitude,
        'longitude': place.latLng.longitude,
      },
      where: 'name = ? AND country = ?',
      whereArgs: [place.name, place.country],
    );
  }

  Future<void> deleteAllPlaces() async {
    final db = await instance.database;
    await db.delete('places');
  }
}
