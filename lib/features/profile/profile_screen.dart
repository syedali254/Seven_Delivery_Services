import 'package:flutter/material.dart';
import '../../core/services/auth_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/glass_card.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthService _authService = AuthService();

  void _handleLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sign Out', style: TextStyle(color: AppTheme.errorColor)),
          ),
        ],
      ),
    );
    if (confirm == true) await _authService.signOut();
  }

  @override
  Widget build(BuildContext context) {
    final user = _authService.currentUser;
    final isMobile = MediaQuery.of(context).size.width < 700;
    
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        padding: EdgeInsets.all(isMobile ? 20 : 32),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              children: [
                const SizedBox(height: 24),
                // Avatar
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppTheme.primaryColor.withOpacity(0.3), width: 3),
                  ),
                  child: const CircleAvatar(
                    radius: 44,
                    backgroundColor: AppTheme.primaryColor,
                    child: Icon(Icons.person, size: 40, color: Colors.white),
                  ),
                ),
                const SizedBox(height: 20),
                Text(user?.email ?? 'Unknown User', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text('Administrator', style: TextStyle(color: AppTheme.primaryColor, fontSize: 12, fontWeight: FontWeight.w600)),
                ),
                const SizedBox(height: 32),
                
                // Account section
                GlassCard(
                  padding: const EdgeInsets.all(0),
                  child: Column(
                    children: [
                      _buildSettingsTile(Icons.email_outlined, 'Email', user?.email ?? '-'),
                      const Divider(height: 1, indent: 56),
                      _buildSettingsTile(Icons.shield_outlined, 'Role', 'Admin'),
                      const Divider(height: 1, indent: 56),
                      _buildSettingsTile(Icons.info_outline, 'Version', 'v3.0'),
                    ],
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Logout
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _handleLogout,
                    icon: const Icon(Icons.logout_rounded, size: 18),
                    label: const Text('Sign Out'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.errorColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
                
                const SizedBox(height: 32),
                Text('Seven Delivery Service', style: TextStyle(color: AppTheme.greyColor.withOpacity(0.5), fontSize: 11)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsTile(IconData icon, String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.greyColor, size: 20),
          const SizedBox(width: 16),
          Text(title, style: const TextStyle(color: AppTheme.greyColor, fontSize: 13)),
          const Spacer(),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13), overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}
