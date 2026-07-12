import 'package:flutter/material.dart';
import 'package:absensi/core/widgets/app_toast.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../data/services/api_service.dart';
import 'admin_attendance_form_screen.dart';
import 'dart:async';

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
  
  int _currentPage = 1;
  int _lastPage = 1;
  String _searchQuery = '';
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _fetchAttendances();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          _searchQuery = query;
          _currentPage = 1; 
        });
        _fetchAttendances();
      }
    });
  }

  Future<void> _fetchAttendances() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await _apiService.getAttendances(page: _currentPage, search: _searchQuery);
      setState(() {
        _attendances = response['data'] ?? [];
        _currentPage = response['current_page'] ?? 1;
        _lastPage = response['last_page'] ?? 1;
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
      builder: (context) => AlertDialog(title: const Text('Hapus Absensi'), content: const Text('Apakah Anda yakin ingin menghapus data absensi ini?'), actions: [
          OutlinedButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
          ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error, foregroundColor: Theme.of(context).colorScheme.onError), onPressed: () => Navigator.pop(context, true), child: const Text('Hapus')),
        ]),
    );

    if (confirm != true) return;

    try {
      await _apiService.deleteAttendance(id);
      if (mounted) {
        AppToast.showSuccess(context, message: 'Data absensi berhasil dihapus');
        _fetchAttendances();
      }
    } catch (e) {
      if (mounted) {
        AppToast.showError(context, message: 'Gagal menghapus absensi: $e');
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
      _fetchAttendances();
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
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(decoration: InputDecoration(border: const OutlineInputBorder(), hintText: 'Cari pengguna atau status...'), onChanged: _onSearchChanged),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('Gagal memuat', style: Theme.of(context).textTheme.titleMedium),
                            Text(_error!, style: const TextStyle(color: Colors.red)),
                            const SizedBox(height: 16),
                            ElevatedButton(onPressed: _fetchAttendances, child: const Text('Coba Lagi')),
                          ],
                        ),
                      )
                    : _attendances.isEmpty
                        ? const Center(child: Text('Tidak ada data absensi'))
                        : ListView(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.surface,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Theme.of(context).dividerColor),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.05),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Column(
                                    children: _attendances.asMap().entries.map((entry) {
                                      final index = entry.key;
                                      final att = entry.value;
                                      final isLast = index == _attendances.length - 1;
                                      
                                      final user = att['user'];
                                      final userName = user?['name'] ?? 'Unknown User';
                                      final date = att['date'] ?? '-';
                                      final checkIn = att['check_in'] ?? '--:--:--';
                                      final checkOut = att['check_out'] ?? '--:--:--';
                                      final status = att['status'] ?? '-';
                                      final isLate = att['is_late'] == 1 || att['is_late'] == true;
                                      final lateMinutes = att['late_minutes'] ?? 0;
                                      final dateStr = date?.toString() ?? '-';

                                      return Column(
                                        children: [
                                          ListTile(
                                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                                                const SizedBox(height: 4),
                                                Text('$dateStr | $checkIn - $checkOut'),
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
                                                  icon: Icon(LucideIcons.edit2, size: 18, color: Theme.of(context).colorScheme.primary),
                                                  onPressed: () => _navigateToForm(att),
                                                ),
                                                IconButton(
                                                  icon: const Icon(LucideIcons.trash2, size: 18, color: Colors.red),
                                                  onPressed: () => _deleteAttendance(att['id']),
                                                ),
                                              ],
                                            ),
                                          ),
                                          if (!isLast) Divider(height: 1, color: Theme.of(context).dividerColor),
                                        ],
                                      );
                                    }).toList(),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              // Pagination Controls
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  OutlinedButton(onPressed: (_currentPage > 1) ? () {
                                      setState(() => _currentPage--);
                                      _fetchAttendances();
                                    } : null, child: const Row(
                                      children: [
                                        Icon(LucideIcons.chevronLeft, size: 16),
                                        SizedBox(width: 4),
                                        Text('Prev'),
                                      ],
                                    )),
                                  Text('Page $_currentPage of $_lastPage', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                                  OutlinedButton(onPressed: (_currentPage < _lastPage) ? () {
                                      setState(() => _currentPage++);
                                      _fetchAttendances();
                                    } : null, child: const Row(
                                      children: [
                                        Text('Next'),
                                        SizedBox(width: 4),
                                        Icon(LucideIcons.chevronRight, size: 16),
                                      ],
                                    )),
                                ],
                              ),
                              const SizedBox(height: 32),
                            ],
                          ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToForm(),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        child: const Icon(LucideIcons.plus),
      ),
    );
  }
}

