import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  // TODO: Replace with your actual Supabase URL and Anon Key
  static const String supabaseUrl = 'https://lpenvkxvtpdbrzrmhrhg.supabase.co';
  static const String supabaseAnonKey = 'sb_publishable_y0cDWZ6idLhcl78_a4F00Q_datu00Z9';

  static Future<void> initialize() async {
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
    );
  }

  static SupabaseClient get client => Supabase.instance.client;
}
