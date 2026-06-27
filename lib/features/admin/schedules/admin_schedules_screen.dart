import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../../../../data/services/api_service.dart';
import 'admin_schedule_form_screen.dart';
import 'dart:async';

class AdminSchedulesScreen extends StatefulWidget {
  const AdminSchedulesScreen({super.key});

  @override
  State<AdminSchedulesScreen> createState() => _AdminSchedulesScreenState();
}

class _AdminSchedulesScreenState extends State<AdminSchedulesScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  String? _error;
  List<dynamic> _schedules = [];
  
  int _currentPage = 1;
  int _lastPage = 1;
  String _searchQuery = '';
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _fetchSchedules();
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
        _fetchSchedules();
      }
    });
  }

  Future<void> _fetchSchedules() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await _apiService.getSchedules(page: _currentPage, search: _searchQuery);
      setState(() {
        _schedules = response['data'] ?? [];
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

  Future<void> _deleteSchedule(int id) async {
    final bool? confirm = await showDialog(
      context: context,
      builder: (context) => ShadDialog(
        title: const Text('Hapus Jadwal'),
        description: const Text('Apakah Anda yakin ingin menghapus jadwal ini?'),
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
      await _apiService.deleteSchedule(id);
      if (mounted) {
        ShadToaster.of(context).show(const ShadToast(description: Text('Jadwal berhasil dihapus')));
        _fetchSchedules();
      }
    } catch (e) {
      if (mounted) {
        ShadToaster.of(context).show(ShadToast.destructive(description: Text('Gagal menghapus jadwal: $e')));
      }
    }
  }

  void _navigateToForm([Map<String, dynamic>? schedule]) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AdminScheduleFormScreen(schedule: schedule),
      ),
    );

    if (result == true) {
      _fetchSchedules(); 
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manajemen Jadwal'),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.refreshCw),
            onPressed: _fetchSchedules,
          )
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ShadInput(
              placeholder: const Text('Cari jadwal (hari atau grup)...'),
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
                            ShadButton(onPressed: _fetchSchedules, child: const Text('Coba Lagi')),
                          ],
                        ),
                      )
                    : _schedules.isEmpty
                        ? const Center(child: Text('Tidak ada data jadwal'))
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
                                    children: _schedules.asMap().entries.map((entry) {
                                      final index = entry.key;
                                      final schedule = entry.value;
                                      final isLast = index == _schedules.length - 1;
                                      
                                      final groupName = schedule['group'] != null ? schedule['group']['name'] : 'Jadwal Default';
                                      
                                      final isFlexible = schedule['is_flexible'] == 1 || schedule['is_flexible'] == true;

                                      return Column(
                                        children: [
                                          ListTile(
                                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                            leading: CircleAvatar(
                                              backgroundColor: Colors.blue.withOpacity(0.1),
                                              child: const Icon(LucideIcons.calendarClock, color: Colors.blue),
                                            ),
                                            title: Text(groupName, style: const TextStyle(fontWeight: FontWeight.bold)),
                                            subtitle: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                const SizedBox(height: 4),
                                                Text('Senin - Jumat (${schedule['monday_in'] ?? '07:00:00'} - ${schedule['monday_out'] ?? '16:00:00'})'),
                                                if (isFlexible)
                                                  const Text('Fleksibel', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12)),
                                              ],
                                            ),
                                            isThreeLine: true,
                                            trailing: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                IconButton(
                                                  icon: Icon(LucideIcons.edit2, size: 18, color: ShadTheme.of(context).colorScheme.primary),
                                                  onPressed: () => _navigateToForm(schedule),
                                                ),
                                                IconButton(
                                                  icon: const Icon(LucideIcons.trash2, size: 18, color: Colors.red),
                                                  onPressed: () => _deleteSchedule(schedule['id']),
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
                                      _fetchSchedules();
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
                                      _fetchSchedules();
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

