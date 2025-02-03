import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/login_screen.dart';
import 'screens/signup_screen.dart';
import 'widgets/bottom_nav.dart';

Future<void> main() async {
  await Supabase.initialize(
    url: 'https://crvlrgvfqcbopgjvayvd.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImNydmxyZ3ZmcWNib3BnanZheXZkIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Mzg1NTIyNzEsImV4cCI6MjA1NDEyODI3MX0.-C3Ot4GgqprNyj2xgJDB3mZy4Jvb_Dq_zOFKYU3umBE',
  );
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Elderly App',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: FutureBuilder(
        future: checkLoginStatus(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Scaffold(body: Center(child: CircularProgressIndicator()));
          }

          if (snapshot.hasError) {
            return Scaffold(body: Center(child: Text("Error: ${snapshot.error}")));
          }

          if (snapshot.data == true) {
            return BottomNavBar();  // User is logged in
          } else {
            return LoginScreen();  // User is not logged in
          }
        },
      ),
      routes: {
        "/signup": (context) => SignUpScreen(),
        "/dashboard": (context) => BottomNavBar(),
      },
    );
  }

  // Check if the user is already logged in
  Future<bool> checkLoginStatus() async {
    final session = Supabase.instance.client.auth.currentSession;
    return session?.user != null;
  }
}
