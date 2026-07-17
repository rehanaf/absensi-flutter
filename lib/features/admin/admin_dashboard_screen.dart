import 'package:flutter/material.dart';
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

  Widget _buildDailyCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: Theme.of(
        context,
      ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                  Text(
                    title,
                    style: Theme.of(context).textTheme.bodyMedium
                        ?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        )
                        .copyWith(fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatisticsBlock(bool isDesktop) {
    final stats = _data?['statistics'];
    if (stats == null) return const SizedBox.shrink();

    final roles = stats['roles_breakdown'] as List<dynamic>? ?? [];
    final groups = stats['groups_breakdown'] as List<dynamic>? ?? [];

    final roleColors = [
      Colors.purple,
      Colors.indigo,
      Colors.teal,
      Colors.cyan,
      Colors.deepOrange,
    ];
    final groupColors = [
      Colors.amber,
      Colors.brown,
      Colors.pink,
      Colors.lime,
      Colors.blueGrey,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Role Pengguna', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: isDesktop ? 4 : 1,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: isDesktop ? 2.5 : 4.0,
          children: roles.asMap().entries.map((entry) {
            final int index = entry.key;
            final r = entry.value;
            final color = roleColors[index % roleColors.length];
            return _buildDailyCard(
              context,
              r['name'],
              '${r['count']}',
              Icons.person,
              color,
            );
          }).toList(),
        ),
        const SizedBox(height: 32),
        Text('Group', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: isDesktop ? 4 : 1,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: isDesktop ? 2.5 : 4.0,
          children: groups.asMap().entries.map((entry) {
            final int index = entry.key;
            final g = entry.value;
            final color = groupColors[index % groupColors.length];
            return _buildDailyCard(
              context,
              g['name'],
              '${g['count']}',
              Icons.people,
              color,
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
      _buildDailyCard(context, 'User', '$totalUser', Icons.group, Colors.blue),
      _buildDailyCard(
        context,
        'Sudah Absen',
        '${daily['total_present'] ?? 0}',
        Icons.check_circle,
        Colors.green,
      ),
      _buildDailyCard(
        context,
        'Izin',
        '${daily['total_permits'] ?? 0}',
        Icons.description,
        Colors.orange,
      ),
      _buildDailyCard(
        context,
        'Belum Absen',
        '${daily['total_absent'] ?? 0}',
        Icons.cancel,
        Colors.red,
      ),
    ];

    return GridView.count(
      crossAxisCount: isDesktop ? 4 : 1,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: isDesktop ? 2.5 : 4.0,
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
        color: Theme.of(
          context,
        ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.2),
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
                        child: Text(
                          '${parts[2]}/${parts[1]}',
                          style: const TextStyle(fontSize: 10),
                        ),
                      );
                    }
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
            leftTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
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
              belowBarData: BarAreaData(
                show: true,
                color: Colors.green.withValues(alpha: 0.1),
              ),
            ),
            LineChartBarData(
              spots: absentSpots,
              isCurved: true,
              color: Colors.red,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: true),
              belowBarData: BarAreaData(
                show: true,
                color: Colors.red.withValues(alpha: 0.1),
              ),
            ),
          ],
        ),
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tren 7 Hari Terakhir',
          style: Theme.of(context).textTheme.titleMedium,
        ),
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
                    Text(
                      'Gagal memuat data',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _error!,
                      style: const TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _fetchDashboard,
                      child: const Text('Coba Lagi'),
                    ),
                  ],
                ),
              )
            : RefreshIndicator(
                onRefresh: _fetchDashboard,
                child: ListView(
                  padding: const EdgeInsets.all(16.0),
                  children: [
                    Text(
                      'Dashboard Admin',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Data per: ${_data?['date'] ?? '-'}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 1. Statistics
                    _buildStatisticsBlock(isDesktop),
                    const SizedBox(height: 16),

                    // 2. Daily Grid
                    Text(
                      'Kehadiran Hari Ini',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
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
