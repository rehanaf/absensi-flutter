with open('lib/features/admin/admin_dashboard_screen.dart', 'w', encoding='utf-8') as f:
    f.write("""import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../data/services/api_service.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final _apiService = ApiService();
  bool _isLoading = true;
  Map<String, dynamic>? _data;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchDashboard();
  }

  Future<void> _fetchDashboard() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final res = await _apiService.getAdminDashboard();
      setState(() {
        _data = res;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Widget _buildDailyCard(BuildContext context, String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: color, size: 32),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: ShadTheme.of(context).textTheme.muted.copyWith(fontSize: 14)),
                  const SizedBox(height: 4),
                  Text(value, style: ShadTheme.of(context).textTheme.h3.copyWith(fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatisticsBlock() {
    final stats = _data?['statistics'];
    if (stats == null) return const SizedBox.shrink();

    final roles = stats['roles_breakdown'] as List<dynamic>? ?? [];
    final groups = stats['groups_breakdown'] as List<dynamic>? ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Role Pengguna', style: ShadTheme.of(context).textTheme.large),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: roles.map((r) {
            return Chip(
              label: Text('${r['name']}: ${r['count']}'),
              backgroundColor: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
              side: BorderSide.none,
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
        Text('Group', style: ShadTheme.of(context).textTheme.large),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: groups.map((g) {
            return Chip(
              label: Text('${g['name']}: ${g['count']}'),
              backgroundColor: Theme.of(context).colorScheme.secondaryContainer.withValues(alpha: 0.3),
              side: BorderSide.none,
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildDailyGrid(bool isDesktop) {
    final daily = _data?['daily'];
    final stats = _data?['statistics'];
    if (daily == null) return const SizedBox.shrink();

    final totalUser = stats?['total_can_attend'] ?? daily['total_users'] ?? 0;

    final cards = [
      _buildDailyCard(context, 'User', '$totalUser', LucideIcons.users, Colors.blue),
      _buildDailyCard(context, 'Sudah Absen', '${daily['total_present'] ?? 0}', LucideIcons.checkCircle, Colors.green),
      _buildDailyCard(context, 'Izin', '${daily['total_permits'] ?? 0}', LucideIcons.fileText, Colors.orange),
      _buildDailyCard(context, 'Belum Absen', '${daily['total_absent'] ?? 0}', LucideIcons.xCircle, Colors.red),
    ];

    return GridView.count(
      crossAxisCount: isDesktop ? 4 : 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: isDesktop ? 2.5 : 2.0,
      children: cards,
    );
  }

  Widget _buildChart(bool isDesktop) {
    final chartData = _data?['chart_7_days'] as List<dynamic>? ?? [];
    if (chartData.isEmpty) return const SizedBox.shrink();

    List<FlSpot> presentSpots = [];
    List<FlSpot> absentSpots = [];
    
    double maxVal = 0;

    for (int i = 0; i < chartData.length; i++) {
      final item = chartData[i];
      final double p = (item['present'] ?? 0).toDouble();
      final double a = (item['absent'] ?? 0).toDouble();
      presentSpots.add(FlSpot(i.toDouble(), p));
      absentSpots.add(FlSpot(i.toDouble(), a));
      
      if (p > maxVal) maxVal = p;
      if (a > maxVal) maxVal = a;
    }

    final chartWidget = Container(
      height: 300,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(16),
      ),
      child: LineChart(
        LineChartData(
          gridData: const FlGridData(show: false),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final int index = value.toInt();
                  if (index >= 0 && index < chartData.length) {
                    final dateStr = chartData[index]['date'].toString();
                    final parts = dateStr.split('-');
                    if (parts.length == 3) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text('${parts[2]}/${parts[1]}', style: const TextStyle(fontSize: 10)),
                      );
                    }
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          minX: 0,
          maxX: (chartData.length - 1).toDouble(),
          minY: 0,
          maxY: maxVal > 0 ? maxVal + (maxVal * 0.2) : 10,
          lineBarsData: [
            LineChartBarData(
              spots: presentSpots,
              isCurved: true,
              color: Colors.green,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: true),
              belowBarData: BarAreaData(show: true, color: Colors.green.withValues(alpha: 0.1)),
            ),
            LineChartBarData(
              spots: absentSpots,
              isCurved: true,
              color: Colors.red,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: true),
              belowBarData: BarAreaData(show: true, color: Colors.red.withValues(alpha: 0.1)),
            ),
          ],
        ),
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Tren 7 Hari Terakhir', style: ShadTheme.of(context).textTheme.large),
        const SizedBox(height: 16),
        if (isDesktop)
          Row(
            children: [
              Expanded(flex: 1, child: chartWidget),
              Expanded(flex: 1, child: const SizedBox.shrink()),
            ],
          )
        else
          chartWidget,
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.sizeOf(context).width >= 600;

    return Scaffold(
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Gagal memuat data', style: ShadTheme.of(context).textTheme.large),
                        const SizedBox(height: 8),
                        Text(_error!, style: const TextStyle(color: Colors.red), textAlign: TextAlign.center),
                        const SizedBox(height: 16),
                        ShadButton(onPressed: _fetchDashboard, child: const Text('Coba Lagi')),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _fetchDashboard,
                    child: ListView(
                      padding: const EdgeInsets.all(16.0),
                      children: [
                        Text('Dashboard Admin', style: ShadTheme.of(context).textTheme.h3),
                        const SizedBox(height: 4),
                        Text('Data per: ${_data?['date'] ?? '-'}', style: ShadTheme.of(context).textTheme.muted),
                        const SizedBox(height: 16),
                        
                        // 1. Statistics
                        _buildStatisticsBlock(),
                        const SizedBox(height: 16),
                        
                        // 2. Daily Grid
                        Text('Kehadiran Hari Ini', style: ShadTheme.of(context).textTheme.large),
                        const SizedBox(height: 16),
                        _buildDailyGrid(isDesktop),
                        const SizedBox(height: 16),

                        // 3. Chart
                        _buildChart(isDesktop),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
      ),
    );
  }
}
""")
