import 'dart:math';
import 'package:flutter/material.dart';
import '../../core/services/rider_service.dart';
import '../../core/services/log_service.dart';
import '../../core/models/rider_model.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/glass_card.dart';

class RiderRegistrationScreen extends StatefulWidget {
  const RiderRegistrationScreen({super.key});

  @override
  State<RiderRegistrationScreen> createState() => _RiderRegistrationScreenState();
}

class _RiderRegistrationScreenState extends State<RiderRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _riderService = RiderService();
  final _logService = LogService();
  
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController(); // NEW
  final _passwordController = TextEditingController(); // NEW
  final _passportController = TextEditingController();
  final _emiratesController = TextEditingController();
  final _addressController = TextEditingController();
  
  bool _isLoading = false;

  String _generateUuid() {
    final Random random = Random();
    final List<int> values = List<int>.generate(16, (i) => random.nextInt(256));
    values[6] = (values[6] & 0x0f) | 0x40;
    values[8] = (values[8] & 0x3f) | 0x80;
    final List<String> hex = values.map((i) => i.toRadixString(16).padLeft(2, '0')).toList();
    return '${hex[0]}${hex[1]}${hex[2]}${hex[3]}-${hex[4]}${hex[5]}-${hex[6]}${hex[7]}-${hex[8]}${hex[9]}-${hex[10]}${hex[11]}${hex[12]}${hex[13]}${hex[14]}${hex[15]}';
  }

  void _registerRider() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    
    try {
      final String riderId = _generateUuid();
      
      final newRider = RiderModel(
        id: riderId,
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        email: _emailController.text.trim(), // NEW
        password: _passwordController.text.trim(), // NEW
        passportNumber: _passportController.text.trim(),
        emiratesId: _emiratesController.text.trim(),
        address: _addressController.text.trim(),
        status: 'available', 
      );

      final authError = await _riderService.createRider(newRider);
      await _logService.addLog('Admin Registered New Rider Account: ${newRider.email}');

      if (mounted) {
        if (authError == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Rider registered successfully! They can now log in.'), backgroundColor: AppTheme.successColor),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Rider saved but login account issue: $authError'),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 5),
            ),
          );
        }
        _formKey.currentState!.reset();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Registration Failed: $e'), backgroundColor: AppTheme.errorColor),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 700;
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        padding: EdgeInsets.all(isMobile ? 16 : 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Register New Rider', style: TextStyle(fontSize: isMobile ? 22 : 28, fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            const Text('Add rider credentials and documents', style: TextStyle(color: AppTheme.greyColor, fontSize: 13)),
            const SizedBox(height: 24),
            
            GlassCard(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    const Text('LOGIN CREDENTIALS', style: TextStyle(fontWeight: FontWeight.w600, color: AppTheme.primaryColor, fontSize: 11, letterSpacing: 0.5)),
                    const Divider(),
                    _buildTextField(_emailController, 'Rider Login Email', Icons.alternate_email),
                    const SizedBox(height: 12),
                    _buildTextField(_passwordController, 'Rider Login Password', Icons.lock_outline, isPassword: true),
                    const SizedBox(height: 24),
                    
                    const Text('OFFICIAL DOCUMENTATION', style: TextStyle(fontWeight: FontWeight.w600, color: AppTheme.primaryColor, fontSize: 11, letterSpacing: 0.5)),
                    const Divider(),
                    _buildTextField(_nameController, 'Full Name', Icons.person),
                    const SizedBox(height: 12),
                    _buildTextField(_phoneController, 'Phone Number', Icons.phone),
                    const SizedBox(height: 12),
                    _buildTextField(_passportController, 'Passport Number', Icons.badge),
                    const SizedBox(height: 12),
                    _buildTextField(_emiratesController, 'Emirates ID', Icons.perm_identity),
                    const SizedBox(height: 12),
                    _buildTextField(_addressController, 'Resident Address', Icons.home),
                    const SizedBox(height: 32),
                    
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _registerRider,
                        style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor, foregroundColor: Colors.white),
                        child: _isLoading 
                          ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                          : const Text('Register Rider', style: TextStyle(fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, {bool isPassword = false}) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppTheme.primaryColor),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      validator: (v) => v!.isEmpty ? 'Field required' : null,
    );
  }
}
