import 'package:flutter/material.dart';
import '../../core/i18n/app_strings.dart';
import '../../core/services/backup_service.dart';
import '../../core/services/repository.dart';
import '../../widgets/app_drawer.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _repo = Repository();
  Map<String, dynamic>? business;

  @override
  void initState() { super.initState(); _load(); }
  Future<void> _load() async { business = await _repo.business(); if (mounted) setState(() {}); }

  Future<void> _editBusiness() async {
    final name = TextEditingController(text: business?['name']?.toString() ?? '');
    final owner = TextEditingController(text: business?['owner_name']?.toString() ?? '');
    final phone = TextEditingController(text: business?['phone']?.toString() ?? '');
    final email = TextEditingController(text: business?['email']?.toString() ?? '');
    final address = TextEditingController(text: business?['address']?.toString() ?? '');
    final country = TextEditingController(text: business?['country']?.toString() ?? '');
    final currency = TextEditingController(text: business?['currency']?.toString() ?? 'USD');
    final taxName = TextEditingController(text: business?['tax_name']?.toString() ?? '');
    final taxNumber = TextEditingController(text: business?['tax_number']?.toString() ?? '');
    final prefix = TextEditingController(text: business?['invoice_prefix']?.toString() ?? 'INV');
    final footer = TextEditingController(text: business?['receipt_footer']?.toString() ?? 'Thank you for your business.');
    await showModalBottomSheet(context: context, isScrollControlled: true, builder: (_) => Padding(
      padding: EdgeInsets.only(left:16,right:16,top:16,bottom:MediaQuery.of(context).viewInsets.bottom+16),
      child: SingleChildScrollView(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const Text('Business Profile', style: TextStyle(fontSize:20,fontWeight:FontWeight.bold)),
        const SizedBox(height:12),
        TextField(controller:name, decoration: const InputDecoration(labelText:'Business name *')),
        const SizedBox(height:10),
        TextField(controller:owner, decoration: const InputDecoration(labelText:'Owner name')),
        const SizedBox(height:10),
        TextField(controller:phone, decoration: const InputDecoration(labelText:'Phone')),
        const SizedBox(height:10),
        TextField(controller:email, decoration: const InputDecoration(labelText:'Email')),
        const SizedBox(height:10),
        TextField(controller:address, decoration: const InputDecoration(labelText:'Address')),
        const SizedBox(height:10),
        Row(children:[Expanded(child:TextField(controller:country, decoration: const InputDecoration(labelText:'Country'))), const SizedBox(width:10), Expanded(child:TextField(controller:currency, decoration: const InputDecoration(labelText:'Currency')))]),
        const SizedBox(height:10),
        Row(children:[Expanded(child:TextField(controller:taxName, decoration: const InputDecoration(labelText:'Tax name'))), const SizedBox(width:10), Expanded(child:TextField(controller:taxNumber, decoration: const InputDecoration(labelText:'Tax number')))]),
        const SizedBox(height:10),
        TextField(controller:prefix, decoration: const InputDecoration(labelText:'Invoice prefix')),
        const SizedBox(height:10),
        TextField(controller:footer, decoration: const InputDecoration(labelText:'Receipt footer')),
        const SizedBox(height:16),
        FilledButton(onPressed:() async { if(name.text.trim().isEmpty) return; await _repo.saveBusiness({'name':name.text.trim(),'owner_name':owner.text.trim(),'phone':phone.text.trim(),'email':email.text.trim(),'address':address.text.trim(),'country':country.text.trim(),'currency':currency.text.trim().isEmpty?'USD':currency.text.trim(),'tax_name':taxName.text.trim(),'tax_number':taxNumber.text.trim(),'invoice_prefix':prefix.text.trim().isEmpty?'INV':prefix.text.trim(),'receipt_footer':footer.text.trim()}); if(mounted) Navigator.pop(context); await _load(); }, child: const Text('Save Business')),
      ])),
    ));
  }

  Future<void> _backup() async {
    await BackupService().shareBackup();
  }

  Future<void> _restore() async {
    final count = await BackupService().restoreFromPickedFile();
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Restored $count rows. Restart app if needed.')));
  }

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      drawer: const AppDrawer(),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Card(child: ListTile(leading: const Icon(Icons.business), title: const Text('Business Profile'), subtitle: Text(business?['name']?.toString() ?? 'Set business details'), trailing: const Icon(Icons.edit), onTap:_editBusiness)),
        Card(child: ListTile(leading: const Icon(Icons.language), title: const Text('Language'), subtitle: Text(AppStrings.supportedLanguages[scope.language] ?? 'English'), onTap:() async { final lang = await showModalBottomSheet<String>(context:context, builder:(_)=>ListView(padding: const EdgeInsets.all(16), children: AppStrings.supportedLanguages.entries.map((e)=>ListTile(title:Text(e.value), onTap:()=>Navigator.pop(context,e.key))).toList())); if(lang!=null) await scope.setLanguage(lang); })),
        Card(child: ListTile(leading: const Icon(Icons.backup), title: const Text('Export Backup'), subtitle: const Text('Create and share a complete offline JSON backup'), onTap:_backup)),
        Card(child: ListTile(leading: const Icon(Icons.restore), title: const Text('Restore Backup'), subtitle: const Text('Restore from an Invygen JSON backup file'), onTap:_restore)),
        const Card(child: ListTile(leading: Icon(Icons.info), title: Text('About'), subtitle: Text('Invygen Offline POS & Inventory by UMERON Technologies'))),
      ]),
    );
  }
}
