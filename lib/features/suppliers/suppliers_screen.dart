import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/services/repository.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/empty_state.dart';

class SuppliersScreen extends StatefulWidget {
  const SuppliersScreen({super.key});
  @override
  State<SuppliersScreen> createState() => _SuppliersScreenState();
}

class _SuppliersScreenState extends State<SuppliersScreen> {
  final _repo = Repository();
  final _search = TextEditingController();
  List<Map<String, dynamic>> suppliers = [];

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final all = await _repo.all('suppliers', orderBy: 'name ASC');
    final q = _search.text.trim().toLowerCase();
    suppliers = q.isEmpty ? all : all.where((s) => '${s['name']} ${s['phone']} ${s['email']}'.toLowerCase().contains(q)).toList();
    if (mounted) setState(() {});
  }

  Future<void> _launch(String? value, bool email) async {
    if (value == null || value.trim().isEmpty) return;
    await launchUrl(email ? Uri(scheme: 'mailto', path: value.trim()) : Uri(scheme: 'tel', path: value.trim()));
  }

  Future<void> _showProducts(Map<String, dynamic> supplier) async {
    final products = await _repo.supplierProducts(supplier['id'] as int);
    if (!mounted) return;
    showModalBottomSheet(context: context, isScrollControlled: true, builder: (_) => Padding(
      padding: const EdgeInsets.all(16),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text('Products from ${supplier['name']}', style: const TextStyle(fontSize:20,fontWeight:FontWeight.bold)),
        const SizedBox(height:12),
        if(products.isEmpty) const Text('No products assigned to this supplier.'),
        ...products.map((p)=>ListTile(title: Text(p['name'].toString()), subtitle: Text('Stock: ${p['stock']} | Cost: ${p['cost_price']} | Price: ${p['sale_price']}'))),
      ]),
    ));
  }

  Future<void> _openForm([Map<String, dynamic>? s]) async {
    final name = TextEditingController(text: s?['name']?.toString() ?? '');
    final contact = TextEditingController(text: s?['contact_person']?.toString() ?? '');
    final phone = TextEditingController(text: s?['phone']?.toString() ?? '');
    final email = TextEditingController(text: s?['email']?.toString() ?? '');
    final address = TextEditingController(text: s?['address']?.toString() ?? '');
    final notes = TextEditingController(text: s?['notes']?.toString() ?? '');
    await showModalBottomSheet(context: context, isScrollControlled: true, builder: (_) => Padding(
      padding: EdgeInsets.only(left:16,right:16,top:16,bottom:MediaQuery.of(context).viewInsets.bottom+16),
      child: SingleChildScrollView(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text(s == null ? 'Add Supplier' : 'Edit Supplier', style: const TextStyle(fontSize:20,fontWeight:FontWeight.bold)),
        const SizedBox(height:12),
        TextField(controller:name, decoration: const InputDecoration(labelText:'Supplier name *')),
        const SizedBox(height:10),
        TextField(controller:contact, decoration: const InputDecoration(labelText:'Contact person')),
        const SizedBox(height:10),
        TextField(controller:phone, decoration: const InputDecoration(labelText:'Phone')),
        const SizedBox(height:10),
        TextField(controller:email, decoration: const InputDecoration(labelText:'Email')),
        const SizedBox(height:10),
        TextField(controller:address, decoration: const InputDecoration(labelText:'Address')),
        const SizedBox(height:10),
        TextField(controller:notes, decoration: const InputDecoration(labelText:'Notes')),
        const SizedBox(height:16),
        FilledButton(onPressed: () async {
          if (name.text.trim().isEmpty) return;
          final data = {'name':name.text.trim(),'contact_person':contact.text.trim(),'phone':phone.text.trim(),'email':email.text.trim(),'address':address.text.trim(),'notes':notes.text.trim(),'updated_at':DateTime.now().toIso8601String()};
          if (s == null) { data['created_at']=DateTime.now().toIso8601String(); await _repo.insert('suppliers', data); } else { await _repo.update('suppliers', data, s['id'] as int); }
          if (mounted) Navigator.pop(context);
          await _load();
        }, child: const Text('Save')),
      ])),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Suppliers')),
      drawer: const AppDrawer(),
      floatingActionButton: FloatingActionButton(onPressed: () => _openForm(), child: const Icon(Icons.add)),
      body: Column(children: [
        Padding(padding: const EdgeInsets.all(12), child: TextField(controller:_search, onChanged:(_)=>_load(), decoration: const InputDecoration(prefixIcon: Icon(Icons.search), labelText:'Search suppliers'))),
        Expanded(child: suppliers.isEmpty ? const EmptyState(icon: Icons.local_shipping, title: 'No suppliers found') : ListView.separated(
          padding: const EdgeInsets.all(12), itemCount: suppliers.length, separatorBuilder:(_,__)=>const SizedBox(height:4),
          itemBuilder: (_, i) { final s=suppliers[i]; return Card(child: ListTile(
            title: Text(s['name'].toString(), style: const TextStyle(fontWeight: FontWeight.w700)),
            subtitle: Text('${s['phone'] ?? ''}\nBalance: ${s['balance']}'),
            isThreeLine: true,
            leading: const CircleAvatar(child: Icon(Icons.local_shipping)),
            trailing: PopupMenuButton<String>(onSelected:(value){ if(value=='edit') _openForm(s); if(value=='products') _showProducts(s); if(value=='call') _launch(s['phone']?.toString(), false); if(value=='email') _launch(s['email']?.toString(), true); }, itemBuilder:(_)=> const [
              PopupMenuItem(value:'edit', child: Text('Edit')),
              PopupMenuItem(value:'products', child: Text('Products Offered')),
              PopupMenuItem(value:'call', child: Text('Call')),
              PopupMenuItem(value:'email', child: Text('Email')),
            ]),
            onTap:()=>_openForm(s),
          )); },
        )),
      ]),
    );
  }
}
