import 'package:flutter/material.dart';
import 'package:wipro_examination_portal/pages/login_page.dart';
import 'package:wipro_examination_portal/supabase_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase
  await SupabaseConfig.initialize();

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Wipro Examination Portal',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: LoginPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}