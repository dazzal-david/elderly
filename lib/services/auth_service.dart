import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_client.dart';

class AuthService {
  final supabase = SupabaseClientService.supabase;

  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required Map<String, dynamic> profileData,
  }) async {
    final response = await supabase.auth.signUp(email: email, password: password);
    if (response.user != null) {
      await supabase.from('profiles').upsert({
        'id': response.user!.id,
        ...profileData,
      });
    }
    return response;
  }

  Future<AuthResponse> signIn({required String email, required String password}) async {
    return await supabase.auth.signInWithPassword(email: email, password: password);
  }

  Future<void> signOut() async {
    await supabase.auth.signOut();
  }
}
