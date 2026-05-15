import 'package:flutter/material.dart';
import '../../core/i18n/app_strings.dart';
import '../../core/services/repository.dart';
import '../../widgets/app_drawer.dart';
import '../orders/orders_screen.dart';
import '../products/products_screen.dart';
import '../purchases/purchases_screen.dart';
import '../sales/sales_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _repo = Repository();
  Map<String, dynamic> summary = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    summary = await _repo.dashboardSummary();
    if (mounted) setState(() {});
  }

  void _go(Widget page) => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => page));

  Widget _card(String title, String value, IconData icon, Color color, {VoidCallback? onTap}) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(backgroundColor: color.withOpacity(.12), child: Icon(icon, color: color)),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title), Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold))])),
            ],
          ),
        ),
      ),
    );
  }

  Widget _quick(String title, IconData icon, Widget page) {
    return Expanded(
      child: FilledButton.tonalIcon(
        onPressed: () => _go(page),
        icon: Icon(icon),
        label: Text(title, textAlign: TextAlign.center),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppScope.of(context).t;
    final currency = ' ${summary['currency'] ?? ''}';
    return Scaffold(
      appBar: AppBar(title: Text(t('dashboard'))),
      drawer: const AppDrawer(),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text('Run your business offline', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            const Text('POS, stock, orders, customers, suppliers and invoices in one app.'),
            const SizedBox(height: 12),
            Row(children: [_quick('Sale', Icons.point_of_sale, const SalesScreen()), const SizedBox(width: 8), _quick('Stock In', Icons.add_business, const PurchasesScreen())]),
            const SizedBox(height: 8),
            Row(children: [_quick('Orders', Icons.assignment, const OrdersScreen()), const SizedBox(width: 8), _quick('Products', Icons.inventory_2, const ProductsScreen())]),
            const SizedBox(height: 16),
            _card('Products', '${summary['products'] ?? 0}', Icons.inventory_2, Colors.blue, onTap: () => _go(const ProductsScreen())),
            _card('Low Stock', '${summary['lowStock'] ?? 0}', Icons.warning, Colors.orange, onTap: () => _go(const ProductsScreen(lowOnly: true))),
            _card('Pending Orders', '${summary['pendingOrders'] ?? 0}', Icons.pending_actions, Colors.purple, onTap: () => _go(const OrdersScreen(initialFilter: 'pending'))),
            _card('Today Sales', '${(summary['todaySales'] ?? 0).toString()}$currency', Icons.payments, Colors.green),
            _card('Customer Dues', '${(summary['totalDues'] ?? 0).toString()}$currency', Icons.account_balance_wallet, Colors.red),
            _card('Inventory Value', '${(summary['inventoryValue'] ?? 0).toString()}$currency', Icons.warehouse, Colors.indigo),
          ],
        ),
      ),
    );
  }
}
