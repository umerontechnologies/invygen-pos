import 'package:flutter/material.dart';
import '../../core/services/repository.dart';

class RetailerPricesScreen extends StatefulWidget {
  const RetailerPricesScreen({super.key, required this.retailer});
  final Map<String, dynamic> retailer;

  @override
  State<RetailerPricesScreen> createState() => _RetailerPricesScreenState();
}

class _RetailerPricesScreenState extends State<RetailerPricesScreen> {
  final _repo = Repository();
  final _search = TextEditingController();
  List<Map<String, dynamic>> products = [];
  final prices = <int, double>{};

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    products = await _repo.productsWithSuppliers(query: _search.text);
    for (final p in products) {
      prices[p['id'] as int] = await _repo.retailerPrice(widget.retailer['id'] as int, p['id'] as int) ?? _repo.numToDouble(p['sale_price']);
    }
    if (mounted) setState(() {});
  }

  Future<void> _editPrice(Map<String, dynamic> product) async {
    final controller = TextEditingController(text: (prices[product['id']] ?? product['sale_price']).toString());
    await showDialog(context: context, builder: (_) => AlertDialog(
      title: Text('Retailer price - ${product['name']}'),
      content: TextField(controller: controller, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText:'Custom price')),
      actions: [
        TextButton(onPressed:()=>Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(onPressed:() async {
          await _repo.upsertRetailerPrice(widget.retailer['id'] as int, product['id'] as int, double.tryParse(controller.text) ?? 0);
          if (mounted) Navigator.pop(context);
          await _load();
        }, child: const Text('Save')),
      ],
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Prices: ${widget.retailer['name']}')),
      body: Column(children: [
        Padding(padding: const EdgeInsets.all(12), child: TextField(controller:_search, onChanged:(_)=>_load(), decoration: const InputDecoration(prefixIcon: Icon(Icons.search), labelText:'Search products'))),
        Expanded(child: ListView.separated(
          padding: const EdgeInsets.all(12), itemCount: products.length, separatorBuilder:(_,__)=>const Divider(height:1),
          itemBuilder: (_, i) { final p=products[i]; final id=p['id'] as int; return ListTile(
            title: Text(p['name'].toString()),
            subtitle: Text('Default: ${p['sale_price']} | Retailer: ${prices[id]?.toStringAsFixed(2)}'),
            trailing: const Icon(Icons.edit),
            onTap:()=>_editPrice(p),
          ); },
        )),
      ]),
    );
  }
}
