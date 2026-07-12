import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/customer.dart';
import '../models/bill.dart';
import '../models/user.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;
  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('water_billing_final.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    return await openDatabase(
      path,
      version: 5,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE customers (
        id INTEGER PRIMARY KEY,
        code TEXT NOT NULL UNIQUE,
        name TEXT NOT NULL,
        address TEXT NOT NULL,
        phone TEXT NOT NULL,
        currentReading INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE bills (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        customerId INTEGER NOT NULL,
        customerName TEXT,
        customerCode TEXT,
        billCode TEXT NOT NULL UNIQUE,
        date TEXT NOT NULL,
        oldReading INTEGER NOT NULL,
        newReading INTEGER NOT NULL,
        consumption REAL NOT NULL,
        unitPrice REAL NOT NULL,
        amount REAL NOT NULL,
        vat REAL NOT NULL,
        totalAmount REAL NOT NULL,
        imagePath TEXT,
        isSynced INTEGER NOT NULL DEFAULT 0,
        isPaid INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (customerId) REFERENCES customers (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE user_session (
        username TEXT PRIMARY KEY,
        fullName TEXT NOT NULL,
        role TEXT NOT NULL,
        email TEXT,
        phone TEXT,
        customerCode TEXT,
        token TEXT,
        lastLoginAt TEXT NOT NULL
      )
    ''');

    // await _seedDatabase(db);
  }

  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await _addColumnIfMissing(db, 'bills', 'customerName', 'TEXT');
      await _addColumnIfMissing(db, 'bills', 'customerCode', 'TEXT');
      await db.execute('''
        CREATE TABLE IF NOT EXISTS user_session (
          username TEXT PRIMARY KEY,
          fullName TEXT NOT NULL,
          role TEXT NOT NULL,
          email TEXT,
          phone TEXT,
          customerCode TEXT,
          token TEXT,
          lastLoginAt TEXT NOT NULL
        )
      ''');
    }
    if (oldVersion < 3) {
      await _addColumnIfMissing(db, 'user_session', 'customerCode', 'TEXT');
    }
    if (oldVersion < 4) {
      await _addColumnIfMissing(db, 'bills', 'isPaid', 'INTEGER NOT NULL DEFAULT 0');
    }
    if (oldVersion < 5) {
      await db.transaction((txn) async {
        final columns = await txn.rawQuery('PRAGMA table_info(customers)');
        final hasStatus = columns.any((c) => c['name'] == 'status');
        if (hasStatus) {
          await txn.execute('''
            CREATE TABLE customers_temp (
              id INTEGER PRIMARY KEY,
              code TEXT NOT NULL UNIQUE,
              name TEXT NOT NULL,
              address TEXT NOT NULL,
              phone TEXT NOT NULL,
              currentReading INTEGER NOT NULL
            )
          ''');
          await txn.execute('''
            INSERT INTO customers_temp (id, code, name, address, phone, currentReading)
            SELECT id, code, name, address, phone, currentReading FROM customers
          ''');
          await txn.execute('DROP TABLE customers');
          await txn.execute('ALTER TABLE customers_temp RENAME TO customers');
        }
      });
    }
  }

  Future<void> _addColumnIfMissing(Database db, String table, String column, String type) async {
    final columns = await db.rawQuery('PRAGMA table_info($table)');
    final exists = columns.any((c) => c['name'] == column);
    if (!exists) {
      await db.execute('ALTER TABLE $table ADD COLUMN $column $type');
    }
  }

  // Future<void> _seedDatabase(Database db) async {
  //   final customers = [
  //     Customer(id: 1, code: 'KH001', name: 'Lưu Bị', address: '12-A Phố Huế, Hai Bà Trưng, Hà Nội', phone: '0912345001', currentReading: 125),
  //     Customer(id: 2, code: 'KH002', name: 'Quan Vũ', address: '88 Đường Láng, Đống Đa, Hà Nội', phone: '0987654002', currentReading: 80),
  //     Customer(id: 3, code: 'KH003', name: 'Trương Phi', address: '15/2 Trần Duy Hưng, Cầu Giấy, Hà Nội', phone: '0904444003', currentReading: 210),
  //     Customer(id: 4, code: 'KH004', name: 'Gia Cát Lượng', address: 'Lạch Tray, Ngô Quyền, Hải Phòng', phone: '0911222004', currentReading: 45),
  //     Customer(id: 5, code: 'KH005', name: 'Tào Tháo', address: 'Trần Hưng Đạo, TP. Bắc Ninh', phone: '0933555005', currentReading: 320),
  //   ];
  //   for (final customer in customers) {
  //     await db.insert('customers', customer.toMap(), conflictAlgorithm: ConflictAlgorithm.ignore);
  //   }
  // }

  Future<List<Customer>> getAllCustomers() async {
    final db = await database;
    final res = await db.query('customers', orderBy: 'code ASC');
    return res.map(Customer.fromMap).toList();
  }

  /// Upsert danh sách KH từ server.
  /// Giữ lại chỉ số nước lớn nhất giữa local và server để tránh mất dữ liệu ghi mới.
  Future<void> upsertCustomers(List<Customer> customers) async {
    final db = await database;
    for (var c in customers) {
      final existing = await db.query('customers', where: 'id = ?', whereArgs: [c.id]);
      if (existing.isNotEmpty) {
        final localReading = existing.first['currentReading'] as int;
        // Giữ lại chỉ số nước lớn nhất
        final finalReading = localReading > c.currentReading ? localReading : c.currentReading;
        await db.update(
          'customers',
          {...c.toMap(), 'currentReading': finalReading},
          where: 'id = ?',
          whereArgs: [c.id],
        );
      } else {
        await db.insert('customers', c.toMap(), conflictAlgorithm: ConflictAlgorithm.ignore);
      }
    }
  }

  Future<void> updateCustomerReading(int id, int newReading) async {
    final db = await database;
    final rows = await db.update('customers', {'currentReading': newReading}, where: 'id = ?', whereArgs: [id]);
    debugPrint('SQLite updateCustomerReading: customerId=$id, newReading=$newReading, rowsAffected=$rows');
  }

  Future<void> insertBill(Bill bill) async {
    final db = await database;
    // Kiểm tra xem hóa đơn với billCode này đã có ở local chưa
    final existing = await db.query(
      'bills',
      where: 'billCode = ?',
      whereArgs: [bill.billCode],
      limit: 1,
    );
    if (existing.isNotEmpty) {
      final localBill = Bill.fromMap(existing.first);
      // Nếu hóa đơn local chưa đồng bộ (isSynced == false),
      // thì KHÔNG ghi đè bằng dữ liệu từ server, vì bản local có
      // thay đổi offline chưa được đẩy lên (vd: đã đánh dấu thanh toán).
      if (!localBill.isSynced) {
        debugPrint('insertBill: bỏ qua ghi đè bill chưa sync: ${bill.billCode}');
        return;
      }
    }
    await db.insert('bills', bill.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Bill>> getUnsyncedBills() async {
    final db = await database;
    final res = await db.query('bills', where: 'isSynced = ?', whereArgs: [0]);
    return res.map(Bill.fromMap).toList();
  }

  Future<List<Bill>> getAllBills() async {
    final db = await database;
    final res = await db.query('bills', orderBy: 'date DESC');
    return res.map(Bill.fromMap).toList();
  }

  Future<void> markBillsAsSynced(List<Bill> bills) async {
    final db = await database;
    for (var b in bills) {
      await db.update('bills', {'isSynced': 1}, where: 'billCode = ?', whereArgs: [b.billCode]);
    }
  }

  Future<List<Bill>> getBillsByCustomer(int customerId) async {
    final db = await database;
    final res = await db.query('bills', where: 'customerId = ?', whereArgs: [customerId], orderBy: 'date DESC');
    return res.map(Bill.fromMap).toList();
  }

  Future<void> markBillAsPaid(int billId) async {
    final db = await database;
    // Set isPaid = 1 và đồng thời reset isSynced = 0 để gửi bản cập nhật thanh toán này lên SQL Server
    await db.update('bills', {'isPaid': 1, 'isSynced': 0}, where: 'id = ?', whereArgs: [billId]);
  }

  Future<void> markAllBillsAsPaidForCustomer(int customerId) async {
    final db = await database;
    // Cập nhật toàn bộ các hóa đơn chưa thanh toán của KH này thành đã thanh toán và đánh dấu chưa sync
    await db.update(
      'bills',
      {'isPaid': 1, 'isSynced': 0},
      where: 'customerId = ? AND isPaid = ?',
      whereArgs: [customerId, 0],
    );
  }

  Future<Customer?> getCustomerById(int id) async {
    final db = await database;
    final res = await db.query('customers', where: 'id = ?', whereArgs: [id]);
    if (res.isEmpty) return null;
    return Customer.fromMap(res.first);
  }

  Future<void> updateCustomer(Customer customer) async {
    final db = await database;
    await db.update('customers', customer.toMap(), where: 'id = ?', whereArgs: [customer.id]);
  }

  Future<void> saveSession(User user, String? token) async {
    final db = await database;
    await db.insert(
      'user_session',
      {
        ...user.toMap(),
        'token': token,
        'lastLoginAt': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<User?> getLastSession() async {
    final db = await database;
    final res = await db.query('user_session', orderBy: 'lastLoginAt DESC', limit: 1);
    if (res.isEmpty) return null;
    return User.fromMap(res.first);
  }

  Future<void> clearSession() async {
    final db = await database;
    await db.delete('user_session');
  }
}
