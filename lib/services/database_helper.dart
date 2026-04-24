import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:water_tracker_mobile/models/trip.dart';
import 'package:water_tracker_mobile/models/inventory_item.dart';
import 'package:water_tracker_mobile/models/user.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() => _instance;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    await _ensureAdminPassword(_database!);
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'water_tracker_v6.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE trips ADD COLUMN passengersCount INTEGER DEFAULT 0');
      await db.execute('ALTER TABLE trips ADD COLUMN bottlesDistributed INTEGER DEFAULT 0');
      await db.execute('ALTER TABLE users ADD COLUMN password TEXT DEFAULT "123456"');
    }
    if (oldVersion < 3) {
      await db.execute('ALTER TABLE inventory ADD COLUMN receiptNumber TEXT');
      await db.execute('ALTER TABLE inventory ADD COLUMN receiptDateTime TEXT');
    }
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE trips(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        fromCity TEXT,
        toCity TEXT,
        time TEXT,
        tripDate TEXT,
        busId TEXT,
        status TEXT,
        passengersCount INTEGER,
        bottlesDistributed INTEGER
      )
    ''');

    await db.execute('''
      CREATE TABLE inventory(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT,
        location TEXT,
        quantity INTEGER,
        unit TEXT,
        receiptNumber TEXT,
        receiptDateTime TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE users(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT,
        role TEXT,
        email TEXT,
        password TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE cities(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT
      )
    ''');
    
    await _seedData(db);
  }

  Future<void> _seedData(Database db) async {
    // Seed Cities if empty
    final cityCount = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM cities'));
    if (cityCount == 0) {
      List<String> moroccanCities = [
        'الدار البيضاء', 'الرباط', 'مراكش', 'فاس', 'طنجة', 'أكادير', 
        'مكناس', 'وجدة', 'القنيطرة', 'تطوان', 'آسفي', 'تمارة', 
        'سلا', 'بني ملال', 'الجديدة', 'الناظور', 'سطات', 'العرائش', 
        'قصبة تادلة', 'برشيد', 'خريبكة', 'الداخلة', 'العيون'
      ];
      for (var name in moroccanCities) {
        await db.insert('cities', {'name': name});
      }
    }

    // Seed Users if empty or admin missing
    final usersCount = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM users')) ?? 0;
    final adminExists = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM users WHERE email = "admin@water.com"')) ?? 0;
    
    if (usersCount == 0 || adminExists == 0) {
      if (adminExists == 0) {
        await db.insert('users', User(name: 'المدير العام', role: 'مدير', email: 'admin@water.com', password: '123456').toMap());
      } else {
        // Force update password for existing admin as per user request
        await db.update('users', {'password': '123456'}, where: 'email = ?', whereArgs: ['admin@water.com']);
      }
      if (usersCount == 0) {
        await db.insert('users', User(name: 'سارة خالد', role: 'محاسب', email: 'sara@water.com', password: 'sara').toMap());
        await db.insert('users', User(name: 'ياسين علي', role: 'سائق', email: 'yassin@water.com', password: 'yassin').toMap());
      }
    }

    // Seed Trips if empty
    final tripCount = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM trips'));
    if (tripCount == 0) {
      await db.insert('trips', {
        'fromCity': 'الدار البيضاء',
        'toCity': 'الرباط',
        'time': '08:00 ص',
        'tripDate': '2026-04-24',
        'busId': 'TR-500',
        'status': 'مكتمل'
      });
    }

    // Seed Inventory if empty
    final invCount = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM inventory'));
    if (invCount == 0) {
      await db.insert('inventory', {'name': 'مياه معدنية 5L', 'location': 'المستودع الرئيسي', 'quantity': 1000, 'unit': 'وحدة'});
    }
  }

  Future<void> _ensureAdminPassword(Database db) async {
    final List<Map<String, dynamic>> users = await db.query(
      'users',
      where: 'email = ?',
      whereArgs: ['admin@water.com'],
    );

    if (users.isEmpty) {
      await db.insert('users', User(
        name: 'المدير العام',
        role: 'مدير',
        email: 'admin@water.com',
        password: '123456',
      ).toMap());
    } else {
      await db.update(
        'users',
        {'password': '123456'},
        where: 'email = ?',
        whereArgs: ['admin@water.com'],
      );
    }
  }

  // Inventory deduction logic
  Future<void> deductInventory(int quantity) async {
    Database db = await database;
    // For now, deduct from the first item in inventory (the seeded water item)
    final List<Map<String, dynamic>> items = await db.query('inventory', limit: 1);
    if (items.isNotEmpty) {
      int currentQty = items.first['quantity'] as int;
      int newQty = currentQty - quantity;
      await db.update(
        'inventory',
        {'quantity': newQty},
        where: 'id = ?',
        whereArgs: [items.first['id']],
      );
    }
  }

  Future<void> adjustInventory(int oldQuantity, int newQuantity) async {
    int difference = newQuantity - oldQuantity;
    if (difference != 0) {
      await deductInventory(difference);
    }
  }

  // CRUD for Trips
  Future<int> insertTrip(Trip trip) async {
    Database db = await database;
    return await db.insert('trips', trip.toMap());
  }

  Future<int> updateTrip(Trip trip) async {
    Database db = await database;
    return await db.update('trips', trip.toMap(), where: 'id = ?', whereArgs: [trip.id]);
  }

  Future<int> deleteTrip(int id) async {
    Database db = await database;
    // Get the trip to know how many bottles to restore
    List<Map<String, dynamic>> trips = await db.query('trips', where: 'id = ?', whereArgs: [id]);
    if (trips.isNotEmpty) {
      int bottles = trips.first['bottlesDistributed'] as int;
      if (bottles > 0) {
        await adjustInventory(bottles, 0); // Restore bottles (newQty is 0, so deducts -bottles)
      }
    }
    return await db.delete('trips', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Trip>> getTrips() async {
    Database db = await database;
    List<Map<String, dynamic>> maps = await db.query('trips');
    return List.generate(maps.length, (i) => Trip.fromMap(maps[i]));
  }

  // CRUD for Inventory
  Future<int> insertInventory(InventoryItem item) async {
    Database db = await database;
    return await db.insert('inventory', item.toMap());
  }

  Future<int> updateInventory(InventoryItem item) async {
    Database db = await database;
    return await db.update('inventory', item.toMap(), where: 'id = ?', whereArgs: [item.id]);
  }

  Future<int> deleteInventory(int id) async {
    Database db = await database;
    return await db.delete('inventory', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> zeroInventory(int id) async {
    Database db = await database;
    return await db.update('inventory', {'quantity': 0}, where: 'id = ?', whereArgs: [id]);
  }

  Future<List<InventoryItem>> getInventory() async {
    Database db = await database;
    List<Map<String, dynamic>> maps = await db.query('inventory');
    if (maps.isEmpty) {
      await _seedData(db);
      maps = await db.query('inventory');
    }
    return List.generate(maps.length, (i) => InventoryItem.fromMap(maps[i]));
  }

  // CRUD for Users
  Future<int> insertUser(User user) async {
    Database db = await database;
    return await db.insert('users', user.toMap());
  }

  Future<int> updateUser(User user) async {
    Database db = await database;
    return await db.update('users', user.toMap(), where: 'id = ?', whereArgs: [user.id]);
  }

  Future<int> deleteUser(int id) async {
    Database db = await database;
    return await db.delete('users', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<User>> getUsers() async {
    Database db = await database;
    List<Map<String, dynamic>> maps = await db.query('users');
    if (maps.isEmpty) {
      await _seedData(db);
      maps = await db.query('users');
    }
    return List.generate(maps.length, (i) => User.fromMap(maps[i]));
  }

  // CRUD for Cities
  Future<int> insertCity(String name) async {
    Database db = await database;
    return await db.insert('cities', {'name': name});
  }

  Future<List<String>> getCities() async {
    Database db = await database;
    List<Map<String, dynamic>> maps = await db.query('cities');
    if (maps.isEmpty) {
      await _seedData(db);
      maps = await db.query('cities');
    }
    return List.generate(maps.length, (i) => maps[i]['name'] as String);
  }

  Future<Map<String, dynamic>> getReportStats() async {
    Database db = await database;
    final totalDistributed = Sqflite.firstIntValue(await db.rawQuery('SELECT SUM(bottlesDistributed) FROM trips')) ?? 0;
    final totalTrips = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM trips')) ?? 0;
    final totalInventory = Sqflite.firstIntValue(await db.rawQuery('SELECT SUM(quantity) FROM inventory')) ?? 0;
    final totalPassengers = Sqflite.firstIntValue(await db.rawQuery('SELECT SUM(passengersCount) FROM trips')) ?? 0;
    
    return {
      'totalDistributed': totalDistributed,
      'totalTrips': totalTrips,
      'totalInventory': totalInventory,
      'totalPassengers': totalPassengers,
    };
  }

  Future<Map<String, dynamic>> getDashboardStats() async {
    Database db = await database;
    final now = DateTime.now();
    final today = DateFormat('yyyy-MM-dd').format(now);
    
    final todayTrips = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM trips WHERE tripDate = ?', [today])) ?? 0;
    final todayBottles = Sqflite.firstIntValue(await db.rawQuery('SELECT SUM(bottlesDistributed) FROM trips WHERE tripDate = ?', [today])) ?? 0;
    final totalInventory = Sqflite.firstIntValue(await db.rawQuery('SELECT SUM(quantity) FROM inventory')) ?? 0;
    
    return {
      'todayTrips': todayTrips,
      'todayBottles': todayBottles,
      'totalInventory': totalInventory,
    };
  }

  Future<List<Map<String, dynamic>>> getDailyStatsForMonth(String monthYear) async {
    Database db = await database;
    return await db.rawQuery('''
      SELECT 
        tripDate as date,
        COUNT(*) as tripCount,
        SUM(passengersCount) as totalPassengers,
        SUM(bottlesDistributed) as totalBottles
      FROM trips
      WHERE tripDate LIKE ?
      GROUP BY tripDate
      ORDER BY tripDate DESC
    ''', ['$monthYear%']);
  }

  Future<void> deleteAllInventory() async {
    Database db = await database;
    await db.delete('inventory');
  }

  // --- Cloud Sync (Supabase) ---

  Future<Map<String, dynamic>> syncToCloud() async {
    try {
      final supabase = Supabase.instance.client;

      // 1. Sync Trips
      List<Trip> localTrips = await getTrips();
      for (var trip in localTrips) {
        await supabase.from('trips').upsert(trip.toMap());
      }

      // 2. Sync Inventory
      List<InventoryItem> localInventory = await getInventory();
      for (var item in localInventory) {
        await supabase.from('inventory').upsert(item.toMap());
      }

      // 3. Sync Users
      List<User> localUsers = await getUsers();
      for (var user in localUsers) {
        await supabase.from('users').upsert(user.toMap());
      }

      return {'success': true, 'message': 'تم النسخ الاحتياطي للسحاب بنجاح'};
    } catch (e) {
      return {'success': false, 'message': 'فشل النسخ الاحتياطي: ${e.toString()}'};
    }
  }
}
