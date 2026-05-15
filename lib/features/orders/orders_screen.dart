import 'package:flutter/material.dart';
import '../../core/services/invoice_service.dart';
import '../../core/services/repository.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/empty_state.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key, this.initialFilter = 'all'});
  final String initialFilter;
  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  final _repo = Repository();
  List<Map<String, dynamic>> orders = [];
  List<Map<String, dynamic>> products = [];
  List<Map<String, dynamic>> customers = [];
  late String filter;

  @override
  void initState() {
    super.initState();
    filter = widget.initialFilter;
    _load();
  }

  Future<void> _load() async {
    products = await _repo.productsWithSuppliers();
    customers = await _repo.all('customers', orderBy: 'name ASC');
    final allOrders = await _repo.all('orders', orderBy: 'created_at DESC');
    orders = filter == 'all' ? allOrders : allOrders.where((o)=>o['status'] == filter).toList();
    if (mounted) setState(() {});
  }

  Future<double> _priceFor(Map<String, dynamic> product, int? customerId) async {
    if (customerId == null) return _repo.numToDouble(product['sale_price']);
    Map<String, dynamic>? customer;
    for (final c in customers) { if (c['id'] == customerId) customer = c; }
    if (customer != null && customer['customer_type'] == 'retailer') {
      return await _repo.retailerPrice(customerId, product['id'] as int) ?? _repo.numToDouble(product['sale_price']);
    }
    return _repo.numToDouble(product['sale_price']);
  }

  Future<void> _newOrder() async {
    final cart = <Map<String, dynamic>>[];
    int? selectedCustomer;
    final notes = TextEditingController();
    final discount = TextEditingController(text: '0');
    await showModalBottomSheet(context: context, isScrollControlled: true, builder: (_) => StatefulBuilder(builder:(context,setSheet){
      double subtotal() => cart.fold(0, (sum, i) => sum + _repo.numToDouble(i['total']));
      double total() => (subtotal() - (double.tryParse(discount.text) ?? 0)).clamp(0, double.infinity).toDouble();
      Future<void> addProduct(Map<String, dynamic> p) async {
        final price = await _priceFor(p, selectedCustomer);
        setSheet(()=>cart.add({'product_id':p['id'],'product_name':p['name'],'quantity':1.0,'price':price,'cost_price':p['cost_price'],'total':price}));
      }
      String customerName() {
        for (final c in customers) { if (c['id'] == selectedCustomer) return c['name'].toString(); }
        return 'Walk-in Customer';
      }
      return DraggableScrollableSheet(expand:false, initialChildSize:.95, builder:(_,controller)=>Padding(
        padding: EdgeInsets.only(left:16,right:16,top:16,bottom:MediaQuery.of(context).viewInsets.bottom+16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const Text('Create Pending Order', style: TextStyle(fontSize:20,fontWeight:FontWeight.bold)),
          const SizedBox(height:10),
          DropdownButtonFormField<int?>(value:selectedCustomer, items:[const DropdownMenuItem<int?>(value:null, child:Text('Walk-in Customer')), ...customers.map((c)=>DropdownMenuItem<int?>(value:c['id'] as int, child:Text('${c['name']} (${c['customer_type']})')))], onChanged:(v)=>setSheet(()=>selectedCustomer=v), decoration: const InputDecoration(labelText:'Customer / Retailer')),
          const SizedBox(height:10),
          Expanded(child: ListView.builder(controller:controller, itemCount:products.length, itemBuilder:(_,i){ final p=products[i]; return ListTile(title:Text(p['name'].toString()), subtitle:Text('Stock: ${p['stock']} | Price: ${p['sale_price']}'), trailing: const Icon(Icons.add), onTap:()=>addProduct(p)); })),
          const Divider(),
          Text('Cart: ${cart.length} | Total: ${total().toStringAsFixed(2)}', style: const TextStyle(fontWeight:FontWeight.bold)),
          SizedBox(height:120, child: ListView.builder(itemCount:cart.length, itemBuilder:(_,i){ final item=cart[i]; return ListTile(dense:true, title:Text(item['product_name'].toString()), subtitle:Text('${item['quantity']} x ${item['price']}'), trailing: IconButton(icon: const Icon(Icons.delete), onPressed:()=>setSheet(()=>cart.removeAt(i)))); })),
          TextField(controller:discount, keyboardType:TextInputType.number, decoration: const InputDecoration(labelText:'Discount'), onChanged:(_)=>setSheet((){})),
          const SizedBox(height:8),
          TextField(controller:notes, decoration: const InputDecoration(labelText:'Notes')),
          const SizedBox(height:8),
          FilledButton(onPressed: cart.isEmpty ? null : () async { await _repo.createOrder(customerId:selectedCustomer, customerName:customerName(), items:cart, discount:double.tryParse(discount.text)??0, notes:notes.text.trim()); if(mounted) Navigator.pop(context); await _load(); }, child: const Text('Save Pending Order')),
        ]),
      ));
    }));
  }

  Future<void> _deliver(Map<String, dynamic> order) async {
    try {
      await _repo.markOrderDelivered(order['id'] as int);
      await _load();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Order delivered and stock deducted.')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Orders')),
      drawer: const AppDrawer(),
      floatingActionButton: FloatingActionButton.extended(onPressed:_newOrder, icon: const Icon(Icons.add), label: const Text('New Order')),
      body: Column(children: [
        SingleChildScrollView(scrollDirection: Axis.horizontal, padding: const EdgeInsets.all(12), child: Row(children: ['all','pending','delivered','cancelled'].map((s)=>Padding(padding: const EdgeInsets.only(right:8), child: ChoiceChip(label:Text(s.toUpperCase()), selected:filter==s, onSelected:(_){setState(()=>filter=s); _load();}))).toList())),
        Expanded(child: orders.isEmpty ? const EmptyState(icon: Icons.assignment, title: 'No orders found') : ListView.builder(
          padding: const EdgeInsets.all(12), itemCount:orders.length,
          itemBuilder:(_,i){ final o=orders[i]; final status=o['status'].toString(); return Card(child: ListTile(
            title: Text(o['order_no'].toString(), style: const TextStyle(fontWeight:FontWeight.bold)),
            subtitle: Text('${o['customer_name'] ?? 'Walk-in Customer'}\nTotal: ${o['total']} | Status: $status'),
            isThreeLine: true,
            leading: CircleAvatar(child: Icon(status=='delivered'?Icons.done:status=='cancelled'?Icons.cancel:Icons.pending_actions)),
            trailing: PopupMenuButton<String>(onSelected:(value) async { if(value=='deliver') await _deliver(o); if(value=='cancel'){ await _repo.cancelOrder(o['id'] as int); await _load(); } if(value=='print') InvoiceService(_repo).printOrder(o['id'] as int); if(value=='share') InvoiceService(_repo).shareOrder(o['id'] as int); }, itemBuilder:(_)=>[
              if(status=='pending') const PopupMenuItem(value:'deliver', child:Text('Mark Delivered')),
              if(status=='pending') const PopupMenuItem(value:'cancel', child:Text('Cancel Order')),
              const PopupMenuItem(value:'print', child:Text('Print')),
              const PopupMenuItem(value:'share', child:Text('Share PDF')),
            ]),
          )); },
        )),
      ]),
    );
  }
}
