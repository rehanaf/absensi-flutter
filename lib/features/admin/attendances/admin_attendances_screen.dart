import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../../../../data/services/api_service.dart';
import 'admin_attendance_form_screen.dart';

class AdminAttendancesScreen extends StatefulWidget {
  const AdminAttendancesScreen({super.key});

  @override
  State<AdminAttendancesScreen> createState() => _AdminAttendancesScreenState();
}

class _AdminAttendancesScreenState extends State<AdminAttendancesScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  String? _error;
  List<dynamic> _attendances = [];

  @override
  void initState() {
    super.initState();
    _fetchAttendances();
  }

  Future<void> _fetchAttendances() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final data = await _apiService.getAttendances();
      setState(() {
        _attendances = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteAttendance(int id) async {
    final bool? confirm = await showDialog(
      context: context,
      builder: (context) => ShadDialog(
        title: const Text('Hapus Absensi'),
        description: const Text('Apakah Anda yakin ingin menghapus data absensi ini?'),
        actions: [
          ShadButton.outline(
            child: const Text('Batal'),
            onPressed: () => Navigator.pop(context, false),
          ),
          ShadButton.destructive(
            child: const Text('Hapus'),
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _apiService.deleteAttendance(id);
      if (mounted) {
        ShadToaster.of(context).show(const ShadToast(description: Text('Data absensi berhasil dihapus')));
        _fetchAttendances();
      }
    } catch (e) {
      if (mounted) {
        ShadToaster.of(context).show(ShadToast.destructive(description: Text('Gagal menghapus absensi: $e')));
      }
    }
  }

  void _navigateToForm([Map<String, dynamic>? attendance]) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AdminAttendanceFormScreen(attendance: attendance),
      ),
    );

    if (result == true) {
      _fetchAttendances(); // Refresh list after create/update
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rekap Absensi'),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.refreshCw),
            onPressed: _fetchAttendances,
          )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Gagal memuat rekap absensi', style: ShadTheme.of(context).textTheme.large),
                      Text(_error!, style: const TextStyle(color: Colors.red)),
                      const SizedBox(height: 16),
                      ShadButton(onPressed: _fetchAttendances, child: const Text('Coba Lagi')),
                    ],
                  ),
                )
              : _attendances.isEmpty
                  ? Center(child: Text('Belum ada data absensi', style: ShadTheme.of(context).textTheme.large))
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: _attendances.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final att = _attendances[index];
                        final user = att['user'];
                        final userName = user?['name'] ?? 'Unknown User';
                        final date = att['date'] ?? '-';
                        final checkIn = att['check_in'] ?? '--:--:--';
                        final checkOut = att['check_out'] ?? '--:--:--';
                        final status = att['status'] ?? '-';
                        final isLate = att['is_late'] == 1 || att['is_late'] == true;
                        final lateMinutes = att['late_minutes'] ?? 0;

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
                                    child: const Icon(LucideIcons.user, color: Colors.blue),
                                  ),
                            title: Text(userName, style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Tanggal: $date'),
                                Text('Masuk: $checkIn | Keluar: $checkOut'),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.green.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text('Status: $status', style: const TextStyle(color: Colors.green, fontSize: 10)),
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
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(LucideIcons.edit2, size: 20),
                                  onPressed: () => _navigateToForm(att),
                                ),
                                IconButton(
                                  icon: const Icon(LucideIcons.trash2, size: 20, color: Colors.red),
                                  onPressed: () => _deleteAttendance(att['id']),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToForm(),
        child: const Icon(LucideIcons.plus),
      ),
    );
  }
}
