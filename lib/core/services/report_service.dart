import '../../core/models/order_model.dart';
import '../../core/services/supabase_service.dart';

class ReportService {
  // FEATURE 7: REPORT GENERATOR DATA
  Future<Map<String, dynamic>> getAnalyticsData() async {
    final orders = await SupabaseService.client.from('orders').select();
    final riders = await SupabaseService.client.from('riders').select();

    final List<OrderModel> orderModels = orders.map((o) => OrderModel.fromJson(o)).toList();

    int total = orderModels.length;
    int delivered = orderModels.where((o) => o.status == OrderStatus.delivered).length;
    int cancelled = orderModels.where((o) => o.status == OrderStatus.cancelled).length;
    int inTransit = orderModels.where((o) => o.status == OrderStatus.inTransit).length;

    Map<String, int> performance = {};
    for (var o in orderModels) {
      if (o.status == OrderStatus.delivered && o.riderId != null) {
        performance[o.riderId!] = (performance[o.riderId!] ?? 0) + 1;
      }
    }

    return {
      'total': total,
      'delivered': delivered,
      'cancelled': cancelled,
      'inTransit': inTransit,
      'performance': performance,
      'riders': riders,
    };
  }

  // FEATURE 10: SYSTEM HEALTH METRICS (Updated for Vocabulary)
  Future<Map<String, dynamic>> getSystemHealth() async {
    final riders = await SupabaseService.client.from('riders').select('status');
    final orders = await SupabaseService.client.from('orders').select('status');

    // Support available, online, active
    int activeRidersCount = (riders as List).where((r) {
      final s = (r['status'] ?? '').toString().toLowerCase();
      return s == 'active' || s == 'available' || s == 'online';
    }).length;

    int ordersInTransit = (orders as List).where((o) => o['status'] == OrderStatus.inTransit.name).length;
    int failedDeliveries = (orders as List).where((o) => o['status'] == OrderStatus.cancelled.name).length;

    String status = 'healthy';
    if (activeRidersCount == 0) {
      status = 'issue';
    } else if (failedDeliveries > (orders.length * 0.1)) {
      status = 'warning';
    }

    return {
      'activeRiders': activeRidersCount,
      'ordersInTransit': ordersInTransit,
      'failedDeliveries': failedDeliveries,
      'status': status,
    };
  }
}
