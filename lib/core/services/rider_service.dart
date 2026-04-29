import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:seven_delivery_service/core/models/rider_model.dart';
import 'package:seven_delivery_service/core/services/supabase_service.dart';
import 'package:seven_delivery_service/core/config/secrets.dart'; 

class RiderService {
  final SupabaseClient _client = SupabaseService.client;

  Stream<List<RiderModel>> getRidersStream() {
    return _client
        .from('riders')
        .stream(primaryKey: ['id'])
        .map((data) => data.map((json) => RiderModel.fromJson(json)).toList());
  }

  /// Creates rider in DB + Supabase Auth account.
  /// Returns null on success, or a warning string.
  Future<String?> createRider(RiderModel rider) async {
    // 1. Save to DB
    await _client.from('riders').insert(rider.toJson());

    if (rider.email == null || rider.email!.isEmpty ||
        rider.password == null || rider.password!.isEmpty) {
      return 'No credentials provided — saved to database only.';
    }

    // 2. Create auth account
    //    Web → signUp (service_role key is blocked in browsers)
    //    Mobile/Desktop → admin API (auto-confirms email)
    if (!kIsWeb) {
      final adminResult = await _createViaAdminApi(rider);
      if (adminResult == null) return null;
      // If admin API failed on mobile, fall through to signUp
    }

    return await _createViaSignUp(rider);
  }

  /// Admin REST API — only works on mobile/desktop (not web)
  Future<String?> _createViaAdminApi(RiderModel rider) async {
    final String serviceKey = AppSecrets.supabaseServiceKey;
    if (serviceKey == 'PASTE_YOUR_SERVICE_ROLE_KEY_HERE') return 'Key not set';

    try {
      final response = await http.post(
        Uri.parse('${SupabaseService.supabaseUrl}/auth/v1/admin/users'),
        headers: {
          'Content-Type': 'application/json',
          'apikey': serviceKey,
          'Authorization': 'Bearer $serviceKey',
        },
        body: jsonEncode({
          'email': rider.email,
          'password': rider.password,
          'email_confirm': true,
          'user_metadata': {'role': 'rider', 'name': rider.name},
        }),
      );
      if (response.statusCode == 200 || response.statusCode == 201) return null;
      return 'Admin API: HTTP ${response.statusCode}';
    } catch (e) {
      return e.toString().split('\n').first;
    }
  }

  /// SignUp via the already-initialized Supabase client (works on web)
  /// Saves + restores the admin session so admin stays logged in.
  Future<String?> _createViaSignUp(RiderModel rider) async {
    final supabase = Supabase.instance.client;
    final currentSession = supabase.auth.currentSession;
    final String? adminAccessToken = currentSession?.accessToken;
    final String? adminRefreshToken = currentSession?.refreshToken;

    try {
      final res = await supabase.auth.signUp(
        email: rider.email!,
        password: rider.password!,
        data: {'role': 'rider', 'name': rider.name},
      );

      // Restore admin session using saved tokens
      if (adminAccessToken != null && adminRefreshToken != null) {
        await supabase.auth.setSession(adminRefreshToken);
      }

      if (res.user != null) return null; // success
      return 'Could not create login account.';
    } catch (e) {
      // Always restore admin session
      if (adminAccessToken != null && adminRefreshToken != null) {
        try { await supabase.auth.setSession(adminRefreshToken); } catch (_) {}
      }
      return 'Auth failed: ${e.toString().split('\n').first}';
    }
  }

  Future<List<RiderModel>> getAllRiders() async {
    final response = await _client.from('riders').select();
    return (response as List).map((json) => RiderModel.fromJson(json)).toList();
  }

  Future<void> updateRiderStatus(String id, String status) async {
    await _client.from('riders').update({'status': status}).eq('id', id);
  }

  Future<void> deleteRider(String id) async {
    await _client.from('riders').delete().eq('id', id);
  }
}
