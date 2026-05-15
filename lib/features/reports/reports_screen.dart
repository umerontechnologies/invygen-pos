import 'package:flutter/material.dart';
import '../../core/services/repository.dart';
import '../../widgets/app_drawer.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});
  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final _repo = Repository();
  Map<String, dynamic> summary = {};
  List<Map<String, dynamic>> low = [];
  List<Map<String, dynamic>> top = [];

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    summary = await _repo.dashboardSummary();
    low = await _repo.lowStockProducts();
    top = await _repo.topSellingProducts();
    if (mounted) setState(() {});
  }

  Widget _tile(String title, String value, IconData icon) => Card(child: ListTile(leading: Icon(icon), title: Text(title), trailing: Text(value, style: const TextStyle(fontWeight:FontWeight.bold))));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reports')),
      drawer: const AppDrawer(),
      body: RefreshIndicator(onRefresh:_load, child: ListView(padding: const EdgeInsets.all(16), children: [
        _tile('Total Products', '${summary['products'] ?? 0}', Icons.inventory_2),
        _tile('Low Stock Items', '${summary['lowStock'] ?? 0}', Icons.warning),
        _tile('Pending Orders', '${summary['pendingOrders'] ?? 0}', Icons.pending_actions),
        _tile('Today Sales', '${summary['todaySales'] ?? 0}', Icons.payments),
        _tile('Customer Dues', '${summary['totalDues'] ?? 0}', Icons.account_balance_wallet),
        _tile('Inventory Value', '${summary['inventoryValue'] ?? 0}', Icons.warehouse),
        const SizedBox(height:16),
        Text('Low / Out of Stock', style: Theme.of(context).textTheme.titleLarge),
        ...low.take(10).map((p)=>Card(child: ListTile(title:Text(p['name'].toString()), subtitle:Text('Stock: ${p['stock']} | Supplier: ${p['supplier_name'] ?? 'Not assigned'}')))),
        const SizedBox(height:16),
        Text('Top Selling Products', style: Theme.of(context).textTheme.titleLarge),
        ...top.map((p)=>Card(child: ListTile(title:Text(p['product_name'].toString()), subtitle:Text('Qty sold: ${p['qty']} | Sales: ${p['total']}')))),
      ])),
    );
  }
}
