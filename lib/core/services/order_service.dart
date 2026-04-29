import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:seven_delivery_service/core/models/order_model.dart';
import 'package:seven_delivery_service/core/services/supabase_service.dart';
import 'package:seven_delivery_service/core/services/log_service.dart';

class OrderService {
  final LogService _logService = LogService();
  final SupabaseClient _client = SupabaseService.client;

  Stream<List<OrderModel>> getOrdersStream() {
    return _client
        .from('orders')
        .stream(primaryKey: ['id'])
        .order('id', ascending: false)
        .map((data) => data.map((json) => OrderModel.fromJson(json)).toList());
  }

  Future<void> updateOrderStatus(String orderId, OrderStatus newStatus, {String? riderId}) async {
    final String cleanId = orderId.trim();
    final Map<String, dynamic> updates = {'status': newStatus.name};
    if (riderId != null) updates['rider_id'] = riderId;
    if (newStatus == OrderStatus.inTransit) updates['verified'] = true;

    try {
      // 1. First, try the most direct match
      final response = await _client
          .from('orders')
          .update(updates)
          .eq('id', cleanId)
          .select();

      if ((response as List).isNotEmpty) {
        await _logService.addLog('Order $cleanId moved to ${newStatus.name.toUpperCase()}');
        return;
      }

      // 2. If that fails, try Case-Insensitive fallback
      final response2 = await _client
          .from('orders')
          .update(updates)
          .ilike('id', cleanId)
          .select();

      if ((response2 as List).isNotEmpty) {
        await _logService.addLog('Order $cleanId moved to ${newStatus.name.toUpperCase()}');
        return;
      }

      // 3. If BOTH fail, it's either an RLS issue or the ID really is missing
      throw 'Order ID "$cleanId" not found or Update Permission Denied. Check RLS settings.';
      
    } on PostgrestException catch (e) {
      // THIS WILL TELL US THE REAL PROBLEM (e.g. Permission Denied)
      throw 'SUPABASE ERROR (${e.code}): ${e.message}';
    } catch (e) {
      rethrow;
    }
  }

  Future<void> assignOrderToRider(String orderId, String riderId) async {
    await updateOrderStatus(orderId, OrderStatus.assigned, riderId: riderId);
  }

  Future<String?> assignBestRider(String orderId) async {
    try {
      final ridersData = await _client.from('riders').select('id, name, status');
      if (ridersData == null || (ridersData as List).isEmpty) throw 'No riders found.';
      final List activeRiders = (ridersData as List).where((r) {
        final String s = (r['status'] ?? '').toString().toLowerCase();
        return s == 'active' || s == 'available' || s == 'online';
      }).toList();
      if (activeRiders.isEmpty) throw 'No active riders.';
      final ordersData = await _client.from('orders').select('rider_id').not('status', 'in', '("${OrderStatus.delivered.name}","${OrderStatus.cancelled.name}")').not('rider_id', 'is', null);
      Map<String, int> workload = {};
      for (var r in activeRiders) workload[r['id']] = 0;
      for (var o in (ordersData as List)) {
        String rid = o['rider_id'];
        if (workload.containsKey(rid)) workload[rid] = workload[rid]! + 1;
      }
      String bestRiderId = workload.entries.reduce((a, b) => a.value < b.value ? a : b).key;
      String bestRiderName = activeRiders.firstWhere((r) => r['id'] == bestRiderId)['name'];
      await updateOrderStatus(orderId, OrderStatus.assigned, riderId: bestRiderId);
      return bestRiderName;
    } catch (e) {
      print('ASSIGN_ERROR: $e');
      rethrow;
    }
  }

  Future<void> assignOrdersToRider(List<String> orderIds, String riderId) async {
    for (var id in orderIds) {
      await updateOrderStatus(id, OrderStatus.assigned, riderId: riderId);
    }
  }

  Future<void> createOrder(OrderModel order) async {
    await _client.from('orders').insert(order.toJson());
  }
}
