import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/services/backup_service.dart';
import '../../core/services/repository.dart';
import '../dashboard/dashboard_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _business = TextEditingController();
  final _owner = TextEditingController();
  final _country = TextEditingController();
  final _currency = TextEditingController(text: 'USD');
  final _repo = Repository();

  Future<void> _finishSetup() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('setup_done', true);
    if (!mounted) return;
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const DashboardScreen()));
  }

  Future<void> _start() async {
    if (!_formKey.currentState!.validate()) return;
    await _repo.saveBusiness({
      'name': _business.text.trim(),
      'owner_name': _owner.text.trim(),
      'country': _country.text.trim(),
      'currency': _currency.text.trim().isEmpty ? 'USD' : _currency.text.trim(),
      'invoice_prefix': 'INV',
      'receipt_footer': 'Thank you for your business.',
    });
    await _repo.saveProfile({'name': _owner.text.trim(), 'role': 'Owner'});
    await _finishSetup();
  }

  Future<void> _restore() async {
    final count = await BackupService().restoreFromPickedFile();
    if (count > 0) await _finishSetup();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Image.asset('assets/icons/invygen_icon.png', height: 86),
                  const SizedBox(height: 16),
                  const Text('Welcome to Invygen', textAlign: TextAlign.center, style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  const Text('Offline POS, inventory, orders, receipts and customer credit for your business.', textAlign: TextAlign.center),
                  const SizedBox(height: 32),
                  TextFormField(controller: _business, decoration: const InputDecoration(labelText: 'Business name'), validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null),
                  const SizedBox(height: 12),
                  TextFormField(controller: _owner, decoration: const InputDecoration(labelText: 'Owner name')),
                  const SizedBox(height: 12),
                  TextFormField(controller: _country, decoration: const InputDecoration(labelText: 'Country')),
                  const SizedBox(height: 12),
                  TextFormField(controller: _currency, decoration: const InputDecoration(labelText: 'Currency code, e.g. USD, GBP, EUR')),
                  const SizedBox(height: 20),
                  FilledButton(onPressed: _start, child: const Text('I am a New User')),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(onPressed: _restore, icon: const Icon(Icons.restore), label: const Text('Existing User / Restore Backup')),
                  const SizedBox(height: 8),
                  const Text('Google/email cloud login can be added later when cloud sync is enabled. This version works offline without forced signup.', textAlign: TextAlign.center, style: TextStyle(fontSize: 12)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
