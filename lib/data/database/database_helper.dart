import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/quote.dart';
import '../models/user_profile.dart';
import '../models/daily_stats.dart';
import '../../core/services/quote_api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/services/translation_service.dart';
import '../../core/services/connectivity_service.dart';
import '../models/notification_schedule.dart';
import '../models/reflection.dart';
import '../models/mood_entry.dart';
import '../models/affirmation.dart';
import '../models/habit.dart';

/// Helper para gestionar la base de datos SQLite
class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  /// Obtener instancia de la base de datos
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('motivation_pro_v2.db');
    return _database!;
  }

  /// Inicializar base de datos
  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 5,
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
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

    // Tabla de horarios de notificaciones
    await db.execute('''
      CREATE TABLE notification_schedules(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        time TEXT NOT NULL,
        label TEXT NOT NULL,
        days TEXT NOT NULL,
        enabled INTEGER DEFAULT 1
      )
    ''');

    // Tabla de perfil de usuario
    await db.execute('''
      CREATE TABLE user_profile (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        challenges TEXT,
        preferred_times TEXT,
        user_values TEXT,
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

    // Tabla de reflexiones
    await db.execute('''
      CREATE TABLE reflections (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        quote_id INTEGER,
        quote_text TEXT NOT NULL,
        text TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');

    // Tabla de estado de ánimo
    await db.execute('''
      CREATE TABLE moods (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        mood INTEGER NOT NULL,
        note TEXT,
        quote_id INTEGER,
        created_at TEXT NOT NULL
      )
    ''');

    // Tabla de afirmaciones personales
    await db.execute('''
      CREATE TABLE affirmations (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        text TEXT NOT NULL,
        active INTEGER DEFAULT 1,
        created_at TEXT NOT NULL
      )
    ''');

    // Tabla de hábitos
    await db.execute('''
      CREATE TABLE habits (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        description TEXT,
        active INTEGER DEFAULT 1,
        current_streak INTEGER DEFAULT 0,
        max_streak INTEGER DEFAULT 0,
        last_completed_date TEXT,
        created_at TEXT NOT NULL
      )
    ''');

    print('✅ Tablas creadas correctamente - Versión $version');
  }

  /// Actualizar base de datos
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    print('🔄 Actualizando base de datos de v$oldVersion a v$newVersion');

    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS notification_schedules(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          time TEXT NOT NULL,
          label TEXT NOT NULL,
          days TEXT NOT NULL,
          enabled INTEGER DEFAULT 1
        )
      ''');
    }

    if (oldVersion < 3) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS reflections (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          quote_id INTEGER,
          quote_text TEXT NOT NULL,
          text TEXT NOT NULL,
          created_at TEXT NOT NULL
        )
      ''');
    }

    if (oldVersion < 4) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS moods (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          mood INTEGER NOT NULL,
          note TEXT,
          quote_id INTEGER,
          created_at TEXT NOT NULL
        )
      ''');
      await db.execute('''
        CREATE TABLE IF NOT EXISTS affirmations (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          text TEXT NOT NULL,
          active INTEGER DEFAULT 1,
          created_at TEXT NOT NULL
        )
      ''');
    }

    if (oldVersion < 5) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS habits (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          description TEXT,
          active INTEGER DEFAULT 1,
          current_streak INTEGER DEFAULT 0,
          max_streak INTEGER DEFAULT 0,
          last_completed_date TEXT,
          created_at TEXT NOT NULL
        )
      ''');
    }
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

  /// Obtener frase aleatoria con sistema anti-repetición
  Future<Quote?> getRandomQuote() async {
    try {
      final db = await database;

      // 1. PRIORIDAD MÁXIMA: Frases NUNCA vistas
      var result = await db.rawQuery('''
        SELECT * FROM quotes 
        WHERE last_shown IS NULL
        ORDER BY RANDOM() 
        LIMIT 1
      ''');

      if (result.isNotEmpty) {
        print('✅ Frase NUEVA (nunca vista)');
        return Quote.fromMap(result.first);
      }

      // 2. PRIORIDAD ALTA: Frases no vistas en las últimas 12 horas
      result = await db.rawQuery('''
        SELECT * FROM quotes 
        WHERE last_shown < datetime('now', '-12 hours')
        ORDER BY view_count ASC, RANDOM() 
        LIMIT 1
      ''');

      if (result.isNotEmpty) {
        print('✅ Frase no vista en 12h');
        return Quote.fromMap(result.first);
      }

      // 3. PRIORIDAD MEDIA: Frases no vistas en las últimas 6 horas
      result = await db.rawQuery('''
        SELECT * FROM quotes 
        WHERE last_shown < datetime('now', '-6 hours')
        ORDER BY view_count ASC, RANDOM() 
        LIMIT 1
      ''');

      if (result.isNotEmpty) {
        print('✅ Frase no vista en 6h');
        return Quote.fromMap(result.first);
      }

      // 4. PRIORIDAD BAJA: Frases no vistas en la última hora
      result = await db.rawQuery('''
        SELECT * FROM quotes 
        WHERE last_shown < datetime('now', '-1 hour')
        ORDER BY view_count ASC, RANDOM() 
        LIMIT 1
      ''');

      if (result.isNotEmpty) {
        print('✅ Frase no vista en 1h');
        return Quote.fromMap(result.first);
      }

      // 5. ÚLTIMO RECURSO: La menos vista
      result = await db.rawQuery('''
        SELECT * FROM quotes 
        ORDER BY view_count ASC, last_shown ASC, RANDOM() 
        LIMIT 1
      ''');

      if (result.isNotEmpty) {
        print('⚠️ Usando frase menos vista (todas vistas recientemente)');
        return Quote.fromMap(result.first);
      }

      // 6. Si NO hay frases, cargar iniciales
      print('⚠️ No hay frases en BD - Cargando iniciales');
      await _loadInitialQuotes();

      result = await db.rawQuery('''
        SELECT * FROM quotes 
        ORDER BY RANDOM() 
        LIMIT 1
      ''');

      if (result.isNotEmpty) {
        print('✅ Frase inicial cargada');
        return Quote.fromMap(result.first);
      }

      // 7. EMERGENCIA: Crear frase manual
      print('🚨 Creando frase de emergencia');
      final emergency = Quote(
        text:
            'El éxito es la suma de pequeños esfuerzos repetidos día tras día.',
        author: 'Robert Collier',
        category: 'Motivación',
        language: 'es',
        lastShown: null,
        viewCount: 0,
      );

      await insertQuote(emergency);
      return emergency;
    } catch (e) {
      print('🚨 Error crítico en getRandomQuote: $e');
      return Quote(
        text: 'Activa las APIs en Settings para miles de frases nuevas',
        author: 'Motivation PRO',
        category: 'Motivación',
        language: 'es',
        lastShown: null,
        viewCount: 0,
      );
    }
  }

  // ==========================================
  // OPERACIONES CRUD - USER PROFILE
  // ==========================================

  /// Insertar perfil de usuario
  Future<int> insertUserProfile(UserProfile profile) async {
    try {
      final db = await database;
      print('💾 Insertando perfil: ${profile.name}');
      final id = await db.insert('user_profile', profile.toMap());
      print('✅ Perfil insertado con ID: $id');
      return id;
    } catch (e) {
      print('❌ Error insertando perfil: $e');
      rethrow;
    }
  }

  /// Obtener perfil de usuario
  Future<UserProfile?> getUserProfile() async {
    try {
      final db = await database;
      final result = await db.query('user_profile', limit: 1);
      if (result.isNotEmpty) {
        print('✅ Perfil encontrado: ${result.first['name']}');
        return UserProfile.fromMap(result.first);
      }
      print('ℹ️ No hay perfil guardado');
      return null;
    } catch (e) {
      print('❌ Error obteniendo perfil: $e');
      return null;
    }
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

  // ==========================================
  // OPERACIONES CRUD - NOTIFICATION SCHEDULES
  // ==========================================

  /// Insertar horario de notificación
  Future<int> insertSchedule(NotificationSchedule schedule) async {
    final db = await database;
    return await db.insert('notification_schedules', schedule.toMap());
  }

  /// Obtener todos los horarios
  Future<List<NotificationSchedule>> getAllSchedules() async {
    final db = await database;
    final List<Map<String, dynamic>> maps =
        await db.query('notification_schedules', orderBy: 'time ASC');
    return maps.map((map) => NotificationSchedule.fromMap(map)).toList();
  }

  /// Actualizar horario
  Future<int> updateSchedule(NotificationSchedule schedule) async {
    final db = await database;
    return await db.update(
      'notification_schedules',
      schedule.toMap(),
      where: 'id = ?',
      whereArgs: [schedule.id],
    );
  }

  /// Eliminar horario
  Future<int> deleteSchedule(int id) async {
    final db = await database;
    return await db.delete(
      'notification_schedules',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ==========================================
  // MÉTODOS HÍBRIDOS Y TRADUCCIÓN
  // ==========================================

  /// Obtener frase híbrida con filtro de idioma Y traducción automática
  Future<Quote?> getHybridQuote() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final useApi = prefs.getBool('use_api') ?? true;
      final languagePref = prefs.getString('language_preference') ?? 'both';

      print('⚙️ Preferencias: API=$useApi, Idioma=$languagePref');

      // Si no quiere usar APIs, solo local
      if (!useApi) {
        print('💾 APIs desactivadas - usando local');
        return await getRandomQuote();
      }

      // Verificar conexión ANTES de intentar APIs
      final connectivityService = ConnectivityService.instance;
      final hasInternet = await connectivityService.hasConnection();

      if (!hasInternet) {
        print('📡 Sin internet - usando cache local');
        return await getRandomQuote();
      }

      final db = await database;
      final apiService = QuoteApiService.instance;
      const maxAttempts = 10;

      // INTENTAR OBTENER FRASE NUEVA DE API
      for (int attempt = 1; attempt <= maxAttempts; attempt++) {
        print('🔄 Intento $attempt de $maxAttempts');

        Quote? quote;
        try {
          final apiQuote =
              await apiService.getRandomQuote().timeout(Duration(seconds: 5));

          if (apiQuote != null) {
            quote = apiService.apiQuoteToQuote(apiQuote);
            print('📡 Frase obtenida de API (inglés)');
          } else {
            print('⚠️ API retornó null');
            continue;
          }
        } catch (e) {
          print('API error en intento $attempt: $e');
          continue;
        }

        if (quote == null) continue;

        // APLICAR PREFERENCIA DE IDIOMA

        // 1. Usuario quiere SOLO ESPAÑOL
        if (languagePref == 'es') {
          print('🇪🇸 Traduciendo frase a español...');

          final translationService = TranslationService.instance;
          final translatedText =
              await translationService.translateToSpanish(quote.text);

          // Verificar si ya existe
          final existing = await db.rawQuery('''
          SELECT * FROM quotes 
          WHERE text = ?
          LIMIT 1
        ''', [translatedText]);

          if (existing.isNotEmpty) {
            print('⚠️ Traducción ya existe, intento $attempt');
            continue;
          }

          // Crear nueva frase traducida
          final translatedQuote = Quote(
            text: translatedText,
            author: quote.author,
            category: quote.category,
            source: 'api-translated',
            language: 'es',
            lastShown: null,
            viewCount: 0,
          );

          try {
            await insertQuote(translatedQuote);
            print('✅ Nueva traducción guardada');
          } catch (e) {
            print('Error guardando: $e');
          }

          return translatedQuote;
        }

        // 2. Usuario quiere SOLO INGLÉS
        else if (languagePref == 'en') {
          print('🇬🇧 Frase en inglés (original de API)');

          // Verificar si ya existe
          final existing = await db.rawQuery('''
          SELECT * FROM quotes 
          WHERE text = ?
          LIMIT 1
        ''', [quote.text]);

          if (existing.isNotEmpty) {
            print('⚠️ Frase ya existe, intento $attempt');
            continue;
          }

          // Marcar como inglés
          final englishQuote = quote.copyWith(language: 'en');

          try {
            await insertQuote(englishQuote);
            print('✅ Nueva frase en inglés guardada');
          } catch (e) {
            print('Error guardando: $e');
          }

          return englishQuote;
        }

        // 3. Usuario quiere AMBOS
        else {
          print('🌐 Modo mixto');

          // 50% traducir, 50% inglés
          final shouldTranslate = DateTime.now().second % 2 == 0;

          if (shouldTranslate) {
            print('🔄 Traduciendo a español (mixto)...');
            final translationService = TranslationService.instance;
            final translatedText =
                await translationService.translateToSpanish(quote.text);

            // Verificar duplicado
            final existing = await db.rawQuery('''
            SELECT * FROM quotes 
            WHERE text = ?
            LIMIT 1
          ''', [translatedText]);

            if (existing.isNotEmpty) {
              print('⚠️ Ya existe, intento $attempt');
              continue;
            }

            final translatedQuote = Quote(
              text: translatedText,
              author: quote.author,
              category: quote.category,
              source: 'api-translated',
              language: 'es',
              lastShown: null,
              viewCount: 0,
            );

            try {
              await insertQuote(translatedQuote);
              print('✅ Traducción guardada (mixto)');
            } catch (e) {
              print('Error: $e');
            }

            return translatedQuote;
          } else {
            print('📡 Frase en inglés (mixto)');

            // Verificar duplicado
            final existing = await db.rawQuery('''
            SELECT * FROM quotes 
            WHERE text = ?
            LIMIT 1
          ''', [quote.text]);

            if (existing.isNotEmpty) {
              print('⚠️ Ya existe, intento $attempt');
              continue;
            }

            final englishQuote = quote.copyWith(language: 'en');

            try {
              await insertQuote(englishQuote);
              print('✅ Frase en inglés guardada (mixto)');
            } catch (e) {
              print('Error: $e');
            }

            return englishQuote;
          }
        }
      }

      // Si después de intentos no encontró nada nuevo, usar local
      print('⚠️ Después de $maxAttempts intentos, usando frases locales');
      return await getRandomQuote();
    } catch (e) {
      print('🚨 Error en hybrid: $e');
      return await getRandomQuote();
    }
  }

  // ==========================================
  // FRASE DEL DÍA
  // ==========================================

  /// Devuelve la misma frase todo el día; cambia a medianoche
  Future<Quote?> getDailyQuote() async {
    final prefs = await SharedPreferences.getInstance();
    final today =
        '${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().day.toString().padLeft(2, '0')}';
    final savedDate = prefs.getString('daily_quote_date');
    final savedId = prefs.getInt('daily_quote_id');

    if (savedDate == today && savedId != null) {
      final quote = await getQuoteById(savedId);
      if (quote != null) return quote;
    }

    final quote = await getRandomQuote();
    if (quote?.id != null) {
      await prefs.setString('daily_quote_date', today);
      await prefs.setInt('daily_quote_id', quote!.id!);
    }
    return quote;
  }

  // ==========================================
  // BÚSQUEDA Y FILTRADO
  // ==========================================

  /// Buscar frases por texto o autor
  Future<List<Quote>> searchQuotes(String query) async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT * FROM quotes
      WHERE text LIKE ? OR author LIKE ?
      ORDER BY view_count DESC
      LIMIT 50
    ''', ['%$query%', '%$query%']);
    return result.map((map) => Quote.fromMap(map)).toList();
  }

  /// Obtener frases por categoría
  Future<List<Quote>> getQuotesByCategory(String category) async {
    final db = await database;
    final result = await db.query(
      'quotes',
      where: 'category = ?',
      whereArgs: [category],
      orderBy: 'view_count DESC',
      limit: 50,
    );
    return result.map((map) => Quote.fromMap(map)).toList();
  }

  /// Obtener todas las categorías distintas
  Future<List<String>> getCategories() async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT DISTINCT category FROM quotes ORDER BY category ASC',
    );
    return result.map((row) => row['category'] as String).toList();
  }

  // ==========================================
  // OPERACIONES CRUD - REFLEXIONES
  // ==========================================

  Future<int> insertReflection(Reflection reflection) async {
    final db = await database;
    final id = await db.insert('reflections', reflection.toMap());

    // Actualizar contador en daily_stats
    final today = DateTime.now();
    var stats = await getDailyStats(today);
    if (stats == null) {
      stats = DailyStats(date: today, reflectionsWritten: 1);
    } else {
      stats = stats.copyWith(
          reflectionsWritten: stats.reflectionsWritten + 1);
    }
    await upsertDailyStats(stats);

    return id;
  }

  Future<List<Reflection>> getAllReflections() async {
    final db = await database;
    final result = await db.query(
      'reflections',
      orderBy: 'created_at DESC',
    );
    return result.map((map) => Reflection.fromMap(map)).toList();
  }

  Future<Reflection?> getReflectionForDate(DateTime date) async {
    final db = await database;
    final dateStr =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    final result = await db.rawQuery('''
      SELECT * FROM reflections
      WHERE created_at LIKE ?
      ORDER BY created_at DESC
      LIMIT 1
    ''', ['$dateStr%']);
    if (result.isNotEmpty) return Reflection.fromMap(result.first);
    return null;
  }

  Future<int> deleteReflection(int id) async {
    final db = await database;
    return await db.delete('reflections', where: 'id = ?', whereArgs: [id]);
  }

  // ==========================================
  // OPERACIONES CRUD - MOODS
  // ==========================================

  Future<int> insertMood(MoodEntry mood) async {
    final db = await database;
    return await db.insert('moods', mood.toMap());
  }

  Future<MoodEntry?> getMoodForDate(DateTime date) async {
    final db = await database;
    final dateStr =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    final result = await db.rawQuery(
      'SELECT * FROM moods WHERE created_at LIKE ? ORDER BY created_at DESC LIMIT 1',
      ['$dateStr%'],
    );
    if (result.isNotEmpty) return MoodEntry.fromMap(result.first);
    return null;
  }

  Future<List<MoodEntry>> getRecentMoods(int days) async {
    final db = await database;
    final result = await db.query(
      'moods',
      orderBy: 'created_at DESC',
      limit: days,
    );
    return result.map((m) => MoodEntry.fromMap(m)).toList();
  }

  // ==========================================
  // OPERACIONES CRUD - HABITS
  // ==========================================

  Future<int> insertHabit(Habit habit) async {
    final db = await database;
    return await db.insert('habits', habit.toMap());
  }

  Future<List<Habit>> getAllHabits() async {
    final db = await database;
    final result = await db.query(
      'habits',
      where: 'active = ?',
      whereArgs: [1],
      orderBy: 'created_at DESC',
    );
    return result.map((m) => Habit.fromMap(m)).toList();
  }

  Future<int> updateHabit(Habit habit) async {
    final db = await database;
    return await db.update(
      'habits',
      habit.toMap(),
      where: 'id = ?',
      whereArgs: [habit.id],
    );
  }

  Future<int> deleteHabit(int id) async {
    final db = await database;
    return await db.delete('habits', where: 'id = ?', whereArgs: [id]);
  }

  // ==========================================
  // OPERACIONES CRUD - AFFIRMATIONS
  // ==========================================

  Future<int> insertAffirmation(Affirmation affirmation) async {
    final db = await database;
    return await db.insert('affirmations', affirmation.toMap());
  }

  Future<List<Affirmation>> getAllAffirmations() async {
    final db = await database;
    final result = await db.query('affirmations', orderBy: 'created_at DESC');
    return result.map((m) => Affirmation.fromMap(m)).toList();
  }

  Future<List<Affirmation>> getActiveAffirmations() async {
    final db = await database;
    final result = await db.query(
      'affirmations',
      where: 'active = ?',
      whereArgs: [1],
      orderBy: 'created_at DESC',
    );
    return result.map((m) => Affirmation.fromMap(m)).toList();
  }

  Future<int> updateAffirmation(Affirmation affirmation) async {
    final db = await database;
    return await db.update(
      'affirmations',
      affirmation.toMap(),
      where: 'id = ?',
      whereArgs: [affirmation.id],
    );
  }

  Future<int> deleteAffirmation(int id) async {
    final db = await database;
    return await db.delete('affirmations', where: 'id = ?', whereArgs: [id]);
  }

  /// Cargar frases iniciales si la BD está vacía
  Future<void> _loadInitialQuotes() async {
    final db = await database;

    // Verificar si ya hay frases
    final count = await db.rawQuery('SELECT COUNT(*) as count FROM quotes');
    final total = count.first['count'] as int;

    if (total > 0) {
      print('ℹ️ Ya hay $total frases en BD');
      return;
    }

    print('📝 Cargando frases iniciales...');

    // Lista de frases de emergencia
    final initialQuotes = [
      Quote(
        text:
            'El éxito es la suma de pequeños esfuerzos repetidos día tras día.',
        author: 'Robert Collier',
        category: 'Motivación',
        language: 'es',
        lastShown: null,
        viewCount: 0,
      ),
      Quote(
        text: 'No cuentes los días, haz que los días cuenten.',
        author: 'Muhammad Ali',
        category: 'Motivación',
        language: 'es',
        lastShown: null,
        viewCount: 0,
      ),
      Quote(
        text: 'El único modo de hacer un gran trabajo es amar lo que haces.',
        author: 'Steve Jobs',
        category: 'Productividad',
        language: 'es',
        lastShown: null,
        viewCount: 0,
      ),
      Quote(
        text: 'Cree que puedes y ya estarás a medio camino.',
        author: 'Theodore Roosevelt',
        category: 'Mentalidad',
        language: 'es',
        lastShown: null,
        viewCount: 0,
      ),
      Quote(
        text: 'La vida es 10% lo que te pasa y 90% cómo reaccionas a ello.',
        author: 'Charles R. Swindoll',
        category: 'Bienestar',
        language: 'es',
        lastShown: null,
        viewCount: 0,
      ),
    ];

    // Insertar frases
    for (final quote in initialQuotes) {
      try {
        await insertQuote(quote);
      } catch (e) {
        print('Error insertando frase inicial: $e');
      }
    }

    print('✅ ${initialQuotes.length} frases iniciales cargadas');
  }
}
