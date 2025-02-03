import 'package:elderly/screens/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/local_storage.dart';

class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final SupabaseClient supabase = Supabase.instance.client;
  Map<String, dynamic>? userData;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchUserProfile();
  }

  Future<void> fetchUserProfile() async {
    final user = supabase.auth.currentUser;

    if (user == null) {
      setState(() {
        isLoading = false;
      });
      return;
    }

    try {
      // Fetch user profile data from the 'profiles' table (excluding email)
      final response = await supabase
          .from('profiles')
          .select()
          .eq('id', user.id)
          .single();

      setState(() {
        userData = response;
        isLoading = false;
      });
    } catch (error) {
      print("Error fetching profile: $error");
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> logout(BuildContext context) async {
  try {
    await supabase.auth.signOut();  // Sign out from Supabase
    await clearUserDetails();  // Clear saved user details
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => LoginScreen()),  // Navigate to Login screen
    );
  } catch (error) {
    print("Error logging out: $error");
  }
}

  @override
  Widget build(BuildContext context) {
    final user = supabase.auth.currentUser;
    final email = user?.email ?? 'No email available'; // Get email from auth

    return Scaffold(
      appBar: AppBar(
        title: Text("Profile Settings"),
        actions: [
          IconButton(
            icon: Icon(Icons.exit_to_app),
            onPressed: () => logout(context),
          ),
        ],
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : userData == null
              ? Center(child: Text("No profile data found"))
              : Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Name: ${userData!['name']}", style: TextStyle(fontSize: 18)),
                      SizedBox(height: 10),
                      Text("Email: $email", style: TextStyle(fontSize: 18)), // Display email from auth
                      SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () => logout(context),
                        child: Text("Log Out"),
                      ),
                    ],
                  ),
                ),
    );
  }
}
