import 'package:flutter/material.dart';
import '../../core/services/repository.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/empty_state.dart';
import '../retailer_prices/retailer_prices_screen.dart';

class CustomersScreen extends StatefulWidget {
  const CustomersScreen({super.key, required this.type});
  final String type;
  @override
  State<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends State<CustomersScreen> {
  final _repo = Repository();
  final _search = TextEditingController();
  List<Map<String, dynamic>> customers = [];

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final all = await _repo.customersByType(widget.type);
    final q = _search.text.trim().toLowerCase();
    customers = q.isEmpty ? all : all.where((c) => '${c['name']} ${c['phone']} ${c['email']}'.toLowerCase().contains(q)).toList();
    if (mounted) setState(() {});
  }

  Future<void> _payment(Map<String, dynamic> c) async {
    final amount = TextEditingController();
    final notes = TextEditingController();
    String method = 'Cash';
    await showModalBottomSheet(context: context, isScrollControlled: true, builder: (_) => StatefulBuilder(builder: (context, setSheet) => Padding(
      padding: EdgeInsets.only(left:16,right:16,top:16,bottom:MediaQuery.of(context).viewInsets.bottom+16),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text('Receive Payment - ${c['name']}', style: const TextStyle(fontSize:20,fontWeight:FontWeight.bold)),
        const SizedBox(height:12),
        Text('Current balance: ${c['balance']}'),
        const SizedBox(height:10),
        TextField(controller: amount, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText:'Amount received')),
        const SizedBox(height:10),
        DropdownButtonFormField(value: method, items: ['Cash','Card','Bank','Mobile','Other'].map((e)=>DropdownMenuItem(value:e, child:Text(e))).toList(), onChanged:(v)=>setSheet(()=>method=v ?? 'Cash'), decoration: const InputDecoration(labelText:'Payment method')),
        const SizedBox(height:10),
        TextField(controller: notes, decoration: const InputDecoration(labelText:'Notes')),
        const SizedBox(height:16),
        FilledButton(onPressed: () async {
          await _repo.recordCustomerPayment(c['id'] as int, double.tryParse(amount.text) ?? 0, paymentMethod: method, notes: notes.text.trim());
          if (mounted) Navigator.pop(context);
          await _load();
        }, child: const Text('Save Payment')),
      ]),
    )));
  }

  Future<void> _openForm([Map<String, dynamic>? c]) async {
    final name = TextEditingController(text: c?['name']?.toString() ?? '');
    final phone = TextEditingController(text: c?['phone']?.toString() ?? '');
    final email = TextEditingController(text: c?['email']?.toString() ?? '');
    final address = TextEditingController(text: c?['address']?.toString() ?? '');
    final creditLimit = TextEditingController(text: (c?['credit_limit'] ?? '0').toString());
    final notes = TextEditingController(text: c?['notes']?.toString() ?? '');
    await showModalBottomSheet(context: context, isScrollControlled: true, builder: (_) => Padding(
      padding: EdgeInsets.only(left:16,right:16,top:16,bottom:MediaQuery.of(context).viewInsets.bottom+16),
      child: SingleChildScrollView(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text(c == null ? 'Add ${widget.type}' : 'Edit ${widget.type}', style: const TextStyle(fontSize:20,fontWeight:FontWeight.bold)),
        const SizedBox(height:12),
        TextField(controller:name, decoration: const InputDecoration(labelText:'Name *')),
        const SizedBox(height:10),
        TextField(controller:phone, decoration: const InputDecoration(labelText:'Phone')),
        const SizedBox(height:10),
        TextField(controller:email, decoration: const InputDecoration(labelText:'Email')),
        const SizedBox(height:10),
        TextField(controller:address, decoration: const InputDecoration(labelText:'Address')),
        const SizedBox(height:10),
        TextField(controller:creditLimit, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText:'Credit limit')),
        const SizedBox(height:10),
        TextField(controller:notes, decoration: const InputDecoration(labelText:'Notes')),
        const SizedBox(height:16),
        FilledButton(onPressed: () async {
          if (name.text.trim().isEmpty) return;
          final data = {'name':name.text.trim(),'phone':phone.text.trim(),'email':email.text.trim(),'address':address.text.trim(),'customer_type':widget.type,'credit_limit':double.tryParse(creditLimit.text) ?? 0,'notes':notes.text.trim(),'updated_at':DateTime.now().toIso8601String()};
          if (c == null) { data['created_at']=DateTime.now().toIso8601String(); await _repo.insert('customers', data); } else { await _repo.update('customers', data, c['id'] as int); }
          if (mounted) Navigator.pop(context);
          await _load();
        }, child: const Text('Save')),
      ])),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.type == 'retailer' ? 'Retailers' : 'Customers';
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      drawer: const AppDrawer(),
      floatingActionButton: FloatingActionButton(onPressed: () => _openForm(), child: const Icon(Icons.add)),
      body: Column(children: [
        Padding(padding: const EdgeInsets.all(12), child: TextField(controller:_search, onChanged:(_)=>_load(), decoration: const InputDecoration(prefixIcon: Icon(Icons.search), labelText:'Search name, phone or email'))),
        Expanded(child: customers.isEmpty ? EmptyState(icon: widget.type == 'retailer' ? Icons.storefront : Icons.people, title: 'No $title found') : ListView.separated(
          padding: const EdgeInsets.all(12), itemCount: customers.length, separatorBuilder:(_,__)=>const SizedBox(height:4),
          itemBuilder: (_, i) { final c=customers[i]; final balance=_repo.numToDouble(c['balance']); return Card(child: ListTile(
            title: Text(c['name'].toString(), style: const TextStyle(fontWeight: FontWeight.w700)),
            subtitle: Text('${c['phone'] ?? ''}\nBalance: ${balance.toStringAsFixed(2)}'),
            isThreeLine: true,
            leading: CircleAvatar(child: Icon(widget.type == 'retailer' ? Icons.storefront : Icons.person)),
            trailing: PopupMenuButton<String>(onSelected:(value){ if(value=='edit') _openForm(c); if(value=='pay') _payment(c); if(value=='prices') Navigator.push(context, MaterialPageRoute(builder:(_)=>RetailerPricesScreen(retailer: c))).then((_)=>_load()); }, itemBuilder:(_)=>[
              const PopupMenuItem(value:'edit', child: Text('Edit')),
              const PopupMenuItem(value:'pay', child: Text('Receive Payment')),
              if(widget.type=='retailer') const PopupMenuItem(value:'prices', child: Text('Retailer Prices')),
            ]),
            onTap:()=>_openForm(c),
          )); },
        )),
      ]),
    );
  }
}
