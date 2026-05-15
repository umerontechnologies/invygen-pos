import 'package:flutter/material.dart';
import '../../core/services/invoice_service.dart';
import '../../core/services/repository.dart';
import '../../widgets/app_drawer.dart';

class SalesScreen extends StatefulWidget {
  const SalesScreen({super.key});
  @override
  State<SalesScreen> createState() => _SalesScreenState();
}

class _SalesScreenState extends State<SalesScreen> {
  final _repo = Repository();
  final _search = TextEditingController();
  final _discount = TextEditingController(text: '0');
  final _received = TextEditingController();
  List<Map<String, dynamic>> products = [];
  List<Map<String, dynamic>> customers = [];
  List<Map<String, dynamic>> cart = [];
  int? customerId;
  String customerName = 'Walk-in Customer';
  String paymentMethod = 'Cash';

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    products = await _repo.productsWithSuppliers(query: _search.text);
    customers = await _repo.all('customers', orderBy: 'name ASC');
    if (mounted) setState(() {});
  }

  double get subtotal => cart.fold(0, (sum, i) => sum + _repo.numToDouble(i['total']));
  double get discount => double.tryParse(_discount.text) ?? 0;
  double get total => (subtotal - discount).clamp(0, double.infinity).toDouble();

  Future<double> _priceFor(Map<String, dynamic> product) async {
    if (customerId == null) return _repo.numToDouble(product['sale_price']);
    Map<String, dynamic>? customer;
    for (final c in customers) {
      if (c['id'] == customerId) customer = c;
    }
    if (customer != null && customer['customer_type'] == 'retailer') {
      return await _repo.retailerPrice(customerId!, product['id'] as int) ?? _repo.numToDouble(product['sale_price']);
    }
    return _repo.numToDouble(product['sale_price']);
  }

  Future<void> _addProduct(Map<String, dynamic> p) async {
    final stock = _repo.numToDouble(p['stock']);
    if (stock <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${p['name']} is out of stock. Contact supplier from Products screen.')));
      return;
    }
    final price = await _priceFor(p);
    final existing = cart.indexWhere((i) => i['product_id'] == p['id']);
    setState(() {
      if (existing >= 0) {
        final qty = _repo.numToDouble(cart[existing]['quantity']) + 1;
        cart[existing]['quantity'] = qty;
        cart[existing]['total'] = qty * _repo.numToDouble(cart[existing]['price']);
      } else {
        cart.add({'product_id': p['id'], 'product_name': p['name'], 'quantity': 1.0, 'price': price, 'cost_price': p['cost_price'], 'total': price});
      }
      _received.text = total.toStringAsFixed(2);
    });
  }

  void _changeQty(int index, double delta) {
    setState(() {
      final qty = (_repo.numToDouble(cart[index]['quantity']) + delta).clamp(1, 999999).toDouble();
      cart[index]['quantity'] = qty;
      cart[index]['total'] = qty * _repo.numToDouble(cart[index]['price']);
      _received.text = total.toStringAsFixed(2);
    });
  }

  Future<void> _newCustomer() async {
    final name = TextEditingController();
    final phone = TextEditingController();
    String type = 'customer';
    await showDialog(context: context, builder: (_) => StatefulBuilder(builder:(context,setDialog)=>AlertDialog(
      title: const Text('Add Customer / Retailer'),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller:name, decoration: const InputDecoration(labelText:'Name')),
        const SizedBox(height:10),
        TextField(controller:phone, decoration: const InputDecoration(labelText:'Phone')),
        const SizedBox(height:10),
        DropdownButtonFormField(value:type, items: const [DropdownMenuItem(value:'customer', child:Text('Customer')), DropdownMenuItem(value:'retailer', child:Text('Retailer'))], onChanged:(v)=>setDialog(()=>type=v ?? 'customer'), decoration: const InputDecoration(labelText:'Type')),
      ]),
      actions: [TextButton(onPressed:()=>Navigator.pop(context), child: const Text('Cancel')), FilledButton(onPressed:() async { if(name.text.trim().isEmpty) return; final id = await _repo.insert('customers', {'name':name.text.trim(),'phone':phone.text.trim(),'customer_type':type,'created_at':DateTime.now().toIso8601String()}); customerId=id; customerName=name.text.trim(); if(mounted) Navigator.pop(context); await _load(); }, child: const Text('Save'))],
    )));
  }

  Future<void> _finishSale() async {
    if (cart.isEmpty) return;
    try {
      final saleId = await _repo.completeSale(customerId: customerId, customerName: customerName, items: cart, discount: discount, received: double.tryParse(_received.text) ?? 0, paymentMethod: paymentMethod);
      setState(() { cart.clear(); _discount.text='0'; _received.clear(); });
      await _load();
      if (!mounted) return;
      showDialog(context: context, builder: (_) => AlertDialog(
        title: const Text('Sale completed'),
        content: const Text('Print or share the invoice/receipt?'),
        actions: [
          TextButton(onPressed:()=>Navigator.pop(context), child: const Text('Close')),
          TextButton(onPressed:(){ Navigator.pop(context); InvoiceService(_repo).shareSale(saleId); }, child: const Text('Share PDF')),
          FilledButton(onPressed:(){ Navigator.pop(context); InvoiceService(_repo).printSale(saleId); }, child: const Text('Print')),
        ],
      ));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    Map<String, dynamic>? selectedCustomer;
    for (final c in customers) {
      if (c['id'] == customerId) selectedCustomer = c;
    }
    if (selectedCustomer != null) customerName = selectedCustomer['name'].toString();
    return Scaffold(
      appBar: AppBar(title: const Text('POS Sale')),
      drawer: const AppDrawer(),
      body: Column(children: [
        Padding(padding: const EdgeInsets.all(12), child: Column(children: [
          Row(children: [
            Expanded(child: DropdownButtonFormField<int?>(
              value: customerId,
              items: [const DropdownMenuItem<int?>(value:null, child:Text('Walk-in Customer')), ...customers.map((c)=>DropdownMenuItem<int?>(value:c['id'] as int, child:Text('${c['name']} (${c['customer_type']})')))],
              onChanged:(v)=>setState(()=>customerId=v),
              decoration: const InputDecoration(labelText:'Customer / Retailer'),
            )),
            const SizedBox(width:8), IconButton.filledTonal(onPressed:_newCustomer, icon: const Icon(Icons.person_add)),
          ]),
          const SizedBox(height:10),
          TextField(controller:_search, onChanged:(_)=>_load(), decoration: const InputDecoration(prefixIcon:Icon(Icons.search), labelText:'Search products / scan barcode')),
        ])),
        Expanded(child: Row(children: [
          Expanded(flex: 5, child: ListView.builder(itemCount:products.length, itemBuilder:(_,i){ final p=products[i]; final stock=_repo.numToDouble(p['stock']); return Card(child: ListTile(title: Text(p['name'].toString()), subtitle: Text('Stock: $stock | Price: ${p['sale_price']}'), trailing: const Icon(Icons.add_shopping_cart), onTap:()=>_addProduct(p))); })),
          if (MediaQuery.of(context).size.width > 700) Expanded(flex: 4, child: _cartPanel()),
        ])),
        if (MediaQuery.of(context).size.width <= 700) _cartPanel(compact: true),
      ]),
    );
  }

  Widget _cartPanel({bool compact = false}) {
    return Container(
      constraints: compact ? const BoxConstraints(maxHeight: 320) : null,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Theme.of(context).colorScheme.surfaceContainerHighest),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text('Cart (${cart.length}) - Total: ${total.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height:8),
        Expanded(child: cart.isEmpty ? const Center(child: Text('Tap products to add')) : ListView.builder(itemCount:cart.length, itemBuilder:(_,i){ final item=cart[i]; return ListTile(
          dense: true,
          title: Text(item['product_name'].toString()),
          subtitle: Text('${item['quantity']} x ${item['price']} = ${_repo.numToDouble(item['total']).toStringAsFixed(2)}'),
          trailing: Wrap(children: [IconButton(icon: const Icon(Icons.remove_circle_outline), onPressed:()=>_changeQty(i,-1)), IconButton(icon: const Icon(Icons.add_circle_outline), onPressed:()=>_changeQty(i,1)), IconButton(icon: const Icon(Icons.delete_outline), onPressed:()=>setState(()=>cart.removeAt(i))) ]),
        ); })),
        Row(children: [
          Expanded(child: TextField(controller:_discount, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText:'Discount'), onChanged:(_)=>setState(()=>_received.text=total.toStringAsFixed(2)))),
          const SizedBox(width:8),
          Expanded(child: TextField(controller:_received, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText:'Received'))),
        ]),
        const SizedBox(height:8),
        DropdownButtonFormField(value:paymentMethod, items:['Cash','Card','Bank','Mobile','Other'].map((e)=>DropdownMenuItem(value:e, child:Text(e))).toList(), onChanged:(v)=>setState(()=>paymentMethod=v ?? 'Cash'), decoration: const InputDecoration(labelText:'Payment method')),
        const SizedBox(height:8),
        FilledButton.icon(onPressed:_finishSale, icon: const Icon(Icons.check), label: const Text('Complete Sale & Invoice')),
      ]),
    );
  }
}
