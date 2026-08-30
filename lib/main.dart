import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'theme/app_theme.dart';
import 'role_selection_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Supabase.initialize(
      url: 'https://thklxiioebitdolnyepd.supabase.co',
      anonKey: 'sb_publishable_lU0UmjDhw-r8285XFV-7tQ_rizjgdrG',
    );
  } catch (e) {
    debugPrint("Supabase init info/fallback: $e");
  }

  runApp(const QLessApp());
}

class QLessApp extends StatelessWidget {
  const QLessApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'QLess - Queue-Less Canteen',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const RoleSelectionPage(),
    );
  }
}
