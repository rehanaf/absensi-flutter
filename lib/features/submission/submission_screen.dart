import 'package:flutter/material.dart';
import '../../data/services/api_service.dart';
import 'permit_form_screen.dart';
import 'activity_form_screen.dart';

class SubmissionScreen extends StatefulWidget {
  const SubmissionScreen({super.key});

  @override
  State<SubmissionScreen> createState() => _SubmissionScreenState();
}

class _SubmissionScreenState extends State<SubmissionScreen> {
  final ApiService _apiService = ApiService();

  bool _isLoadingPermits = true;
  bool _isLoadingActivities = true;

  List<dynamic> _permits = [];
  List<dynamic> _activities = [];

  @override
  void initState() {
    super.initState();
    _fetchPermits();
    _fetchActivities();
  }

  Future<void> _fetchPermits() async {
    setState(() => _isLoadingPermits = true);
    try {
      final response = await _apiService.getMyPermits();
      if (mounted) {
        setState(() {
          if (response is List) {
            _permits = response;
          } else if (response is Map) {
            _permits = response['data'] ?? [];
          } else {
            _permits = [];
          }
        });
      }
    } catch (e) {
      debugPrint('Failed to load permits: $e');
    } finally {
      if (mounted) setState(() => _isLoadingPermits = false);
    }
  }

  Future<void> _fetchActivities() async {
    setState(() => _isLoadingActivities = true);
    try {
      final response = await _apiService.getMyAttendanceActivities();
      if (mounted) {
        setState(() {
          _activities = response['data'] ?? response;
          if (_activities is Map) _activities = [];
        });
      }
    } catch (e) {
      debugPrint('Failed to load activities: $e');
    } finally {
      if (mounted) setState(() => _isLoadingActivities = false);
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'pending':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  Widget _buildPermitsTab() {
    if (_isLoadingPermits) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_permits.isEmpty) {
      return const Center(
        child: Text('Belum ada riwayat pengajuan izin/sakit'),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchPermits,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _permits.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final item = _permits[index] as Map<String, dynamic>;
          final type = item['type']?.toString().toUpperCase() ?? 'IZIN';
          final status = item['status']?.toString() ?? 'pending';
          final startDate = item['start_date'] ?? '-';
          final endDate = item['end_date'] ?? '-';
          final reason = item['reason'] ?? '-';

          final isDark = Theme.of(context).brightness == Brightness.dark;
          return Container(
            decoration: BoxDecoration(
              color: isDark ? Theme.of(context).cardColor : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: isDark
                  ? Border.all(color: Theme.of(context).dividerColor)
                  : null,
              boxShadow: isDark
                  ? null
                  : [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 10,
                        spreadRadius: 1,
                        offset: const Offset(0, 4),
                      ),
                    ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          type,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(
                              context,
                            ).colorScheme.onPrimaryContainer,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _getStatusColor(status).withAlpha(26),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          status.toUpperCase(),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: _getStatusColor(status),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(
                        Icons.calendar_today,
                        size: 16,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '$startDate s/d $endDate',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Alasan: $reason',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildActivitiesTab() {
    if (_isLoadingActivities) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_activities.isEmpty) {
      return const Center(child: Text('Belum ada riwayat lembur/tugas luar'));
    }

    return RefreshIndicator(
      onRefresh: _fetchActivities,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _activities.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final item = _activities[index] as Map<String, dynamic>;
          final type =
              item['activity_type']
                  ?.toString()
                  .replaceAll('_', ' ')
                  .toUpperCase() ??
              'LEMBUR';
          final status = item['status_approval']?.toString() ?? 'pending';
          final date = item['date'] ?? '-';
          final start = item['start_time'] ?? '-';
          final end = item['end_time'] ?? '-';
          final desc = item['description'] ?? '-';

          final isDark = Theme.of(context).brightness == Brightness.dark;
          return Container(
            decoration: BoxDecoration(
              color: isDark ? Theme.of(context).cardColor : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: isDark
                  ? Border.all(color: Theme.of(context).dividerColor)
                  : null,
              boxShadow: isDark
                  ? null
                  : [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 10,
                        spreadRadius: 1,
                        offset: const Offset(0, 4),
                      ),
                    ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).colorScheme.tertiaryContainer,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          type,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(
                              context,
                            ).colorScheme.onTertiaryContainer,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _getStatusColor(status).withAlpha(26),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          status.toUpperCase(),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: _getStatusColor(status),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(
                        Icons.calendar_today,
                        size: 16,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        date,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 16),
                      const Icon(
                        Icons.access_time,
                        size: 16,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${start.toString().substring(0, 5)} - ${end.toString().substring(0, 5)}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Ket: $desc',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: const PreferredSize(
          preferredSize: Size.fromHeight(kToolbarHeight),
          child: Material(
            elevation: 1,
            child: TabBar(
              tabs: [
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.medical_services_outlined, size: 18),
                      SizedBox(width: 8),
                      Text('Izin / Sakit'),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.work_history_outlined, size: 18),
                      SizedBox(width: 8),
                      Text('Lembur / Tugas'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        body: TabBarView(children: [_buildPermitsTab(), _buildActivitiesTab()]),
        floatingActionButton: Builder(
          builder: (context) {
            return FloatingActionButton.extended(
              onPressed: () async {
                final tabIndex = DefaultTabController.of(context).index;
                bool? result;
                if (tabIndex == 0) {
                  result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const PermitFormScreen(),
                    ),
                  );
                  if (result == true) _fetchPermits();
                } else {
                  result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ActivityFormScreen(),
                    ),
                  );
                  if (result == true) _fetchActivities();
                }
              },
              icon: const Icon(Icons.add),
              label: const Text('Buat Pengajuan'),
            );
          },
        ),
      ),
    );
  }
}
