import 'package:flutter/material.dart';
import '../core/i18n/app_strings.dart';
import '../features/customers/customers_screen.dart';
import '../features/dashboard/dashboard_screen.dart';
import '../features/orders/orders_screen.dart';
import '../features/products/products_screen.dart';
import '../features/profile/profile_screen.dart';
import '../features/purchases/purchases_screen.dart';
import '../features/reports/reports_screen.dart';
import '../features/sales/sales_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/suppliers/suppliers_screen.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  void _go(BuildContext context, Widget page) {
    Navigator.pop(context);
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => page));
  }

  @override
  Widget build(BuildContext context) {
    final t = AppScope.of(context).t;
    return Drawer(
      child: ListView(
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(color: Color(0xFF1565C0)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Image.asset('assets/icons/invygen_icon.png', width: 56, height: 56),
                const SizedBox(height: 12),
                const Text('Invygen', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                const Text('Offline POS & Inventory', style: TextStyle(color: Colors.white70)),
              ],
            ),
          ),
          _tile(context, Icons.dashboard, t('dashboard'), const DashboardScreen()),
          _tile(context, Icons.inventory_2, t('products'), const ProductsScreen()),
          _tile(context, Icons.people, t('customers'), const CustomersScreen(type: 'customer')),
          _tile(context, Icons.storefront, t('retailers'), const CustomersScreen(type: 'retailer')),
          _tile(context, Icons.local_shipping, t('suppliers'), const SuppliersScreen()),
          _tile(context, Icons.add_business, t('purchases'), const PurchasesScreen()),
          _tile(context, Icons.point_of_sale, t('sales'), const SalesScreen()),
          _tile(context, Icons.assignment, t('orders'), const OrdersScreen()),
          _tile(context, Icons.analytics, t('reports'), const ReportsScreen()),
          _tile(context, Icons.person, t('profile'), const ProfileScreen()),
          _tile(context, Icons.settings, t('settings'), const SettingsScreen()),
        ],
      ),
    );
  }

  ListTile _tile(BuildContext context, IconData icon, String title, Widget page) {
    return ListTile(leading: Icon(icon), title: Text(title), onTap: () => _go(context, page));
  }
}
