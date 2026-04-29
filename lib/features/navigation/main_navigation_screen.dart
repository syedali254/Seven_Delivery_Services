import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_theme.dart';
import '../../core/services/auth_service.dart';
import '../dashboard/dashboard_screen.dart';
import '../dashboard/rider_dashboard_screen.dart';
import '../orders/orders_screen.dart';
import '../rider_management/rider_management_screen.dart';
import '../rider_registration/rider_registration_screen.dart';
import '../profile/profile_screen.dart';
import '../qr_scanner/qr_scanner_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _selectedIndex = 0;
  final AuthService _authService = AuthService();
  
  UserRole _currentRole = UserRole.unknown;
  bool _isLoadingRole = true;

  @override
  void initState() {
    super.initState();
    _loadRole();
  }

  Future<void> _loadRole() async {
    setState(() => _isLoadingRole = true);
    final role = await _authService.getUserRole();
    if (mounted) {
      setState(() {
        _currentRole = role;
        _isLoadingRole = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingRole) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: AppTheme.primaryColor),
              SizedBox(height: 16),
              Text('Loading...', style: TextStyle(color: AppTheme.greyColor, fontSize: 13)),
            ],
          ),
        ),
      );
    }

    double width = MediaQuery.of(context).size.width;
    bool isMobile = width < 700;

    final Widget dashboard = _currentRole == UserRole.admin 
        ? const DashboardScreen() 
        : const RiderDashboardScreen();

    final List<Map<String, dynamic>> allDestinations = [
      {'screen': dashboard, 'icon': Icons.dashboard_rounded, 'label': 'Home', 'adminOnly': false},
      {'screen': const OrdersScreen(), 'icon': Icons.local_shipping_rounded, 'label': 'Orders', 'adminOnly': false},
      {'screen': const RiderManagementScreen(), 'icon': Icons.people_rounded, 'label': 'Fleet', 'adminOnly': true},
      {'screen': const QRScannerScreen(), 'icon': Icons.qr_code_scanner_rounded, 'label': 'Verify', 'adminOnly': false},
      {'screen': const RiderRegistrationScreen(), 'icon': Icons.person_add_rounded, 'label': 'Onboard', 'adminOnly': true},
      {'screen': const ProfileScreen(), 'icon': Icons.settings_rounded, 'label': 'Settings', 'adminOnly': true},
    ];

    final List<Map<String, dynamic>> allowedDestinations = allDestinations.where((d) {
      if (_currentRole == UserRole.admin) return true;
      return d['adminOnly'] == false;
    }).toList();

    if (_selectedIndex >= allowedDestinations.length) _selectedIndex = 0;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: _buildTopBar(isMobile),
      bottomNavigationBar: isMobile ? _buildBottomBar(allowedDestinations) : null,
      body: SafeArea(
        top: false, // AppBar already handles top
        child: Row(
          children: [
            if (!isMobile) _buildNavigationRail(width > 900, allowedDestinations),
            Expanded(child: allowedDestinations[_selectedIndex]['screen'] as Widget),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildTopBar(bool isMobile) {
    return AppBar(
      backgroundColor: AppTheme.darkColor,
      elevation: 0,
      systemOverlayStyle: SystemUiOverlayStyle.light,
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.delivery_dining, color: AppTheme.primaryColor, size: 18),
          ),
          const SizedBox(width: 10),
          Text(
            isMobile 
              ? (_currentRole == UserRole.admin ? 'SDS Admin' : 'SDS Rider')
              : (_currentRole == UserRole.admin ? 'Seven Logistics Admin' : 'Seven Rider Hub'), 
            style: const TextStyle(fontWeight: FontWeight.w700, color: Colors.white, fontSize: 15, letterSpacing: 0.3),
          ),
        ],
      ),
      actions: [
        IconButton(
          onPressed: _loadRole, 
          icon: const Icon(Icons.refresh_rounded, color: Colors.white54, size: 20),
          tooltip: 'Refresh',
        ),
        const SizedBox(width: 4),
      ],
    );
  }

  Widget _buildBottomBar(List<Map<String, dynamic>> items) {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (i) => setState(() => _selectedIndex = i),
        items: items.map((d) => BottomNavigationBarItem(
          icon: Padding(
            padding: const EdgeInsets.only(bottom: 2),
            child: Icon(d['icon'] as IconData),
          ),
          label: d['label'] as String,
        )).toList(),
      ),
    );
  }

  Widget _buildNavigationRail(bool extended, List<Map<String, dynamic>> items) {
    return NavigationRail(
      extended: extended,
      selectedIndex: _selectedIndex,
      onDestinationSelected: (i) => setState(() => _selectedIndex = i),
      backgroundColor: Colors.white,
      indicatorColor: AppTheme.primaryColor.withOpacity(0.1),
      destinations: items.map((d) => NavigationRailDestination(icon: Icon(d['icon'] as IconData), label: Text(d['label'] as String))).toList(),
    );
  }
}
