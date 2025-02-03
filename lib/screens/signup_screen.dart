import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../widgets/bottom_nav.dart';
import 'email_verification_screen.dart';

final supabase = Supabase.instance.client; // ✅ Fix Supabase reference

class SignUpScreen extends StatefulWidget {
  @override
  _SignUpScreenState createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController ageController = TextEditingController();
  final TextEditingController genderController = TextEditingController();
  final TextEditingController bloodGroupController = TextEditingController();
  final TextEditingController heightController = TextEditingController();
  final TextEditingController weightController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController caretakerPhoneController = TextEditingController();
  final TextEditingController emergencyPhoneController = TextEditingController();

  Future<void> signupUser(BuildContext context) async {
  try {
    print("🔄 Signing up user...");

    final response = await supabase.auth.signUp(
      email: emailController.text.trim(),
      password: passwordController.text,
    );

    final user = response.user;

    if (user == null) {
      print("⚠️ Signup failed, user is null.");
      return;
    }

    print("🟢 User Created: ${user.id}");

    // Insert into the users table manually
    await supabase.from('users').insert({
      'id': user.id,
      'email': user.email,
    });

    print("✅ Inserted into users table");

    // Wait before inserting into `profiles`
    await Future.delayed(Duration(seconds: 2));

    final profileInsert = await supabase.from('profiles').insert({
      'id': user.id,
      'name': nameController.text,
      'age': int.tryParse(ageController.text) ?? 0,
      'gender': genderController.text,
      'blood_group': bloodGroupController.text,
      'height': double.tryParse(heightController.text) ?? 0.0,
      'weight': double.tryParse(weightController.text) ?? 0.0,
      'medical_conditions': [],
      'allergies': [],
      'phone': phoneController.text,
      'caretaker_phone': caretakerPhoneController.text,
      'emergency_phone': emergencyPhoneController.text,
    });

    print("✅ Profile Data Inserted: $profileInsert");

    // Check if the email is verified
    final userResponse = await supabase.auth.getUser();
    final isEmailVerified = userResponse.user?.userMetadata?['email_verified'] ?? false;

    if (!isEmailVerified) {
      // Show the email verification message
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text("Email Verification"),
            content: Text(
                "Please check your email to verify your account. Once verified, you can log in."),
            actions: <Widget>[
              TextButton(
                child: Text("OK"),
                onPressed: () {
                  Navigator.of(context).pop(); // Close the alert dialog
                  // Proceed to the verification screen after showing message
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EmailVerificationScreen(),
                    ),
                  );
                },
              ),
            ],
          );
        },
      );
    } else {
      // If email is verified, go to Dashboard
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => BottomNavBar()),
      );
    }

  } catch (error) {
    print("❌ Signup Error: $error");
  }
}



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Sign Up")),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(controller: emailController, decoration: InputDecoration(labelText: "Email")),
            TextField(controller: passwordController, decoration: InputDecoration(labelText: "Password"), obscureText: true),
            TextField(controller: nameController, decoration: InputDecoration(labelText: "Full Name")),
            TextField(controller: ageController, decoration: InputDecoration(labelText: "Age")),
            TextField(controller: genderController, decoration: InputDecoration(labelText: "Gender")),
            TextField(controller: bloodGroupController, decoration: InputDecoration(labelText: "Blood Group")),
            TextField(controller: heightController, decoration: InputDecoration(labelText: "Height")),
            TextField(controller: weightController, decoration: InputDecoration(labelText: "Weight")),
            TextField(controller: phoneController, decoration: InputDecoration(labelText: "Phone")),
            TextField(controller: caretakerPhoneController, decoration: InputDecoration(labelText: "Caretaker Phone")),
            TextField(controller: emergencyPhoneController, decoration: InputDecoration(labelText: "Emergency Phone")),
            SizedBox(height: 20),
            ElevatedButton(onPressed: () async {
                                                // Call the signupUser function and await its completion
                                                await signupUser(context);
                                              },
                                              child: Text("Sign Up"),
            ),
          ],
        ),
      ),
    );
  }
}
