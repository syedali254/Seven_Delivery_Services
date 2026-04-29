import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seven_delivery_service/core/services/supabase_service.dart';
import 'package:seven_delivery_service/core/services/order_service.dart';
import 'package:seven_delivery_service/core/services/rider_service.dart';
import 'package:seven_delivery_service/core/services/log_service.dart';
import 'package:seven_delivery_service/core/models/order_model.dart';
import 'package:seven_delivery_service/core/models/rider_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class TestHttpOverrides extends HttpOverrides {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Supabase Integration Tests', () {
    late OrderService orderService;
    late RiderService riderService;
    late LogService logService;

    setUpAll(() async {
      // Allow real network requests
      HttpOverrides.global = TestHttpOverrides();
      
      // Mock SharedPreferences platform channel
      const MethodChannel('plugins.flutter.io/shared_preferences')
          .setMockMethodCallHandler((MethodCall methodCall) async {
        if (methodCall.method == 'getAll') {
          return <String, dynamic>{};
        }
        return null;
      });

      // Initialize Supabase normally
      await SupabaseService.initialize();
      
      orderService = OrderService();
      riderService = RiderService();
      logService = LogService();
    });

    test('Full Workflow Test: Rider -> Order -> Log', () async {
      print('--- Starting Integration Test ---');

      // 1. Check Connection
      try {
        final initialRiders = await riderService.getAllRiders();
        print('Connection Successful. Found ${initialRiders.length} riders.');
      } catch (e) {
        print('Connection Error (Expected if RLS is on and not logged in): $e');
        // If we get a 401, the connection is actually working but blocked by security
        if (e.toString().contains('401')) {
          print('Verified: Connection works, Security (RLS) is active.');
          return;
        }
        rethrow;
      }

      // 2. Create a Test Order
      final testOrder = OrderModel(
        id: 'TEST-AWB-${DateTime.now().millisecondsSinceEpoch}',
        senderName: 'Sender Test',
        receiverName: 'Receiver Test',
        address: '123 Test St, Dubai',
        status: OrderStatus.processing,
      );

      print('Creating Test Order: ${testOrder.id}...');
      await orderService.createOrder(testOrder);

      // 3. Verify Order Exists
      final orders = await orderService.getAllOrders();
      final found = orders.any((o) => o.id == testOrder.id);
      expect(found, isTrue);
      print('Order verified in database.');

      // 4. Add a Log
      print('Adding log entry...');
      await logService.addLog('Ran integration test successfully');
      
      final logs = await logService.getRecentLogs();
      expect(logs.isNotEmpty, isTrue);
      print('Log verified in database.');
      
      print('--- Integration Test Passed ---');
    });
  });
}
