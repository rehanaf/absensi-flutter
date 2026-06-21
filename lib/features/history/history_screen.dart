import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../../data/services/api_service.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  String? _error;
  List<dynamic> _attendances = [];

  @override
  void initState() {
    super.initState();
    _fetchHistory();
  }

  Future<void> _fetchHistory() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final res = await _apiService.getHistory();
      if (mounted) {
        setState(() {
          _attendances = res['attendances'] ?? [];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Riwayat Absensi'),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.refreshCw),
            onPressed: _fetchHistory,
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _fetchHistory,
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
                  ? ListView(
                      padding: const EdgeInsets.all(24),
                      children: [
                        Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text('Gagal memuat riwayat', style: ShadTheme.of(context).textTheme.large),
                              Text(_error!, style: const TextStyle(color: Colors.red)),
                              const SizedBox(height: 16),
                              ShadButton(onPressed: _fetchHistory, child: const Text('Coba Lagi')),
                            ],
                          ),
                        ),
                      ],
                    )
                  : _attendances.isEmpty
                      ? ListView(
                          padding: const EdgeInsets.all(24),
                          children: [
                            Center(
                              child: Text('Belum ada data riwayat', style: ShadTheme.of(context).textTheme.large),
                            ),
                          ],
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: _attendances.length,
                          separatorBuilder: (context, index) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final att = _attendances[index];
                            final date = att['date'] ?? '-';
                            final checkIn = att['check_in'] ?? '--:--:--';
                            final checkOut = att['check_out'] ?? '--:--:--';
                            final status = att['status'] ?? '-';
                            final isLate = att['is_late'] == 1 || att['is_late'] == true;
                            final lateMinutes = att['late_minutes'] ?? 0;

                            Color statusColor = Colors.green;
                            if (status == 'izin' || status == 'sakit') statusColor = Colors.orange;
                            if (status == 'alpa') statusColor = Colors.red;

                            return Container(
                              decoration: BoxDecoration(
                                border: Border.all(color: ShadTheme.of(context).colorScheme.border),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: ListTile(
                                leading: att['photo_url'] != null
                                    ? CircleAvatar(
                                        backgroundImage: NetworkImage(att['photo_url']),
                                        backgroundColor: Colors.grey.shade200,
                                      )
                                    : CircleAvatar(
                                        backgroundColor: Colors.blue.withOpacity(0.1),
                                        child: const Icon(LucideIcons.calendarClock, color: Colors.blue),
                                      ),
                                title: Text('Tanggal: $date', style: const TextStyle(fontWeight: FontWeight.bold)),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Masuk: $checkIn | Keluar: $checkOut'),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: statusColor.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text('Status: $status', style: TextStyle(color: statusColor, fontSize: 10)),
                                        ),
                                        if (isLate) ...[
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: Colors.red.withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Text('Terlambat $lateMinutes mnt', style: const TextStyle(color: Colors.red, fontSize: 10)),
                                          ),
                                        ]
                                      ],
                                    ),
                                  ],
                                ),
                                isThreeLine: true,
                              ),
                            );
                          },
                        ),
        ),
      ),
    );
  }
}
