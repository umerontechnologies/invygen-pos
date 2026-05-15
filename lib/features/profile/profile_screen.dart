import 'package:flutter/material.dart';
import '../../core/services/repository.dart';
import '../../widgets/app_drawer.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _repo = Repository();
  Map<String, dynamic>? profile;

  @override
  void initState() { super.initState(); _load(); }
  Future<void> _load() async { profile = await _repo.profile(); if (mounted) setState(() {}); }

  Future<void> _edit() async {
    final name = TextEditingController(text: profile?['name']?.toString() ?? '');
    final email = TextEditingController(text: profile?['email']?.toString() ?? '');
    final phone = TextEditingController(text: profile?['phone']?.toString() ?? '');
    final role = TextEditingController(text: profile?['role']?.toString() ?? 'Owner');
    final pin = TextEditingController(text: profile?['pin']?.toString() ?? '');
    await showModalBottomSheet(context: context, isScrollControlled: true, builder: (_) => Padding(
      padding: EdgeInsets.only(left:16,right:16,top:16,bottom:MediaQuery.of(context).viewInsets.bottom+16),
      child: SingleChildScrollView(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const Text('Edit Profile', style: TextStyle(fontSize:20,fontWeight:FontWeight.bold)),
        const SizedBox(height:12),
        TextField(controller:name, decoration: const InputDecoration(labelText:'Full name')),
        const SizedBox(height:10),
        TextField(controller:email, decoration: const InputDecoration(labelText:'Email')),
        const SizedBox(height:10),
        TextField(controller:phone, decoration: const InputDecoration(labelText:'Phone')),
        const SizedBox(height:10),
        TextField(controller:role, decoration: const InputDecoration(labelText:'Role')),
        const SizedBox(height:10),
        TextField(controller:pin, decoration: const InputDecoration(labelText:'Optional local PIN')),
        const SizedBox(height:16),
        FilledButton(onPressed:() async { await _repo.saveProfile({'name':name.text.trim(),'email':email.text.trim(),'phone':phone.text.trim(),'role':role.text.trim(),'pin':pin.text.trim()}); if(mounted) Navigator.pop(context); await _load(); }, child: const Text('Save Profile')),
      ])),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      drawer: const AppDrawer(),
      floatingActionButton: FloatingActionButton(onPressed:_edit, child: const Icon(Icons.edit)),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Card(child: Padding(padding: const EdgeInsets.all(18), child: Column(children: [
          const CircleAvatar(radius:42, child: Icon(Icons.person, size:42)),
          const SizedBox(height:12),
          Text(profile?['name']?.toString().isNotEmpty == true ? profile!['name'].toString() : 'Owner', style: const TextStyle(fontSize:22,fontWeight:FontWeight.bold)),
          Text(profile?['role']?.toString() ?? 'Owner'),
          const Divider(),
          ListTile(leading: const Icon(Icons.email), title: Text(profile?['email']?.toString() ?? 'No email')),
          ListTile(leading: const Icon(Icons.phone), title: Text(profile?['phone']?.toString() ?? 'No phone')),
        ]))),
      ]),
    );
  }
}
