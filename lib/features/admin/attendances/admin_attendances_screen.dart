import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
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
            child: ShadInput(
              placeholder: const Text('Cari pengguna atau status...'),
              onChanged: _onSearchChanged,
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('Gagal memuat', style: ShadTheme.of(context).textTheme.large),
                            Text(_error!, style: const TextStyle(color: Colors.red)),
                            const SizedBox(height: 16),
                            ShadButton(onPressed: _fetchAttendances, child: const Text('Coba Lagi')),
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
                                  color: ShadTheme.of(context).colorScheme.background,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: ShadTheme.of(context).colorScheme.border),
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
                                                  icon: Icon(LucideIcons.edit2, size: 18, color: ShadTheme.of(context).colorScheme.primary),
                                                  onPressed: () => _navigateToForm(att),
                                                ),
                                                IconButton(
                                                  icon: const Icon(LucideIcons.trash2, size: 18, color: Colors.red),
                                                  onPressed: () => _deleteAttendance(att['id']),
                                                ),
                                              ],
                                            ),
                                          ),
                                          if (!isLast) Divider(height: 1, color: ShadTheme.of(context).colorScheme.border),
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
                                  ShadButton.outline(
                                    enabled: _currentPage > 1,
                                    onPressed: () {
                                      setState(() => _currentPage--);
                                      _fetchAttendances();
                                    },
                                    child: const Row(
                                      children: [
                                        Icon(LucideIcons.chevronLeft, size: 16),
                                        SizedBox(width: 4),
                                        Text('Prev'),
                                      ],
                                    ),
                                  ),
                                  Text('Page $_currentPage of $_lastPage', style: ShadTheme.of(context).textTheme.muted),
                                  ShadButton.outline(
                                    enabled: _currentPage < _lastPage,
                                    onPressed: () {
                                      setState(() => _currentPage++);
                                      _fetchAttendances();
                                    },
                                    child: const Row(
                                      children: [
                                        Text('Next'),
                                        SizedBox(width: 4),
                                        Icon(LucideIcons.chevronRight, size: 16),
                                      ],
                                    ),
                                  ),
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
        backgroundColor: ShadTheme.of(context).colorScheme.primary,
        foregroundColor: ShadTheme.of(context).colorScheme.primaryForeground,
        child: const Icon(LucideIcons.plus),
      ),
    );
  }
}

