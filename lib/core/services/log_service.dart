import '../models/log_model.dart';
import 'supabase_service.dart';

class LogService {
  final _client = SupabaseService.client;

  Future<void> addLog(String action) async {
    try {
      await _client.from('logs').insert({
        'action': action,
        'timestamp': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('Logging failed: $e');
    }
  }

  Future<List<LogModel>> getRecentLogs() async {
    try {
      final data = await _client
          .from('logs')
          .select('*')
          .order('timestamp', ascending: false)
          .limit(50);
      return (data as List).map((json) => LogModel.fromJson(json)).toList();
    } catch (e) {
      rethrow;
    }
  }

  Stream<List<LogModel>> getLogsStream() {
    return _client
        .from('logs')
        .stream(primaryKey: ['id'])
        .order('timestamp', ascending: false)
        .limit(20)
        .map((data) => data.map((json) => LogModel.fromJson(json)).toList());
  }
}
