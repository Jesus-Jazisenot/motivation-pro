import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/quote.dart';
import '../models/user_profile.dart';
import '../models/daily_stats.dart';

/// Helper para gestionar la base de datos SQLite
class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  /// Obtener instancia de la base de datos
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('motivation_pro.db');
    return _database!;
  }

  /// Inicializar base de datos
  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  /// Crear tablas
  Future<void> _createDB(Database db, int version) async {
    // Tabla de frases
    await db.execute('''
      CREATE TABLE quotes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        text TEXT NOT NULL,
        author TEXT,
        category TEXT NOT NULL,
        source TEXT DEFAULT 'local',
        language TEXT DEFAULT 'es',
        length INTEGER,
        created_at TEXT NOT NULL,
        last_shown TEXT,
        view_count INTEGER DEFAULT 0,
        is_favorite INTEGER DEFAULT 0
      )
    ''');

    // Tabla de perfil de usuario
    await db.execute('''
      CREATE TABLE user_profile (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        challenges TEXT,
        preferred_times TEXT,
        values TEXT,
        tone_preference TEXT DEFAULT 'balanced',
        created_at TEXT NOT NULL,
        level INTEGER DEFAULT 1,
        total_xp INTEGER DEFAULT 0,
        current_streak INTEGER DEFAULT 0,
        max_streak INTEGER DEFAULT 0
      )
    ''');

    // Tabla de estadísticas diarias
    await db.execute('''
      CREATE TABLE daily_stats (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL UNIQUE,
        quotes_viewed INTEGER DEFAULT 0,
        time_spent_seconds INTEGER DEFAULT 0,
        categories_viewed TEXT,
        reflections_written INTEGER DEFAULT 0
      )
    ''');

    print('✅ Tablas creadas correctamente');
  }

  /// Cerrar base de datos
  Future<void> close() async {
    final db = await instance.database;
    db.close();
  }

  // ==========================================
  // OPERACIONES CRUD - QUOTES
  // ==========================================

  /// Insertar frase
  Future<int> insertQuote(Quote quote) async {
    final db = await database;
    return await db.insert('quotes', quote.toMap());
  }

  /// Obtener todas las frases
  Future<List<Quote>> getAllQuotes() async {
    final db = await database;
    final result = await db.query('quotes');
    return result.map((map) => Quote.fromMap(map)).toList();
  }

  /// Obtener frases favoritas
  Future<List<Quote>> getFavoriteQuotes() async {
    final db = await database;
    final result = await db.query(
      'quotes',
      where: 'is_favorite = ?',
      whereArgs: [1],
    );
    return result.map((map) => Quote.fromMap(map)).toList();
  }

  /// Obtener frase por ID
  Future<Quote?> getQuoteById(int id) async {
    final db = await database;
    final result = await db.query(
      'quotes',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (result.isNotEmpty) {
      return Quote.fromMap(result.first);
    }
    return null;
  }

  /// Actualizar frase
  Future<int> updateQuote(Quote quote) async {
    final db = await database;
    return await db.update(
      'quotes',
      quote.toMap(),
      where: 'id = ?',
      whereArgs: [quote.id],
    );
  }

  /// Eliminar frase
  Future<int> deleteQuote(int id) async {
    final db = await database;
    return await db.delete(
      'quotes',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Obtener frase aleatoria no vista recientemente
  Future<Quote?> getRandomQuote() async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT * FROM quotes 
      WHERE last_shown IS NULL OR last_shown < datetime('now', '-1 day')
      ORDER BY RANDOM() 
      LIMIT 1
    ''');
    if (result.isNotEmpty) {
      return Quote.fromMap(result.first);
    }
    return null;
  }

  // ==========================================
  // OPERACIONES CRUD - USER PROFILE
  // ==========================================

  /// Insertar perfil de usuario
  Future<int> insertUserProfile(UserProfile profile) async {
    final db = await database;
    return await db.insert('user_profile', profile.toMap());
  }

  /// Obtener perfil de usuario
  Future<UserProfile?> getUserProfile() async {
    final db = await database;
    final result = await db.query('user_profile', limit: 1);
    if (result.isNotEmpty) {
      return UserProfile.fromMap(result.first);
    }
    return null;
  }

  /// Actualizar perfil de usuario
  Future<int> updateUserProfile(UserProfile profile) async {
    final db = await database;
    return await db.update(
      'user_profile',
      profile.toMap(),
      where: 'id = ?',
      whereArgs: [profile.id],
    );
  }

  // ==========================================
  // OPERACIONES CRUD - DAILY STATS
  // ==========================================

  /// Insertar o actualizar estadísticas del día
  Future<int> upsertDailyStats(DailyStats stats) async {
    final db = await database;
    return await db.insert(
      'daily_stats',
      stats.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Obtener estadísticas de un día específico
  Future<DailyStats?> getDailyStats(DateTime date) async {
    final db = await database;
    final dateStr =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    final result = await db.query(
      'daily_stats',
      where: 'date = ?',
      whereArgs: [dateStr],
    );
    if (result.isNotEmpty) {
      return DailyStats.fromMap(result.first);
    }
    return null;
  }

  /// Obtener estadísticas de los últimos N días
  Future<List<DailyStats>> getRecentStats(int days) async {
    final db = await database;
    final result = await db.query(
      'daily_stats',
      orderBy: 'date DESC',
      limit: days,
    );
    return result.map((map) => DailyStats.fromMap(map)).toList();
  }

  /// Obtener total de frases vistas
  Future<int> getTotalQuotesViewed() async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT SUM(quotes_viewed) as total FROM daily_stats',
    );
    return result.first['total'] as int? ?? 0;
  }
}
