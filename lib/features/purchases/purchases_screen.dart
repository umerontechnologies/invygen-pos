import 'package:flutter/material.dart';
import '../../core/services/repository.dart';
import '../../widgets/app_drawer.dart';

class PurchasesScreen extends StatefulWidget {
  const PurchasesScreen({super.key});
  @override
  State<PurchasesScreen> createState() => _PurchasesScreenState();
}

class _PurchasesScreenState extends State<PurchasesScreen> {
  final _repo = Repository();
  List<Map<String, dynamic>> suppliers = [];
  List<Map<String, dynamic>> products = [];
  List<Map<String, dynamic>> cart = [];
  int? supplierId;
  double paid = 0;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    suppliers = await _repo.all('suppliers', orderBy: 'name ASC');
    products = await _repo.productsWithSuppliers();
    if (mounted) setState(() {});
  }

  double get total => cart.fold(0, (sum, i) => sum + _repo.numToDouble(i['total']));

  Future<void> _addProduct(Map<String, dynamic> p) async {
    final qty = TextEditingController(text: '1');
    final cost = TextEditingController(text: p['cost_price'].toString());
    await showDialog(context: context, builder: (_) => AlertDialog(
      title: Text('Stock In - ${p['name']}'),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: qty, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText:'Quantity')),
        const SizedBox(height:10),
        TextField(controller: cost, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText:'Cost price')),
      ]),
      actions: [
        TextButton(onPressed:()=>Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(onPressed:(){ final q=double.tryParse(qty.text)??0; final c=double.tryParse(cost.text)??0; if(q>0){ setState(()=>cart.add({'product_id':p['id'],'product_name':p['name'],'quantity':q,'cost_price':c,'total':q*c})); } Navigator.pop(context); }, child: const Text('Add')),
      ],
    ));
  }

  Future<void> _finish() async {
    if (cart.isEmpty) return;
    await _repo.createPurchase(supplierId: supplierId, items: cart, paid: paid);
    setState(() { cart.clear(); paid = 0; });
    await _load();
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Stock updated successfully')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Purchases / Stock In')),
      drawer: const AppDrawer(),
      body: Column(children: [
        Padding(padding: const EdgeInsets.all(12), child: DropdownButtonFormField<int?>(
          value: supplierId,
          items: [const DropdownMenuItem<int?>(value:null, child:Text('No supplier')), ...suppliers.map((s)=>DropdownMenuItem<int?>(value:s['id'] as int, child:Text(s['name'].toString())))],
          onChanged:(v)=>setState(()=>supplierId=v),
          decoration: const InputDecoration(labelText:'Supplier'),
        )),
        Expanded(child: ListView.builder(itemCount: products.length, itemBuilder:(_,i){ final p=products[i]; return ListTile(title: Text(p['name'].toString()), subtitle: Text('Stock: ${p['stock']} | Cost: ${p['cost_price']}'), trailing: const Icon(Icons.add), onTap:()=>_addProduct(p)); })),
        Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Theme.of(context).colorScheme.surfaceContainerHighest), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children:[
          Text('Items: ${cart.length} | Total: ${total.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height:8),
          TextField(keyboardType: TextInputType.number, decoration: const InputDecoration(labelText:'Paid amount'), onChanged:(v)=>paid=double.tryParse(v)??0),
          const SizedBox(height:8),
          FilledButton(onPressed:_finish, child: const Text('Save Purchase & Update Stock')),
        ])),
      ]),
    );
  }
}
