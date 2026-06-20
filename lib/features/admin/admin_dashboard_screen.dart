import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
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

  Widget _buildStatCard(BuildContext context, String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: ShadTheme.of(context).colorScheme.border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: ShadTheme.of(context).textTheme.muted),
                const SizedBox(height: 4),
                Text(value, style: ShadTheme.of(context).textTheme.h3),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
                      padding: const EdgeInsets.all(24.0),
                      children: [
                        Text('Dashboard Admin', style: ShadTheme.of(context).textTheme.h3),
                        const SizedBox(height: 8),
                        Text('Data per: ${_data?['date'] ?? '-'}', style: ShadTheme.of(context).textTheme.muted),
                        const SizedBox(height: 24),
                        _buildStatCard(context, 'Total Pengguna Aktif', '${_data?['total_users'] ?? 0}', LucideIcons.users, Colors.blue),
                        const SizedBox(height: 16),
                        _buildStatCard(context, 'Total Hadir', '${_data?['total_present'] ?? 0}', LucideIcons.checkCircle, Colors.green),
                        const SizedBox(height: 16),
                        _buildStatCard(context, 'Total Izin/Sakit', '${_data?['total_permits'] ?? 0}', LucideIcons.fileText, Colors.orange),
                        const SizedBox(height: 16),
                        _buildStatCard(context, 'Total Alpa', '${_data?['total_absent'] ?? 0}', LucideIcons.xCircle, Colors.red),
                      ],
                    ),
                  ),
      ),
    );
  }
}
