import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:seven_delivery_service/core/services/supabase_service.dart';

enum UserRole { admin, rider, unknown }

class AuthService {
  final SupabaseClient _client = SupabaseService.client;

  User? get currentUser => _client.auth.currentUser;
  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  Future<AuthResponse> signIn(String email, String password) async {
    return await _client.auth.signInWithPassword(email: email, password: password);
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  Future<UserRole> getUserRole() async {
    final user = currentUser;
    if (user == null) return UserRole.unknown;

    final String cleanEmail = user.email!.trim().toLowerCase();
    
    if (cleanEmail == 'p230556@pwr.nu.edu.pk') {
      return UserRole.admin;
    }

    try {
      // 1. Check Admins Table
      final adminData = await _client
          .from('admins')
          .select('role') 
          .ilike('Email', cleanEmail) 
          .maybeSingle();

      if (adminData != null) {
        final String r = adminData['role']?.toString().toLowerCase().trim() ?? 'rider';
        return r == 'admin' ? UserRole.admin : UserRole.rider;
      }

      // 2. Check Riders Table (Trying BOTH lowercase and Capital column names)
      dynamic riderData;
      try {
        riderData = await _client.from('riders').select('id').ilike('email', cleanEmail).maybeSingle();
      } catch (_) {
        riderData = await _client.from('riders').select('id').ilike('Email', cleanEmail).maybeSingle();
      }

      return riderData != null ? UserRole.rider : UserRole.unknown;
    } catch (e) {
      return UserRole.rider; 
    }
  }

  // LINKING: Find Rider ID (Trying both column variations)
  Future<String?> getRiderId() async {
    final user = currentUser;
    if (user == null) return null;
    final String cleanEmail = user.email!.trim().toLowerCase();

    try {
      // Try lowercase column first
      final data = await _client
          .from('riders')
          .select('id')
          .ilike('email', cleanEmail)
          .maybeSingle();
      
      if (data != null) return data['id'];

      // Try Capital column as fallback
      final dataCap = await _client
          .from('riders')
          .select('id')
          .ilike('Email', cleanEmail)
          .maybeSingle();
      
      return dataCap?['id'];
    } catch (e) {
      print('GET_RIDER_ID_ERROR: $e');
      return null;
    }
  }
}
