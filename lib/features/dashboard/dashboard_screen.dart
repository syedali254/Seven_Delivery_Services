import 'package:flutter/material.dart';
import '../../core/models/log_model.dart';
import '../../core/models/order_model.dart';
import '../../core/services/log_service.dart';
import '../../core/services/order_service.dart';
import '../../core/services/report_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/glass_card.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final OrderService _orderService = OrderService();
  final LogService _logService = LogService();
  final ReportService _reportService = ReportService();

  @override
  Widget build(BuildContext context) {
    bool isMobile = MediaQuery.of(context).size.width < 700;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        padding: EdgeInsets.all(isMobile ? AppTheme.s16 : AppTheme.s32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(isMobile),
            const SizedBox(height: AppTheme.s24),
            _buildHealthMonitor(isMobile), // FEATURE 10
            const SizedBox(height: AppTheme.s24),
            _buildFinancialRow(isMobile),
            const SizedBox(height: AppTheme.s24),
            _buildKPISection(isMobile),
            const SizedBox(height: AppTheme.s24),
            if (isMobile) ...[
              _buildPerformanceSection(),
              const SizedBox(height: AppTheme.s24),
              _buildActivitySection(),
            ] else 
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 3, child: _buildPerformanceSection()),
                  const SizedBox(width: AppTheme.s32),
                  Expanded(flex: 2, child: _buildActivitySection()),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool isMobile) {
    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Operations Hub', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
          const SizedBox(height: 2),
          const Text('Real-time overview', style: TextStyle(color: AppTheme.greyColor, fontSize: 13)),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _showReportModal,
              icon: const Icon(Icons.analytics_outlined, size: 18),
              label: const Text('Generate Report'),
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.darkColor, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 12)),
            ),
          ),
        ],
      );
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Operations Hub', style: Theme.of(context).textTheme.displayLarge),
            const Text('Real-time overview', style: TextStyle(color: AppTheme.greyColor, fontSize: 16)),
          ],
        ),
        ElevatedButton.icon(
          onPressed: _showReportModal,
          icon: const Icon(Icons.analytics_outlined),
          label: const Text('Generate Report'),
          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.darkColor, foregroundColor: Colors.white),
        ),
      ],
    );
  }

  Widget _buildHealthMonitor(bool isMobile) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _reportService.getSystemHealth(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const LinearProgressIndicator();
        final health = snapshot.data!;
        Color statusColor = health['status'] == 'healthy' ? AppTheme.successColor : (health['status'] == 'warning' ? Colors.amber : AppTheme.errorColor);

        return GlassCard(
          padding: EdgeInsets.symmetric(horizontal: isMobile ? 14 : 20, vertical: 12),
          child: isMobile 
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 10, height: 10,
                        decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle, boxShadow: [BoxShadow(color: statusColor.withOpacity(0.5), blurRadius: 8)]),
                      ),
                      const SizedBox(width: 10),
                      Text('System ${health['status'].toUpperCase()}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: statusColor)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _healthStat('Riders', health['activeRiders'].toString()),
                      _healthStat('In Transit', health['ordersInTransit'].toString()),
                      _healthStat('Failed', health['failedDeliveries'].toString()),
                    ],
                  ),
                ],
              )
            : Row(
            children: [
              Container(
                width: 12, height: 12,
                decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle, boxShadow: [BoxShadow(color: statusColor.withOpacity(0.5), blurRadius: 8)]),
              ),
              const SizedBox(width: 16),
              Text('SYSTEM HEALTH: ${health['status'].toUpperCase()}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: statusColor)),
              const Spacer(),
              _healthStat('Active Riders', health['activeRiders'].toString()),
              const SizedBox(width: 24),
              _healthStat('In Transit', health['ordersInTransit'].toString()),
              const SizedBox(width: 24),
              _healthStat('Failed Drops', health['failedDeliveries'].toString()),
            ],
          ),
        );
      },
    );
  }

  Widget _healthStat(String label, String val) {
    return Column(
      children: [
        Text(val, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
        Text(label, style: const TextStyle(color: AppTheme.greyColor, fontSize: 10, fontWeight: FontWeight.bold)),
      ],
    );
  }

  void _showReportModal() async {
    showDialog(context: context, barrierDismissible: false, builder: (c) => const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor)));
    final data = await _reportService.getAnalyticsData();
    if (mounted) Navigator.pop(context);

    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final isMobile = MediaQuery.of(context).size.width < 700;
        return Container(
          height: MediaQuery.of(context).size.height * 0.8,
          decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
          padding: EdgeInsets.all(isMobile ? 20 : 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Analytics Report', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
                ],
              ),
              const Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _reportStat('Total', data['total'].toString()),
                  _reportStat('Delivered', data['delivered'].toString()),
                  _reportStat('Canceled', data['cancelled'].toString()),
                ],
              ),
              const SizedBox(height: 24),
              const Text('Rider Performance', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.builder(
                  itemCount: data['riders'].length,
                  itemBuilder: (context, i) {
                    final r = data['riders'][i];
                    final count = data['performance'][r['id']] ?? 0;
                    return ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: AppTheme.primaryColor.withOpacity(0.1), shape: BoxShape.circle),
                        child: const Icon(Icons.delivery_dining, color: AppTheme.primaryColor, size: 18),
                      ),
                      title: Text(r['name']),
                      trailing: Text('$count Drops', style: const TextStyle(fontWeight: FontWeight.bold)),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _reportStat(String label, String val) {
    return Column(
      children: [
        Text(val, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: AppTheme.primaryColor)),
        Text(label, style: const TextStyle(color: AppTheme.greyColor, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildFinancialRow(bool isMobile) {
    return StreamBuilder<List<OrderModel>>(
      stream: _orderService.getOrdersStream(),
      builder: (context, snapshot) {
        final orders = snapshot.data ?? [];
        double totalRev = 0;
        double pendingCod = 0;
        for (var o in orders) {
          totalRev += o.serviceFee;
          if (o.status != OrderStatus.delivered && o.status != OrderStatus.cancelled) pendingCod += o.codAmount;
        }

        if (isMobile) {
          return Column(
            children: [
              _buildFinancialCard('Revenue', '${totalRev.toStringAsFixed(0)} AED', Icons.payments, Colors.orange),
              const SizedBox(height: 12),
              _buildFinancialCard('Pending', '${pendingCod.toStringAsFixed(0)} AED', Icons.account_balance_wallet, Colors.blue),
            ],
          );
        }

        return Row(
          children: [
            Expanded(child: _buildFinancialCard('Fleet Revenue', '${totalRev.toStringAsFixed(0)} AED', Icons.payments, Colors.orange)),
            const SizedBox(width: AppTheme.s24),
            Expanded(child: _buildFinancialCard('Pending COD', '${pendingCod.toStringAsFixed(0)} AED', Icons.account_balance_wallet, Colors.blue)),
          ],
        );
      },
    );
  }

  Widget _buildFinancialCard(String title, String val, IconData icon, Color color) {
    return GlassCard(
      padding: const EdgeInsets.all(AppTheme.s16),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(color: AppTheme.greyColor, fontSize: 11, fontWeight: FontWeight.bold)),
              Text(val, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildKPISection(bool isMobile) {
    return StreamBuilder<List<OrderModel>>(
      stream: _orderService.getOrdersStream(),
      builder: (context, snapshot) {
        final orders = snapshot.data ?? [];
        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: isMobile ? 2 : 3,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: isMobile ? 1.6 : 2.5,
          children: [
            _buildKPICard('Orders', orders.length.toString(), Icons.inventory_2, AppTheme.primaryColor, isMobile),
            _buildKPICard('Flow', orders.where((o) => o.status == OrderStatus.processing).length.toString(), Icons.sync, Colors.amber, isMobile),
            _buildKPICard('Success', orders.where((o) => o.status == OrderStatus.delivered).length.toString(), Icons.task_alt, AppTheme.successColor, isMobile),
          ],
        );
      },
    );
  }

  Widget _buildKPICard(String title, String value, IconData icon, Color color, bool isMobile) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: isMobile ? 20 : 24),
          Text(value, style: TextStyle(fontSize: isMobile ? 18 : 24, fontWeight: FontWeight.w900)),
          Text(title, style: const TextStyle(color: AppTheme.greyColor, fontSize: 10, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildPerformanceSection() {
    return StreamBuilder<List<OrderModel>>(
      stream: _orderService.getOrdersStream(),
      builder: (context, snapshot) {
        final orders = snapshot.data ?? [];
        final total = orders.isEmpty ? 1 : orders.length;
        return GlassCard(
          child: Column(
            children: [
              const Text('Performance', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildCircularStat('Flow', orders.where((o) => o.status == OrderStatus.inTransit).length / total, Colors.purple),
                    const SizedBox(width: 20),
                    _buildCircularStat('Success', orders.where((o) => o.status == OrderStatus.delivered).length / total, AppTheme.successColor),
                    const SizedBox(width: 20),
                    _buildCircularStat('Canceled', orders.where((o) => o.status == OrderStatus.cancelled).length / total, AppTheme.errorColor),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCircularStat(String label, double val, Color color) {
    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(width: 70, height: 70, child: CircularProgressIndicator(value: val, strokeWidth: 8, backgroundColor: color.withOpacity(0.1), color: color)),
            Text('${(val * 100).toInt()}%', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          ],
        ),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.greyColor, fontSize: 10)),
      ],
    );
  }

  Widget _buildActivitySection() {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Fleet Feed', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          StreamBuilder<List<LogModel>>(
            stream: _logService.getLogsStream(),
            builder: (context, snapshot) {
              final logs = snapshot.data ?? [];
              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: logs.length > 5 ? 5 : logs.length,
                itemBuilder: (context, i) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      const CircleAvatar(radius: 3, backgroundColor: AppTheme.primaryColor),
                      const SizedBox(width: 8),
                      Expanded(child: Text(logs[i].action, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
