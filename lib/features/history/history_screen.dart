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
                      : ListView(
                          padding: const EdgeInsets.all(24),
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                border: Border.all(color: ShadTheme.of(context).colorScheme.border),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              clipBehavior: Clip.hardEdge,
                              child: Material(
                                color: Colors.transparent,
                                child: Column(
                                  children: List.generate(
                                    _attendances.length,
                                    (index) {
                                      final att = _attendances[index];
                                      final rawDate = att['date']?.toString() ?? '-';
                                      final date = rawDate;
                                      final checkIn = att['check_in'] ?? '--:--';
                                      final checkOut = att['check_out'] ?? '--:--';
                                      final status = att['status'] ?? '-';
                                      final isLate = att['is_late'] == 1 || att['is_late'] == true;
                                      final lateMinutes = att['late_minutes'] ?? 0;

                                      Color badgeColor = ShadTheme.of(context).colorScheme.primary;
                                      if (status == 'hadir') badgeColor = Colors.green;
                                      if (status == 'sakit' || status == 'izin') badgeColor = Colors.orange;
                                      if (status == 'alpa' || status == 'alpha') badgeColor = Colors.red;

                                      return Column(
                                        children: [
                                          InkWell(
                                            onTap: () {},
                                            child: Padding(
                                              padding: const EdgeInsets.all(16),
                                              child: Row(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  if (att['photo_url'] != null)
                                                    CircleAvatar(
                                                      backgroundImage: NetworkImage(att['photo_url']),
                                                      backgroundColor: Colors.grey.shade200,
                                                    )
                                                  else
                                                    CircleAvatar(
                                                      backgroundColor: Colors.blue.withOpacity(0.1),
                                                      child: const Icon(LucideIcons.calendarClock, color: Colors.blue),
                                                    ),
                                                  const SizedBox(width: 16),
                                                  Expanded(
                                                    child: Column(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                        Text(date, style: const TextStyle(fontWeight: FontWeight.bold)),
                                                        const SizedBox(height: 4),
                                                        Text('Masuk: $checkIn  •  Pulang: $checkOut', style: ShadTheme.of(context).textTheme.muted),
                                                        if (isLate) ...[
                                                          const SizedBox(height: 4),
                                                          Text('Terlambat $lateMinutes menit', style: const TextStyle(color: Colors.red, fontSize: 12)),
                                                        ],
                                                      ],
                                                    ),
                                                  ),
                                                  ShadBadge(
                                                    backgroundColor: badgeColor,
                                                    child: Text(status.toString().toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 10)),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                          if (index < _attendances.length - 1)
                                            Divider(height: 1, color: ShadTheme.of(context).colorScheme.border),
                                        ],
                                      );
                                    },
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
        ),
      ),
    );
  }
}
