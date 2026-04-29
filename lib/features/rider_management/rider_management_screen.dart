import 'package:flutter/material.dart';
import '../../core/models/rider_model.dart';
import '../../core/services/rider_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/glass_card.dart';

class RiderManagementScreen extends StatefulWidget {
  const RiderManagementScreen({super.key});

  @override
  State<RiderManagementScreen> createState() => _RiderManagementScreenState();
}

class _RiderManagementScreenState extends State<RiderManagementScreen> {
  final RiderService _riderService = RiderService();
  final TextEditingController _searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 700;
    return Padding(
      padding: EdgeInsets.all(isMobile ? 16.0 : 32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(isMobile),
          const SizedBox(height: 20),
          _buildSearchField(),
          const SizedBox(height: 16),
          Expanded(child: _buildRiderContent(isMobile)),
        ],
      ),
    );
  }

  Widget _buildHeader(bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Fleet Management', style: TextStyle(fontSize: isMobile ? 22 : 32, fontWeight: FontWeight.w800)),
        const SizedBox(height: 2),
        const Text('Monitor and manage your delivery fleet', style: TextStyle(color: AppTheme.greyColor, fontSize: 13)),
      ],
    );
  }

  Widget _buildSearchField() {
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: TextField(
        controller: _searchController,
        onChanged: (v) => setState(() {}),
        decoration: const InputDecoration(
          hintText: 'Search by name or phone...',
          prefixIcon: Icon(Icons.search, color: AppTheme.greyColor),
          border: InputBorder.none,
          filled: false,
        ),
      ),
    );
  }

  Widget _buildRiderContent(bool isMobile) {
    return StreamBuilder<List<RiderModel>>(
      stream: _riderService.getRidersStream(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return Center(child: Text('Unable to load riders', style: TextStyle(color: AppTheme.greyColor)));
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor));
        
        var riders = snapshot.data!;
        if (_searchController.text.isNotEmpty) {
          final query = _searchController.text.toLowerCase();
          riders = riders.where((r) => r.name.toLowerCase().contains(query) || r.phone.contains(query)).toList();
        }

        if (riders.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.people_outline, size: 48, color: AppTheme.greyColor.withOpacity(0.5)),
                const SizedBox(height: 12),
                const Text('No riders found', style: TextStyle(color: AppTheme.greyColor, fontSize: 15)),
              ],
            ),
          );
        }

        if (isMobile) return _buildRiderCardList(riders);
        return _buildRiderTable(riders);
      },
    );
  }

  Widget _buildRiderCardList(List<RiderModel> riders) {
    return ListView.separated(
      itemCount: riders.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, i) {
        final rider = riders[i];
        return GlassCard(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                    child: Text(rider.name.isNotEmpty ? rider.name[0].toUpperCase() : '?', style: const TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.w700)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(rider.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                        const SizedBox(height: 2),
                        Text(rider.phone, style: const TextStyle(color: AppTheme.greyColor, fontSize: 12)),
                      ],
                    ),
                  ),
                  _buildStatusChip(rider.status),
                ],
              ),
              const SizedBox(height: 10),
              const Divider(height: 1),
              const SizedBox(height: 10),
              Row(
                children: [
                  _infoTag(Icons.badge_outlined, rider.passportNumber),
                  const SizedBox(width: 16),
                  _infoTag(Icons.perm_identity, rider.emiratesId),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 18, color: AppTheme.greyColor),
                    onPressed: () => _editRider(rider),
                    constraints: const BoxConstraints(),
                    padding: const EdgeInsets.all(4),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: Icon(Icons.delete_outline, size: 18, color: AppTheme.errorColor.withOpacity(0.7)),
                    onPressed: () => _confirmDelete(rider),
                    constraints: const BoxConstraints(),
                    padding: const EdgeInsets.all(4),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _infoTag(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: AppTheme.greyColor),
        const SizedBox(width: 4),
        Text(text, style: const TextStyle(fontSize: 11, color: AppTheme.greyColor)),
      ],
    );
  }

  Widget _buildRiderTable(List<RiderModel> riders) {
    return GlassCard(
      padding: EdgeInsets.zero,
      child: SingleChildScrollView(
        child: SizedBox(
          width: double.infinity,
          child: DataTable(
            headingTextStyle: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.darkColor),
            columns: const [
              DataColumn(label: Text('Name')),
              DataColumn(label: Text('Phone')),
              DataColumn(label: Text('Passport')),
              DataColumn(label: Text('Emirates ID')),
              DataColumn(label: Text('Status')),
              DataColumn(label: Text('Actions')),
            ],
            rows: riders.map((rider) => DataRow(
              cells: [
                DataCell(Text(rider.name, style: const TextStyle(fontWeight: FontWeight.bold))),
                DataCell(Text(rider.phone)),
                DataCell(Text(rider.passportNumber)),
                DataCell(Text(rider.emiratesId)),
                DataCell(_buildStatusChip(rider.status)),
                DataCell(Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      onPressed: () => _editRider(rider),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red, size: 18),
                      onPressed: () => _confirmDelete(rider),
                    ),
                  ],
                )),
              ],
            )).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    final statusLower = status.toLowerCase();
    Color color = Colors.grey;
    if (statusLower == 'available') color = Colors.green;
    if (statusLower == 'busy') color = Colors.orange;
    if (statusLower == 'offline' || statusLower == 'unavailable') color = Colors.red;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
      child: Text(status.toUpperCase(), style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }

  void _editRider(RiderModel rider) {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Edit functionality triggered')));
  }

  void _confirmDelete(RiderModel rider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Rider?'),
        content: Text('Are you sure you want to remove ${rider.name} from the fleet?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _riderService.deleteRider(rider.id);
            }, 
            child: const Text('Remove', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
