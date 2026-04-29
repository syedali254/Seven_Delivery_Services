import 'package:flutter/material.dart';
import 'package:seven_delivery_service/core/models/order_model.dart';
import 'package:seven_delivery_service/core/models/rider_model.dart';
import 'package:seven_delivery_service/core/services/order_service.dart';
import 'package:seven_delivery_service/core/services/rider_service.dart';
import 'package:seven_delivery_service/core/services/auth_service.dart';
import 'package:seven_delivery_service/core/theme/app_theme.dart';
import 'package:seven_delivery_service/core/widgets/glass_card.dart';

class RiderDashboardScreen extends StatefulWidget {
  const RiderDashboardScreen({super.key});

  @override
  State<RiderDashboardScreen> createState() => _RiderDashboardScreenState();
}

class _RiderDashboardScreenState extends State<RiderDashboardScreen> {
  final OrderService _orderService = OrderService();
  final RiderService _riderService = RiderService();
  final AuthService _authService = AuthService();
  
  String? _myRiderId;
  String? _myRiderName;
  String _dutyStatus = 'available';
  bool _isToggling = false;
  bool _isInitialLoading = true;
  String _loadError = '';

  @override
  void initState() {
    super.initState();
    _loadMyData();
  }

  Future<void> _loadMyData() async {
    try {
      final id = await _authService.getRiderId();
      if (id != null) {
        final List<RiderModel> riders = await _riderService.getAllRiders();
        final RiderModel me = riders.firstWhere((r) => r.id == id);
        if (mounted) {
          setState(() {
            _myRiderId = id;
            _myRiderName = me.name;
            _dutyStatus = me.status;
            _isInitialLoading = false;
            _loadError = '';
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _isInitialLoading = false;
            _loadError = 'profile_not_found';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isInitialLoading = false;
          _loadError = 'connection_error';
        });
      }
    }
  }

  void _handleLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Sign Out', style: TextStyle(color: AppTheme.errorColor))),
        ],
      ),
    );
    if (confirm == true) await _authService.signOut();
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitialLoading) {
      return const Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: AppTheme.primaryColor),
              SizedBox(height: 16),
              Text('Loading your dashboard...', style: TextStyle(color: AppTheme.greyColor, fontSize: 13)),
            ],
          ),
        ),
      );
    }
    bool isOnline = _dutyStatus == 'available';
    final isMobile = MediaQuery.of(context).size.width < 700;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: RefreshIndicator(
        color: AppTheme.primaryColor,
        onRefresh: _loadMyData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.all(isMobile ? AppTheme.s16 : AppTheme.s24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_loadError.isNotEmpty) 
                _buildErrorCard(),

              _buildWelcomeHeader(isOnline),
              const SizedBox(height: 20),
              _buildPersonalStats(),
              const SizedBox(height: 28),
              const Text('Active Deliveries', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppTheme.darkColor)),
              const SizedBox(height: 12),
              _buildMyOrdersList(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorCard() {
    final isProfileError = _loadError == 'profile_not_found';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Row(
        children: [
          Icon(isProfileError ? Icons.person_off_outlined : Icons.wifi_off_rounded, color: Colors.orange.shade700, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              isProfileError 
                ? 'Unable to load your profile. Contact your admin if this persists.'
                : 'Connection issue. Pull down to retry.',
              style: TextStyle(color: Colors.orange.shade800, fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeHeader(bool isOnline) {
    final displayName = _myRiderName ?? _authService.currentUser?.email?.split('@')[0] ?? 'Rider';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Welcome back,', style: TextStyle(color: AppTheme.greyColor, fontSize: 14)),
                  const SizedBox(height: 2),
                  Text(displayName, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800), overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(30),
                    onTap: () async {
                      if (_myRiderId == null || _isToggling) return;
                      setState(() => _isToggling = true);
                      String nextStatus = _dutyStatus == 'available' ? 'unavailable' : 'available';
                      await _riderService.updateRiderStatus(_myRiderId!, nextStatus);
                      if (mounted) setState(() { _dutyStatus = nextStatus; _isToggling = false; });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: _isToggling ? AppTheme.greyColor : (isOnline ? AppTheme.successColor : AppTheme.errorColor),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_isToggling) const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          else Icon(isOnline ? Icons.bolt : Icons.power_settings_new, color: Colors.white, size: 15),
                          const SizedBox(width: 6),
                          Text(isOnline ? 'On Duty' : 'Off Duty', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 12)),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _handleLogout,
                  icon: const Icon(Icons.logout_rounded, color: AppTheme.greyColor, size: 20),
                  tooltip: 'Sign Out',
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPersonalStats() {
    return StreamBuilder<List<OrderModel>>(
      stream: _orderService.getOrdersStream(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const LinearProgressIndicator();
        
        // Match the ID exactly (Case-insensitive)
        final myOrders = snapshot.data!.where((o) => o.riderId?.toLowerCase() == _myRiderId?.toLowerCase()).toList();
        final delivered = myOrders.where((o) => o.status == OrderStatus.delivered).toList();
        double totalCod = 0;
        for (var o in delivered) totalCod += o.codAmount;
        
        return Row(
          children: [
            Expanded(child: _buildStatCard('Delivered', delivered.length.toString(), Icons.task_alt, AppTheme.successColor)),
            const SizedBox(width: 12),
            Expanded(child: _buildStatCard('COD Collected', '${totalCod.toInt()} AED', Icons.payments, Colors.orange)),
          ],
        );
      },
    );
  }

  Widget _buildStatCard(String title, String val, IconData icon, Color color) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 12),
          Text(val, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
          Text(title, style: const TextStyle(color: AppTheme.greyColor, fontSize: 10, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildMyOrdersList() {
    return StreamBuilder<List<OrderModel>>(
      stream: _orderService.getOrdersStream(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        
        // Match the ID exactly (Case-insensitive)
        final myOrders = snapshot.data!.where((o) => o.riderId?.toLowerCase() == _myRiderId?.toLowerCase() && o.status != OrderStatus.delivered).toList();

        if (myOrders.isEmpty) {
          return const GlassCard(padding: EdgeInsets.all(40), child: Center(child: Text('No active parcels assigned to you.', style: TextStyle(color: AppTheme.greyColor))));
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: myOrders.length,
          itemBuilder: (context, i) {
            final order = myOrders[i];
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: GlassCard(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: AppTheme.primaryColor.withOpacity(0.1), shape: BoxShape.circle), child: const Icon(Icons.inventory_2, color: AppTheme.primaryColor, size: 20)),
                    const SizedBox(width: 16),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(order.id, style: const TextStyle(fontWeight: FontWeight.bold)), Text('To: ${order.receiverName} | ${order.city}', style: const TextStyle(color: AppTheme.greyColor, fontSize: 11))])),
                    Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: AppTheme.primaryColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)), child: Text(order.status.name.toUpperCase(), style: const TextStyle(color: AppTheme.primaryColor, fontSize: 9, fontWeight: FontWeight.bold))),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
