import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class AppDatabase {
  AppDatabase._();
  static final AppDatabase instance = AppDatabase._();
  static Database? _database;

  static const int dbVersion = 5;

  Future<Database> get database async {
    if (_database != null) return _database!;
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'invygen_offline.db');
    _database = await openDatabase(path, version: dbVersion, onCreate: _onCreate, onUpgrade: _onUpgrade);
    return _database!;
  }

  Future<void> close() async {
    await _database?.close();
    _database = null;
  }

  Future<void> _safe(Database db, String sql) async {
    try {
      await db.execute(sql);
    } catch (_) {}
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute("""
      CREATE TABLE businesses(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        owner_name TEXT,
        phone TEXT,
        email TEXT,
        address TEXT,
        country TEXT,
        currency TEXT DEFAULT 'USD',
        tax_name TEXT,
        tax_number TEXT,
        invoice_prefix TEXT DEFAULT 'INV',
        receipt_footer TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT
      )
    """);

    await db.execute("""
      CREATE TABLE profiles(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT,
        email TEXT,
        phone TEXT,
        role TEXT DEFAULT 'Owner',
        pin TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT
      )
    """);

    await db.execute("""
      CREATE TABLE categories(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE
      )
    """);

    await db.execute("""
      CREATE TABLE suppliers(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        contact_person TEXT,
        phone TEXT,
        email TEXT,
        address TEXT,
        balance REAL NOT NULL DEFAULT 0,
        notes TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT
      )
    """);

    await db.execute("""
      CREATE TABLE products(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        sku TEXT,
        barcode TEXT,
        name TEXT NOT NULL,
        category TEXT,
        brand TEXT,
        unit TEXT DEFAULT 'pcs',
        supplier_id INTEGER,
        cost_price REAL NOT NULL DEFAULT 0,
        sale_price REAL NOT NULL DEFAULT 0,
        stock REAL NOT NULL DEFAULT 0,
        min_stock REAL NOT NULL DEFAULT 0,
        description TEXT,
        is_active INTEGER NOT NULL DEFAULT 1,
        created_at TEXT NOT NULL,
        updated_at TEXT
      )
    """);

    await db.execute("""
      CREATE TABLE customers(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        phone TEXT,
        email TEXT,
        address TEXT,
        customer_type TEXT NOT NULL DEFAULT 'customer',
        credit_limit REAL NOT NULL DEFAULT 0,
        balance REAL NOT NULL DEFAULT 0,
        notes TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT
      )
    """);

    await db.execute("""
      CREATE TABLE retailer_prices(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        customer_id INTEGER NOT NULL,
        product_id INTEGER NOT NULL,
        price REAL NOT NULL,
        UNIQUE(customer_id, product_id)
      )
    """);

    await db.execute("""
      CREATE TABLE purchases(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        purchase_no TEXT NOT NULL,
        supplier_id INTEGER,
        purchase_date TEXT NOT NULL,
        subtotal REAL NOT NULL DEFAULT 0,
        total REAL NOT NULL DEFAULT 0,
        paid REAL NOT NULL DEFAULT 0,
        pending REAL NOT NULL DEFAULT 0,
        notes TEXT,
        created_at TEXT NOT NULL
      )
    """);

    await db.execute("""
      CREATE TABLE purchase_items(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        purchase_id INTEGER NOT NULL,
        product_id INTEGER NOT NULL,
        product_name TEXT NOT NULL,
        quantity REAL NOT NULL,
        cost_price REAL NOT NULL,
        total REAL NOT NULL
      )
    """);

    await db.execute("""
      CREATE TABLE sales(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        invoice_no TEXT NOT NULL,
        customer_id INTEGER,
        customer_name TEXT,
        sale_date TEXT NOT NULL,
        subtotal REAL NOT NULL DEFAULT 0,
        discount REAL NOT NULL DEFAULT 0,
        tax REAL NOT NULL DEFAULT 0,
        total REAL NOT NULL DEFAULT 0,
        received REAL NOT NULL DEFAULT 0,
        pending REAL NOT NULL DEFAULT 0,
        payment_method TEXT DEFAULT 'Cash',
        status TEXT NOT NULL DEFAULT 'paid',
        created_at TEXT NOT NULL
      )
    """);

    await db.execute("""
      CREATE TABLE sale_items(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        sale_id INTEGER NOT NULL,
        product_id INTEGER NOT NULL,
        product_name TEXT NOT NULL,
        quantity REAL NOT NULL,
        price REAL NOT NULL,
        cost_price REAL NOT NULL DEFAULT 0,
        total REAL NOT NULL
      )
    """);

    await db.execute("""
      CREATE TABLE orders(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        order_no TEXT NOT NULL,
        customer_id INTEGER,
        customer_name TEXT,
        order_date TEXT NOT NULL,
        subtotal REAL NOT NULL DEFAULT 0,
        discount REAL NOT NULL DEFAULT 0,
        total REAL NOT NULL DEFAULT 0,
        received REAL NOT NULL DEFAULT 0,
        pending REAL NOT NULL DEFAULT 0,
        status TEXT NOT NULL DEFAULT 'pending',
        notes TEXT,
        stock_deducted INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL,
        delivered_at TEXT
      )
    """);

    await db.execute("""
      CREATE TABLE order_items(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        order_id INTEGER NOT NULL,
        product_id INTEGER NOT NULL,
        product_name TEXT NOT NULL,
        quantity REAL NOT NULL,
        price REAL NOT NULL,
        cost_price REAL NOT NULL DEFAULT 0,
        total REAL NOT NULL
      )
    """);

    await db.execute("""
      CREATE TABLE payments(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        customer_id INTEGER,
        sale_id INTEGER,
        order_id INTEGER,
        amount REAL NOT NULL,
        payment_method TEXT DEFAULT 'Cash',
        notes TEXT,
        payment_date TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    """);

    await db.execute("""
      CREATE TABLE expenses(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        amount REAL NOT NULL,
        expense_date TEXT NOT NULL,
        notes TEXT,
        created_at TEXT NOT NULL
      )
    """);

    await db.execute("""
      CREATE TABLE stock_movements(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        product_id INTEGER NOT NULL,
        type TEXT NOT NULL,
        quantity REAL NOT NULL,
        balance_after REAL,
        ref_type TEXT,
        ref_id INTEGER,
        notes TEXT,
        created_at TEXT NOT NULL
      )
    """);

    await db.execute("""
      CREATE TABLE app_settings(
        key TEXT PRIMARY KEY,
        value TEXT
      )
    """);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    await _safe(db, 'ALTER TABLE businesses ADD COLUMN phone TEXT');
    await _safe(db, 'ALTER TABLE businesses ADD COLUMN email TEXT');
    await _safe(db, 'ALTER TABLE businesses ADD COLUMN address TEXT');
    await _safe(db, 'ALTER TABLE businesses ADD COLUMN tax_name TEXT');
    await _safe(db, 'ALTER TABLE businesses ADD COLUMN tax_number TEXT');
    await _safe(db, "ALTER TABLE businesses ADD COLUMN invoice_prefix TEXT DEFAULT 'INV'");
    await _safe(db, 'ALTER TABLE businesses ADD COLUMN receipt_footer TEXT');
    await _safe(db, 'ALTER TABLE businesses ADD COLUMN updated_at TEXT');
    await _safe(db, 'ALTER TABLE suppliers ADD COLUMN contact_person TEXT');
    await _safe(db, 'ALTER TABLE suppliers ADD COLUMN notes TEXT');
    await _safe(db, 'ALTER TABLE suppliers ADD COLUMN updated_at TEXT');
    await _safe(db, 'ALTER TABLE products ADD COLUMN brand TEXT');
    await _safe(db, 'ALTER TABLE products ADD COLUMN supplier_id INTEGER');
    await _safe(db, 'ALTER TABLE products ADD COLUMN description TEXT');
    await _safe(db, 'ALTER TABLE products ADD COLUMN updated_at TEXT');
    await _safe(db, 'ALTER TABLE customers ADD COLUMN credit_limit REAL NOT NULL DEFAULT 0');
    await _safe(db, 'ALTER TABLE customers ADD COLUMN notes TEXT');
    await _safe(db, 'ALTER TABLE customers ADD COLUMN updated_at TEXT');
    await _safe(db, 'ALTER TABLE sales ADD COLUMN customer_name TEXT');
    await _safe(db, 'ALTER TABLE sales ADD COLUMN tax REAL NOT NULL DEFAULT 0');
    await _safe(db, "ALTER TABLE sales ADD COLUMN payment_method TEXT DEFAULT 'Cash'");
    await _safe(db, 'ALTER TABLE sale_items ADD COLUMN cost_price REAL NOT NULL DEFAULT 0');
    await _safe(db, 'ALTER TABLE orders ADD COLUMN customer_name TEXT');
    await _safe(db, 'ALTER TABLE orders ADD COLUMN subtotal REAL NOT NULL DEFAULT 0');
    await _safe(db, 'ALTER TABLE orders ADD COLUMN discount REAL NOT NULL DEFAULT 0');
    await _safe(db, 'ALTER TABLE orders ADD COLUMN received REAL NOT NULL DEFAULT 0');
    await _safe(db, 'ALTER TABLE orders ADD COLUMN pending REAL NOT NULL DEFAULT 0');
    await _safe(db, 'ALTER TABLE orders ADD COLUMN delivered_at TEXT');
    await _safe(db, 'ALTER TABLE order_items ADD COLUMN cost_price REAL NOT NULL DEFAULT 0');
    await _safe(db, 'ALTER TABLE stock_movements ADD COLUMN balance_after REAL');

    await _safe(db, """CREATE TABLE IF NOT EXISTS profiles(
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT,
      email TEXT,
      phone TEXT,
      role TEXT DEFAULT 'Owner',
      pin TEXT,
      created_at TEXT NOT NULL,
      updated_at TEXT
    )""");
    await _safe(db, """CREATE TABLE IF NOT EXISTS purchases(
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      purchase_no TEXT NOT NULL,
      supplier_id INTEGER,
      purchase_date TEXT NOT NULL,
      subtotal REAL NOT NULL DEFAULT 0,
      total REAL NOT NULL DEFAULT 0,
      paid REAL NOT NULL DEFAULT 0,
      pending REAL NOT NULL DEFAULT 0,
      notes TEXT,
      created_at TEXT NOT NULL
    )""");
    await _safe(db, """CREATE TABLE IF NOT EXISTS purchase_items(
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      purchase_id INTEGER NOT NULL,
      product_id INTEGER NOT NULL,
      product_name TEXT NOT NULL,
      quantity REAL NOT NULL,
      cost_price REAL NOT NULL,
      total REAL NOT NULL
    )""");
    await _safe(db, """CREATE TABLE IF NOT EXISTS payments(
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      customer_id INTEGER,
      sale_id INTEGER,
      order_id INTEGER,
      amount REAL NOT NULL,
      payment_method TEXT DEFAULT 'Cash',
      notes TEXT,
      payment_date TEXT NOT NULL,
      created_at TEXT NOT NULL
    )""");
    await _safe(db, """CREATE TABLE IF NOT EXISTS expenses(
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      title TEXT NOT NULL,
      amount REAL NOT NULL,
      expense_date TEXT NOT NULL,
      notes TEXT,
      created_at TEXT NOT NULL
    )""");
    await _safe(db, """CREATE TABLE IF NOT EXISTS app_settings(
      key TEXT PRIMARY KEY,
      value TEXT
    )""");
  }
}
