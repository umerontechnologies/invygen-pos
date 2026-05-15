import 'package:flutter/material.dart';

class AppStrings {
  static const supportedLanguages = <String, String>{
    'en': 'English',
    'es': 'Spanish',
    'fr': 'French',
    'ar': 'Arabic',
  };

  static const _strings = <String, Map<String, String>>{
    'app_name': {'en': 'Invygen', 'es': 'Invygen', 'fr': 'Invygen', 'ar': 'Invygen'},
    'dashboard': {'en': 'Dashboard', 'es': 'Panel', 'fr': 'Tableau', 'ar': 'لوحة التحكم'},
    'products': {'en': 'Products', 'es': 'Productos', 'fr': 'Produits', 'ar': 'المنتجات'},
    'customers': {'en': 'Customers', 'es': 'Clientes', 'fr': 'Clients', 'ar': 'العملاء'},
    'retailers': {'en': 'Retailers', 'es': 'Minoristas', 'fr': 'Detaillants', 'ar': 'تجار التجزئة'},
    'suppliers': {'en': 'Suppliers', 'es': 'Proveedores', 'fr': 'Fournisseurs', 'ar': 'الموردون'},
    'purchases': {'en': 'Purchases / Stock In', 'es': 'Compras / Stock', 'fr': 'Achats / Stock', 'ar': 'المشتريات / المخزون'},
    'sales': {'en': 'Sales', 'es': 'Ventas', 'fr': 'Ventes', 'ar': 'المبيعات'},
    'orders': {'en': 'Orders', 'es': 'Pedidos', 'fr': 'Commandes', 'ar': 'الطلبات'},
    'reports': {'en': 'Reports', 'es': 'Informes', 'fr': 'Rapports', 'ar': 'التقارير'},
    'profile': {'en': 'Profile', 'es': 'Perfil', 'fr': 'Profil', 'ar': 'الملف الشخصي'},
    'settings': {'en': 'Settings', 'es': 'Ajustes', 'fr': 'Paramètres', 'ar': 'الإعدادات'},
    'backup_restore': {'en': 'Backup & Restore', 'es': 'Copia y restauración', 'fr': 'Sauvegarde', 'ar': 'نسخ احتياطي واستعادة'},
    'business_profile': {'en': 'Business Profile', 'es': 'Perfil del negocio', 'fr': 'Profil entreprise', 'ar': 'ملف النشاط'},
    'save': {'en': 'Save', 'es': 'Guardar', 'fr': 'Enregistrer', 'ar': 'حفظ'},
    'cancel': {'en': 'Cancel', 'es': 'Cancelar', 'fr': 'Annuler', 'ar': 'إلغاء'},
    'print': {'en': 'Print', 'es': 'Imprimir', 'fr': 'Imprimer', 'ar': 'طباعة'},
    'share': {'en': 'Share', 'es': 'Compartir', 'fr': 'Partager', 'ar': 'مشاركة'},
    'total': {'en': 'Total', 'es': 'Total', 'fr': 'Total', 'ar': 'الإجمالي'},
    'stock': {'en': 'Stock', 'es': 'Stock', 'fr': 'Stock', 'ar': 'المخزون'},
    'low_stock': {'en': 'Low Stock', 'es': 'Stock bajo', 'fr': 'Stock faible', 'ar': 'مخزون منخفض'},
    'out_of_stock': {'en': 'Out of Stock', 'es': 'Sin stock', 'fr': 'Rupture', 'ar': 'نفد المخزون'},
  };

  static String text(String key, String lang) {
    return _strings[key]?[lang] ?? _strings[key]?['en'] ?? key;
  }
}

class AppScope extends InheritedWidget {
  const AppScope({super.key, required this.language, required this.setLanguage, required super.child});
  final String language;
  final Future<void> Function(String language) setLanguage;

  static AppScope of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'AppScope missing');
    return scope!;
  }

  String t(String key) => AppStrings.text(key, language);

  @override
  bool updateShouldNotify(AppScope oldWidget) => oldWidget.language != language;
}
