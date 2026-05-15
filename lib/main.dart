import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/database/app_database.dart';
import 'core/i18n/app_strings.dart';
import 'core/theme/app_theme.dart';
import 'features/dashboard/dashboard_screen.dart';
import 'features/onboarding/onboarding_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppDatabase.instance.database;
  final prefs = await SharedPreferences.getInstance();
  final isSetupDone = prefs.getBool('setup_done') ?? false;
  final language = prefs.getString('language') ?? 'en';
  runApp(InvygenApp(isSetupDone: isSetupDone, initialLanguage: language));
}

class InvygenApp extends StatefulWidget {
  const InvygenApp({super.key, required this.isSetupDone, required this.initialLanguage});
  final bool isSetupDone;
  final String initialLanguage;

  @override
  State<InvygenApp> createState() => _InvygenAppState();
}

class _InvygenAppState extends State<InvygenApp> {
  late String language = widget.initialLanguage;

  Future<void> setLanguage(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language', value);
    setState(() => language = value);
  }

  @override
  Widget build(BuildContext context) {
    return AppScope(
      language: language,
      setLanguage: setLanguage,
      child: MaterialApp(
        title: 'Invygen',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        home: widget.isSetupDone ? const DashboardScreen() : const OnboardingScreen(),
      ),
    );
  }
}
