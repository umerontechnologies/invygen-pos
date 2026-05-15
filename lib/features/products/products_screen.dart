import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/services/repository.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/empty_state.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key, this.lowOnly = false});
  final bool lowOnly;
  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  final _repo = Repository();
  final _search = TextEditingController();
  List<Map<String, dynamic>> products = [];
  List<Map<String, dynamic>> suppliers = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    suppliers = await _repo.all('suppliers', orderBy: 'name ASC');
    products = await _repo.productsWithSuppliers(query: _search.text, lowOnly: widget.lowOnly);
    if (mounted) setState(() {});
  }

  Future<void> _contactSupplier(Map<String, dynamic> p, {required bool email}) async {
    final value = (email ? p['supplier_email'] : p['supplier_phone'])?.toString() ?? '';
    if (value.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No supplier contact found for this product.')));
      return;
    }
    final uri = email ? Uri(scheme: 'mailto', path: value) : Uri(scheme: 'tel', path: value);
    await launchUrl(uri);
  }

  Future<void> _openForm([Map<String, dynamic>? item]) async {
    final name = TextEditingController(text: item?['name']?.toString() ?? '');
    final sku = TextEditingController(text: item?['sku']?.toString() ?? '');
    final barcode = TextEditingController(text: item?['barcode']?.toString() ?? '');
    final category = TextEditingController(text: item?['category']?.toString() ?? '');
    final brand = TextEditingController(text: item?['brand']?.toString() ?? '');
    final unit = TextEditingController(text: item?['unit']?.toString() ?? 'pcs');
    final cost = TextEditingController(text: (item?['cost_price'] ?? '').toString());
    final price = TextEditingController(text: (item?['sale_price'] ?? '').toString());
    final stock = TextEditingController(text: (item?['stock'] ?? '0').toString());
    final minStock = TextEditingController(text: (item?['min_stock'] ?? '0').toString());
    final description = TextEditingController(text: item?['description']?.toString() ?? '');
    int? supplierId = item?['supplier_id'] as int?;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => StatefulBuilder(
        builder: (context, setSheet) => Padding(
          padding: EdgeInsets.only(left: 16, right: 16, top: 16, bottom: MediaQuery.of(context).viewInsets.bottom + 16),
          child: SingleChildScrollView(
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Text(item == null ? 'Add Product' : 'Edit Product', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              TextField(controller: name, decoration: const InputDecoration(labelText: 'Product name *')),
              const SizedBox(height: 10),
              Row(children: [
                Expanded(child: TextField(controller: sku, decoration: const InputDecoration(labelText: 'SKU'))),
                const SizedBox(width: 10),
                Expanded(child: TextField(controller: barcode, decoration: const InputDecoration(labelText: 'Barcode'))),
              ]),
              const SizedBox(height: 10),
              Row(children: [
                Expanded(child: TextField(controller: category, decoration: const InputDecoration(labelText: 'Category'))),
                const SizedBox(width: 10),
                Expanded(child: TextField(controller: brand, decoration: const InputDecoration(labelText: 'Brand'))),
              ]),
              const SizedBox(height: 10),
              DropdownButtonFormField<int?>(
                value: supplierId,
                items: [
                  const DropdownMenuItem<int?>(value: null, child: Text('No supplier')),
                  ...suppliers.map((s) => DropdownMenuItem<int?>(value: s['id'] as int, child: Text(s['name'].toString()))),
                ],
                onChanged: (value) => setSheet(() => supplierId = value),
                decoration: const InputDecoration(labelText: 'Main supplier'),
              ),
              const SizedBox(height: 10),
              Row(children: [
                Expanded(child: TextField(controller: unit, decoration: const InputDecoration(labelText: 'Unit'))),
                const SizedBox(width: 10),
                Expanded(child: TextField(controller: minStock, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Low stock alert'))),
              ]),
              const SizedBox(height: 10),
              Row(children: [
                Expanded(child: TextField(controller: cost, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Cost price'))),
                const SizedBox(width: 10),
                Expanded(child: TextField(controller: price, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Sale price'))),
              ]),
              const SizedBox(height: 10),
              TextField(controller: stock, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Opening/current stock')),
              const SizedBox(height: 10),
              TextField(controller: description, minLines: 2, maxLines: 3, decoration: const InputDecoration(labelText: 'Description')),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () async {
                  if (name.text.trim().isEmpty) return;
                  final data = {
                    'name': name.text.trim(),
                    'sku': sku.text.trim(),
                    'barcode': barcode.text.trim(),
                    'category': category.text.trim(),
                    'brand': brand.text.trim(),
                    'unit': unit.text.trim().isEmpty ? 'pcs' : unit.text.trim(),
                    'supplier_id': supplierId,
                    'cost_price': double.tryParse(cost.text) ?? 0,
                    'sale_price': double.tryParse(price.text) ?? 0,
                    'stock': double.tryParse(stock.text) ?? 0,
                    'min_stock': double.tryParse(minStock.text) ?? 0,
                    'description': description.text.trim(),
                    'updated_at': DateTime.now().toIso8601String(),
                  };
                  if (item == null) {
                    data['created_at'] = DateTime.now().toIso8601String();
                    await _repo.insert('products', data);
                  } else {
                    await _repo.update('products', data, item['id'] as int);
                  }
                  if (mounted) Navigator.pop(context);
                  await _load();
                },
                child: const Text('Save Product'),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.lowOnly ? 'Low / Out of Stock' : 'Products')),
      drawer: const AppDrawer(),
      floatingActionButton: FloatingActionButton(onPressed: () => _openForm(), child: const Icon(Icons.add)),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: TextField(
            controller: _search,
            decoration: const InputDecoration(prefixIcon: Icon(Icons.search), labelText: 'Search by name, SKU, barcode or category'),
            onChanged: (_) => _load(),
          ),
        ),
        Expanded(
          child: products.isEmpty
              ? const EmptyState(icon: Icons.inventory_2, title: 'No products found', message: 'Add products manually or restore/import data from backup.')
              : ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: products.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 4),
                  itemBuilder: (_, i) {
                    final p = products[i];
                    final stock = _repo.numToDouble(p['stock']);
                    final minStock = _repo.numToDouble(p['min_stock']);
                    final low = stock <= minStock;
                    final out = stock <= 0;
                    return Card(
                      child: ListTile(
                        title: Text(p['name'].toString(), style: const TextStyle(fontWeight: FontWeight.w700)),
                        subtitle: Text('${p['category'] ?? ''} | Stock: $stock | Price: ${p['sale_price']}\nSupplier: ${p['supplier_name'] ?? 'Not assigned'}'),
                        isThreeLine: true,
                        leading: CircleAvatar(backgroundColor: out ? Colors.red.shade50 : low ? Colors.orange.shade50 : Colors.blue.shade50, child: Icon(out ? Icons.error : low ? Icons.warning : Icons.inventory_2, color: out ? Colors.red : low ? Colors.orange : Colors.blue)),
                        trailing: PopupMenuButton<String>(
                          onSelected: (value) {
                            if (value == 'edit') _openForm(p);
                            if (value == 'call') _contactSupplier(p, email: false);
                            if (value == 'email') _contactSupplier(p, email: true);
                          },
                          itemBuilder: (_) => const [
                            PopupMenuItem(value: 'edit', child: Text('Edit')),
                            PopupMenuItem(value: 'call', child: Text('Call Supplier')),
                            PopupMenuItem(value: 'email', child: Text('Email Supplier')),
                          ],
                        ),
                        onTap: () => _openForm(p),
                      ),
                    );
                  },
                ),
        ),
      ]),
    );
  }
}
