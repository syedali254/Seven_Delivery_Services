import 'package:flutter/material.dart';
import '../../core/models/order_model.dart';
import '../../core/services/order_service.dart';
import '../../core/services/rider_service.dart';
import '../../core/services/auth_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/glass_card.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  final OrderService _orderService = OrderService();
  final RiderService _riderService = RiderService();
  final AuthService _authService = AuthService();
  
  UserRole _role = UserRole.unknown;
  String? _myRiderId;
  Set<String> _selectedOrderIds = {};

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final r = await _authService.getUserRole();
    final id = await _authService.getRiderId();
    setState(() {
      _role = r;
      _myRiderId = id;
    });
  }

  void _autoAssignSelected() async {
    final riders = await _riderService.getAllRiders();
    final activeRiders = riders.where((r) => r.status == 'available').toList();
    
    if (activeRiders.isEmpty) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No AVAILABLE riders found!'), backgroundColor: AppTheme.errorColor));
      return;
    }

    int riderIdx = 0;
    for (String id in _selectedOrderIds) {
      final bestRider = activeRiders[riderIdx % activeRiders.length];
      await _orderService.assignOrderToRider(id, bestRider.id);
      riderIdx++;
    }

    setState(() => _selectedOrderIds.clear());
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Orders Auto-Assigned Successfully!'), backgroundColor: AppTheme.successColor));
  }

  void _manualAssignSelected() async {
    final riders = await _riderService.getAllRiders();
    
    if (mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: AppTheme.darkColor,
          insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          title: const Text('Select Rider', style: TextStyle(color: Colors.white)),
          content: SizedBox(
            width: 300,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: riders.length,
              itemBuilder: (context, i) {
                final r = riders[i];
                return ListTile(
                  leading: CircleAvatar(backgroundColor: r.status == 'available' ? Colors.green : Colors.grey, radius: 5),
                  title: Text(r.name, style: const TextStyle(color: Colors.white)),
                  subtitle: Text(r.phone, style: const TextStyle(color: AppTheme.greyColor, fontSize: 10)),
                  onTap: () async {
                    for (String orderId in _selectedOrderIds) {
                      await _orderService.assignOrderToRider(orderId, r.id);
                    }
                    Navigator.pop(context);
                    setState(() => _selectedOrderIds.clear());
                  },
                );
              },
            ),
          ),
        ),
      );
    }
  }

  void _showAddOrderDialog() {
    final senderNameController = TextEditingController();
    final senderPhoneController = TextEditingController();
    final pickupAddressController = TextEditingController();
    final receiverNameController = TextEditingController();
    final receiverPhoneController = TextEditingController();
    final addressController = TextEditingController();
    final contentController = TextEditingController(text: 'General Goods');
    final codController = TextEditingController(text: '0');
    final weightController = TextEditingController(text: '1.0');
    final piecesController = TextEditingController(text: '1');
    String selectedCity = 'Dubai';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.darkColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        title: const Text('New Shipment', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDialogField(senderNameController, 'Sender Name', Icons.person_outline),
                const SizedBox(height: 12),
                _buildDialogField(senderPhoneController, 'Sender Phone', Icons.phone_android),
                const SizedBox(height: 12),
                _buildDialogField(pickupAddressController, 'Pickup Address', Icons.storefront),
                const SizedBox(height: 24),
                _buildDialogField(receiverNameController, 'Receiver Name', Icons.person),
                const SizedBox(height: 12),
                _buildDialogField(receiverPhoneController, 'Receiver Phone', Icons.phone),
                const SizedBox(height: 12),
                _buildDialogField(addressController, 'Delivery Address', Icons.home_outlined),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedCity,
                  dropdownColor: AppTheme.darkColor,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Delivery City',
                    labelStyle: const TextStyle(color: AppTheme.greyColor),
                    prefixIcon: const Icon(Icons.location_city, color: AppTheme.primaryColor),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  items: ['Dubai', 'Abu Dhabi', 'Sharjah', 'Ajman', 'Fujairah', 'RAK', 'UAQ']
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (v) => selectedCity = v!,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _buildDialogField(codController, 'COD (AED)', Icons.payments, isNumber: true)),
                    const SizedBox(width: 12),
                    Expanded(child: _buildDialogField(weightController, 'Weight (KG)', Icons.monitor_weight_outlined, isNumber: true)),
                  ],
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL')),
          ElevatedButton(
            onPressed: () async {
              final newOrder = OrderModel(
                id: 'SDS-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
                senderName: senderNameController.text,
                senderPhone: senderPhoneController.text,
                pickupAddress: pickupAddressController.text,
                receiverName: receiverNameController.text,
                receiverPhone: receiverPhoneController.text,
                address: addressController.text,
                city: selectedCity,
                content: contentController.text,
                weight: double.tryParse(weightController.text) ?? 1.0,
                pieces: int.tryParse(piecesController.text) ?? 1,
                codAmount: double.tryParse(codController.text) ?? 0,
                serviceFee: 25.0,
                status: OrderStatus.processing,
                verified: false,
              );
              await _orderService.createOrder(newOrder);
              if (mounted) Navigator.pop(context);
            },
            child: const Text('CREATE'),
          ),
        ],
      ),
    );
  }

  Widget _buildDialogField(TextEditingController controller, String label, IconData icon, {bool isNumber = false}) {
    return TextField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppTheme.greyColor),
        prefixIcon: Icon(icon, color: AppTheme.primaryColor),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 700;
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          Padding(
            padding: EdgeInsets.all(isMobile ? AppTheme.s16 : AppTheme.s24),
            child: Column(
              children: [
                _buildHeader(isMobile),
                const SizedBox(height: 16),
                Expanded(child: _buildShipmentList()),
              ],
            ),
          ),
          if (_selectedOrderIds.isNotEmpty) _buildBatchActionBar(isMobile),
        ],
      ),
    );
  }

  Widget _buildHeader(bool isMobile) {
    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Orders', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          const Text('Manage shipments', style: TextStyle(color: AppTheme.greyColor, fontSize: 13)),
          if (_role == UserRole.admin) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _showAddOrderDialog,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('New Shipment'),
              ),
            ),
          ],
        ],
      );
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text('Shipment Management', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
        if (_role == UserRole.admin)
          ElevatedButton.icon(
            onPressed: _showAddOrderDialog,
            icon: const Icon(Icons.add),
            label: const Text('New Shipment'),
          ),
      ],
    );
  }

  Widget _buildBatchActionBar(bool isMobile) {
    return Positioned(
      bottom: 20,
      left: isMobile ? 12 : 20,
      right: isMobile ? 12 : 20,
      child: GlassCard(
        color: AppTheme.darkColor,
        padding: EdgeInsets.symmetric(horizontal: isMobile ? 14 : 24, vertical: 12),
        child: isMobile 
          ? Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('${_selectedOrderIds.length} selected', style: const TextStyle(fontWeight: FontWeight.w600, color: AppTheme.primaryColor, fontSize: 13)),
                    IconButton(
                      onPressed: () => setState(() => _selectedOrderIds.clear()),
                      icon: const Icon(Icons.close, color: Colors.white38, size: 20),
                      constraints: const BoxConstraints(),
                      padding: EdgeInsets.zero,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextButton.icon(
                        onPressed: _autoAssignSelected,
                        icon: const Icon(Icons.bolt, color: Colors.yellow, size: 16),
                        label: const Text('Auto', style: TextStyle(color: Colors.white, fontSize: 12)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _manualAssignSelected,
                        style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 10)),
                        child: const Text('Assign', style: TextStyle(fontSize: 12)),
                      ),
                    ),
                  ],
                ),
              ],
            )
          : Row(
            children: [
              Text('${_selectedOrderIds.length} selected', style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryColor)),
              const Spacer(),
              TextButton.icon(onPressed: _autoAssignSelected, icon: const Icon(Icons.bolt, color: Colors.yellow), label: const Text('Auto Assign', style: TextStyle(color: Colors.white))),
              const SizedBox(width: 12),
              ElevatedButton.icon(onPressed: _manualAssignSelected, icon: const Icon(Icons.person_add), label: const Text('Manual Assign')),
              const SizedBox(width: 12),
              IconButton(onPressed: () => setState(() => _selectedOrderIds.clear()), icon: const Icon(Icons.close, color: Colors.white24)),
          ],
        ),
      ),
    );
  }

  Widget _buildShipmentList() {
    return StreamBuilder<List<OrderModel>>(
      stream: _orderService.getOrdersStream(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        var orders = snapshot.data!;
        if (_role == UserRole.rider) orders = orders.where((o) => o.riderId == _myRiderId).toList();

        return ListView.builder(
          itemCount: orders.length,
          itemBuilder: (context, i) {
            final order = orders[i];
            bool isSelected = _selectedOrderIds.contains(order.id);

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: GlassCard(
                padding: const EdgeInsets.all(8),
                child: CheckboxListTile(
                  value: isSelected,
                  onChanged: _role == UserRole.admin ? (val) {
                    setState(() {
                      if (val!) {
                        _selectedOrderIds.add(order.id);
                      } else {
                        _selectedOrderIds.remove(order.id);
                      }
                    });
                  } : null,
                  activeColor: AppTheme.primaryColor,
                  checkColor: Colors.white,
                  title: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(order.id, style: const TextStyle(fontWeight: FontWeight.bold)),
                            Text('To: ${order.receiverName} | ${order.city}', style: const TextStyle(color: AppTheme.greyColor, fontSize: 12)),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('${order.codAmount} AED', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                          Text(order.status.name.toUpperCase(), style: const TextStyle(fontSize: 10, color: AppTheme.greyColor)),
                        ],
                      ),
                    ],
                  ),
                  secondary: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: AppTheme.primaryColor.withOpacity(0.1), shape: BoxShape.circle),
                    child: const Icon(Icons.local_shipping, color: AppTheme.primaryColor, size: 20),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
