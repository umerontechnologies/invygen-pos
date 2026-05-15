import 'package:intl/intl.dart';
import 'package:sqflite/sqflite.dart';
import '../database/app_database.dart';

class Repository {
  Future<Database> get _db async => AppDatabase.instance.database;

  String now() => DateTime.now().toIso8601String();

  double numToDouble(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value.toDouble();
    if (value is double) return value;
    return double.tryParse(value.toString()) ?? 0;
  }

  Future<int> insert(String table, Map<String, dynamic> data) async => (await _db).insert(table, data);

  Future<int> update(String table, Map<String, dynamic> data, int id) async =>
      (await _db).update(table, data, where: 'id = ?', whereArgs: [id]);

  Future<int> delete(String table, int id) async => (await _db).delete(table, where: 'id = ?', whereArgs: [id]);

  Future<List<Map<String, dynamic>>> all(String table, {String orderBy = 'id DESC'}) async =>
      (await _db).query(table, orderBy: orderBy);

  Future<Map<String, dynamic>?> find(String table, int id) async {
    final rows = await (await _db).query(table, where: 'id = ?', whereArgs: [id], limit: 1);
    return rows.isEmpty ? null : rows.first;
  }

  Future<int> count(String table, {String? where, List<Object?>? whereArgs}) async {
    final result = await (await _db).rawQuery(
      'SELECT COUNT(*) AS c FROM $table${where == null ? '' : ' WHERE $where'}',
      whereArgs,
    );
    return (result.first['c'] as int?) ?? 0;
  }

  Future<double> sum(String table, String column, {String? where, List<Object?>? whereArgs}) async {
    final result = await (await _db).rawQuery(
      'SELECT COALESCE(SUM($column), 0) AS s FROM $table${where == null ? '' : ' WHERE $where'}',
      whereArgs,
    );
    return numToDouble(result.first['s']);
  }

  Future<Map<String, dynamic>?> business() async {
    final rows = await (await _db).query('businesses', orderBy: 'id ASC', limit: 1);
    return rows.isEmpty ? null : rows.first;
  }

  Future<int> saveBusiness(Map<String, dynamic> data) async {
    final existing = await business();
    data['updated_at'] = now();
    if (existing == null) {
      data['created_at'] = now();
      return insert('businesses', data);
    }
    return update('businesses', data, existing['id'] as int);
  }

  Future<Map<String, dynamic>?> profile() async {
    final rows = await (await _db).query('profiles', orderBy: 'id ASC', limit: 1);
    return rows.isEmpty ? null : rows.first;
  }

  Future<int> saveProfile(Map<String, dynamic> data) async {
    final existing = await profile();
    data['updated_at'] = now();
    if (existing == null) {
      data['created_at'] = now();
      return insert('profiles', data);
    }
    return update('profiles', data, existing['id'] as int);
  }

  Future<void> setSetting(String key, String value) async {
    await (await _db).insert('app_settings', {'key': key, 'value': value}, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<String?> setting(String key) async {
    final rows = await (await _db).query('app_settings', where: 'key = ?', whereArgs: [key], limit: 1);
    return rows.isEmpty ? null : rows.first['value']?.toString();
  }

  Future<List<Map<String, dynamic>>> productsWithSuppliers({String query = '', bool lowOnly = false}) async {
    final db = await _db;
    final where = <String>[];
    final args = <Object?>[];
    where.add('p.is_active = 1');
    if (query.trim().isNotEmpty) {
      where.add('(p.name LIKE ? OR p.sku LIKE ? OR p.barcode LIKE ? OR p.category LIKE ?)');
      final q = '%${query.trim()}%';
      args.addAll([q, q, q, q]);
    }
    if (lowOnly) where.add('p.stock <= p.min_stock');
    return db.rawQuery('''
      SELECT p.*, s.name AS supplier_name, s.phone AS supplier_phone, s.email AS supplier_email
      FROM products p
      LEFT JOIN suppliers s ON s.id = p.supplier_id
      WHERE ${where.join(' AND ')}
      ORDER BY p.name ASC
    ''', args);
  }

  Future<List<Map<String, dynamic>>> customersByType(String type) async {
    return (await _db).query('customers', where: 'customer_type = ?', whereArgs: [type], orderBy: 'name ASC');
  }

  Future<List<Map<String, dynamic>>> supplierProducts(int supplierId) async {
    return (await _db).query('products', where: 'supplier_id = ?', whereArgs: [supplierId], orderBy: 'name ASC');
  }

  Future<double?> retailerPrice(int customerId, int productId) async {
    final rows = await (await _db).query(
      'retailer_prices',
      where: 'customer_id = ? AND product_id = ?',
      whereArgs: [customerId, productId],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return numToDouble(rows.first['price']);
  }

  Future<void> upsertRetailerPrice(int customerId, int productId, double price) async {
    await (await _db).insert(
      'retailer_prices',
      {'customer_id': customerId, 'product_id': productId, 'price': price},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> addStock(int productId, double quantity, String refType, int refId, {String? notes}) async {
    final db = await _db;
    await db.transaction((txn) async {
      await txn.rawUpdate('UPDATE products SET stock = stock + ?, updated_at = ? WHERE id = ?', [quantity, now(), productId]);
      final product = (await txn.query('products', where: 'id = ?', whereArgs: [productId], limit: 1)).first;
      await txn.insert('stock_movements', {
        'product_id': productId,
        'type': 'in',
        'quantity': quantity,
        'balance_after': numToDouble(product['stock']),
        'ref_type': refType,
        'ref_id': refId,
        'notes': notes ?? 'Stock added for $refType #$refId',
        'created_at': now(),
      });
    });
  }

  Future<void> reduceStock(int productId, double quantity, String refType, int refId, {String? notes}) async {
    final db = await _db;
    await db.transaction((txn) async {
      await txn.rawUpdate('UPDATE products SET stock = stock - ?, updated_at = ? WHERE id = ?', [quantity, now(), productId]);
      final product = (await txn.query('products', where: 'id = ?', whereArgs: [productId], limit: 1)).first;
      await txn.insert('stock_movements', {
        'product_id': productId,
        'type': 'out',
        'quantity': quantity,
        'balance_after': numToDouble(product['stock']),
        'ref_type': refType,
        'ref_id': refId,
        'notes': notes ?? 'Stock deducted for $refType #$refId',
        'created_at': now(),
      });
    });
  }

  Future<int> createPurchase({required int? supplierId, required List<Map<String, dynamic>> items, required double paid, String notes = ''}) async {
    final db = await _db;
    final created = now();
    final purchaseNo = 'PUR-${DateFormat('yyyyMMddHHmmss').format(DateTime.now())}';
    final total = items.fold<double>(0, (sum, item) => sum + numToDouble(item['total']));
    final pending = total - paid;
    return db.transaction((txn) async {
      final id = await txn.insert('purchases', {
        'purchase_no': purchaseNo,
        'supplier_id': supplierId,
        'purchase_date': created,
        'subtotal': total,
        'total': total,
        'paid': paid,
        'pending': pending > 0 ? pending : 0,
        'notes': notes,
        'created_at': created,
      });
      for (final item in items) {
        final productId = item['product_id'] as int;
        final qty = numToDouble(item['quantity']);
        final cost = numToDouble(item['cost_price']);
        await txn.insert('purchase_items', {...item, 'purchase_id': id});
        await txn.rawUpdate('UPDATE products SET stock = stock + ?, cost_price = ?, supplier_id = COALESCE(?, supplier_id), updated_at = ? WHERE id = ?', [qty, cost, supplierId, created, productId]);
        final product = (await txn.query('products', where: 'id = ?', whereArgs: [productId], limit: 1)).first;
        await txn.insert('stock_movements', {
          'product_id': productId,
          'type': 'in',
          'quantity': qty,
          'balance_after': numToDouble(product['stock']),
          'ref_type': 'purchase',
          'ref_id': id,
          'notes': 'Purchase $purchaseNo',
          'created_at': created,
        });
      }
      if (supplierId != null && pending > 0) {
        await txn.rawUpdate('UPDATE suppliers SET balance = balance + ? WHERE id = ?', [pending, supplierId]);
      }
      return id;
    });
  }

  Future<int> completeSale({
    required int? customerId,
    required String customerName,
    required List<Map<String, dynamic>> items,
    required double discount,
    required double received,
    required String paymentMethod,
  }) async {
    final db = await _db;
    final created = now();
    final business = await this.business();
    final prefix = (business?['invoice_prefix']?.toString().isNotEmpty ?? false) ? business!['invoice_prefix'].toString() : 'INV';
    final invoiceNo = '$prefix-${DateFormat('yyyyMMddHHmmss').format(DateTime.now())}';
    final subtotal = items.fold<double>(0, (sum, item) => sum + numToDouble(item['total']));
    final total = (subtotal - discount).clamp(0, double.infinity).toDouble();
    final pending = total - received;

    return db.transaction((txn) async {
      for (final item in items) {
        final productId = item['product_id'] as int;
        final qty = numToDouble(item['quantity']);
        final productRows = await txn.query('products', where: 'id = ?', whereArgs: [productId], limit: 1);
        if (productRows.isEmpty) throw Exception('Product not found');
        final stock = numToDouble(productRows.first['stock']);
        if (stock < qty) throw Exception('Insufficient stock for ${item['product_name']}');
      }

      final saleId = await txn.insert('sales', {
        'invoice_no': invoiceNo,
        'customer_id': customerId,
        'customer_name': customerName,
        'sale_date': created,
        'subtotal': subtotal,
        'discount': discount,
        'tax': 0,
        'total': total,
        'received': received,
        'pending': pending > 0 ? pending : 0,
        'payment_method': paymentMethod,
        'status': pending > 0 ? (received > 0 ? 'partial' : 'unpaid') : 'paid',
        'created_at': created,
      });

      for (final item in items) {
        final productId = item['product_id'] as int;
        final qty = numToDouble(item['quantity']);
        await txn.insert('sale_items', {...item, 'sale_id': saleId});
        await txn.rawUpdate('UPDATE products SET stock = stock - ?, updated_at = ? WHERE id = ?', [qty, created, productId]);
        final product = (await txn.query('products', where: 'id = ?', whereArgs: [productId], limit: 1)).first;
        await txn.insert('stock_movements', {
          'product_id': productId,
          'type': 'out',
          'quantity': qty,
          'balance_after': numToDouble(product['stock']),
          'ref_type': 'sale',
          'ref_id': saleId,
          'notes': 'Sale $invoiceNo',
          'created_at': created,
        });
      }

      if (customerId != null && pending > 0) {
        await txn.rawUpdate('UPDATE customers SET balance = balance + ? WHERE id = ?', [pending, customerId]);
      }
      if (customerId != null && received > 0) {
        await txn.insert('payments', {
          'customer_id': customerId,
          'sale_id': saleId,
          'amount': received,
          'payment_method': paymentMethod,
          'notes': 'Payment received on invoice $invoiceNo',
          'payment_date': created,
          'created_at': created,
        });
      }
      return saleId;
    });
  }

  Future<int> createOrder({
    required int? customerId,
    required String customerName,
    required List<Map<String, dynamic>> items,
    required double discount,
    String notes = '',
  }) async {
    final db = await _db;
    final created = now();
    final orderNo = 'ORD-${DateFormat('yyyyMMddHHmmss').format(DateTime.now())}';
    final subtotal = items.fold<double>(0, (sum, item) => sum + numToDouble(item['total']));
    final total = (subtotal - discount).clamp(0, double.infinity).toDouble();
    return db.transaction((txn) async {
      final id = await txn.insert('orders', {
        'order_no': orderNo,
        'customer_id': customerId,
        'customer_name': customerName,
        'order_date': created,
        'subtotal': subtotal,
        'discount': discount,
        'total': total,
        'received': 0,
        'pending': total,
        'status': 'pending',
        'notes': notes,
        'stock_deducted': 0,
        'created_at': created,
      });
      for (final item in items) {
        await txn.insert('order_items', {...item, 'order_id': id});
      }
      return id;
    });
  }

  Future<void> markOrderDelivered(int orderId) async {
    final db = await _db;
    final delivered = now();
    await db.transaction((txn) async {
      final orderRows = await txn.query('orders', where: 'id = ?', whereArgs: [orderId], limit: 1);
      if (orderRows.isEmpty) return;
      final order = orderRows.first;
      if (order['status'] == 'delivered' && order['stock_deducted'] == 1) return;
      final items = await txn.query('order_items', where: 'order_id = ?', whereArgs: [orderId]);
      for (final item in items) {
        final productId = item['product_id'] as int;
        final qty = numToDouble(item['quantity']);
        final productRows = await txn.query('products', where: 'id = ?', whereArgs: [productId], limit: 1);
        if (productRows.isEmpty) throw Exception('Product not found');
        final stock = numToDouble(productRows.first['stock']);
        if (stock < qty) throw Exception('Insufficient stock for ${item['product_name']}');
      }
      for (final item in items) {
        final productId = item['product_id'] as int;
        final qty = numToDouble(item['quantity']);
        await txn.rawUpdate('UPDATE products SET stock = stock - ?, updated_at = ? WHERE id = ?', [qty, delivered, productId]);
        final product = (await txn.query('products', where: 'id = ?', whereArgs: [productId], limit: 1)).first;
        await txn.insert('stock_movements', {
          'product_id': productId,
          'type': 'out',
          'quantity': qty,
          'balance_after': numToDouble(product['stock']),
          'ref_type': 'order',
          'ref_id': orderId,
          'notes': 'Delivered order ${order['order_no']}',
          'created_at': delivered,
        });
      }
      await txn.update('orders', {'status': 'delivered', 'stock_deducted': 1, 'delivered_at': delivered}, where: 'id = ?', whereArgs: [orderId]);
    });
  }

  Future<void> cancelOrder(int orderId) async {
    await (await _db).update('orders', {'status': 'cancelled'}, where: 'id = ?', whereArgs: [orderId]);
  }

  Future<void> recordCustomerPayment(int customerId, double amount, {String paymentMethod = 'Cash', String notes = ''}) async {
    final db = await _db;
    final created = now();
    await db.transaction((txn) async {
      await txn.insert('payments', {
        'customer_id': customerId,
        'amount': amount,
        'payment_method': paymentMethod,
        'notes': notes,
        'payment_date': created,
        'created_at': created,
      });
      await txn.rawUpdate('UPDATE customers SET balance = MAX(balance - ?, 0), updated_at = ? WHERE id = ?', [amount, created, customerId]);
    });
  }

  Future<List<Map<String, dynamic>>> saleItems(int saleId) async {
    return (await _db).query('sale_items', where: 'sale_id = ?', whereArgs: [saleId]);
  }

  Future<List<Map<String, dynamic>>> orderItems(int orderId) async {
    return (await _db).query('order_items', where: 'order_id = ?', whereArgs: [orderId]);
  }

  Future<Map<String, dynamic>> dashboardSummary() async {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final business = await this.business();
    return {
      'currency': business?['currency'] ?? 'USD',
      'products': await count('products', where: 'is_active = 1'),
      'customers': await count('customers', where: "customer_type = 'customer'"),
      'retailers': await count('customers', where: "customer_type = 'retailer'"),
      'suppliers': await count('suppliers'),
      'lowStock': await count('products', where: 'stock <= min_stock AND is_active = 1'),
      'pendingOrders': await count('orders', where: "status = 'pending'"),
      'todaySales': await sum('sales', 'total', where: "sale_date LIKE ?", whereArgs: ['$today%']),
      'totalDues': await sum('customers', 'balance'),
      'inventoryValue': await (await _db).rawQuery('SELECT COALESCE(SUM(stock * cost_price), 0) AS v FROM products').then((r) => numToDouble(r.first['v'])),
    };
  }

  Future<List<Map<String, dynamic>>> lowStockProducts() async => productsWithSuppliers(lowOnly: true);

  Future<List<Map<String, dynamic>>> topSellingProducts() async {
    return (await _db).rawQuery('''
      SELECT product_name, SUM(quantity) AS qty, SUM(total) AS total
      FROM sale_items
      GROUP BY product_id, product_name
      ORDER BY qty DESC
      LIMIT 10
    ''');
  }
}
