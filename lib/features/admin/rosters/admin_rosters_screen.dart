import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../../../data/services/api_service.dart';
import 'admin_roster_form_screen.dart';

class AdminRostersScreen extends StatefulWidget {
  const AdminRostersScreen({super.key});

  @override
  State<AdminRostersScreen> createState() => _AdminRostersScreenState();
}

class _AdminRostersScreenState extends State<AdminRostersScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  String? _error;
  List<dynamic> _items = [];
  
  int _currentPage = 1;
  int _lastPage = 1;
  String _searchQuery = '';
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _fetchItems();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      setState(() {
        _searchQuery = value;
        _currentPage = 1;
      });
      _fetchItems();
    });
  }

  Future<void> _fetchItems() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final data = await _apiService.getRosters(
        page: _currentPage,
        search: _searchQuery,
      );
      if (!mounted) return;
      setState(() {
        _items = data['data'] ?? [];
        _currentPage = data['current_page'] ?? 1;
        _lastPage = data['last_page'] ?? 1;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _deleteItem(int id) async {
    final bool? confirm = await showDialog(
      context: context,
      builder: (context) => ShadDialog(
        title: const Text('Hapus Data'),
        description: const Text('Apakah Anda yakin ingin menghapus data ini?'),
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
      await _apiService.deleteRoster(id);
      if (mounted) {
        ShadToaster.of(context).show(const ShadToast(description: Text('Berhasil dihapus')));
        _fetchItems();
      }
    } catch (e) {
      if (mounted) {
        ShadToaster.of(context).show(ShadToast.destructive(description: Text('Gagal: $e')));
      }
    }
  }

  void _navigateToForm([Map<String, dynamic>? item]) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AdminRosterFormScreen(item: item),
      ),
    );

    if (result == true) {
      _fetchItems();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manajemen Roster Jadwal'),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.refreshCw),
            onPressed: _fetchItems,
          )
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ShadInput(
              placeholder: const Text('Cari...'),
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
                            ShadButton(onPressed: _fetchItems, child: const Text('Coba Lagi')),
                          ],
                        ),
                      )
                    : _items.isEmpty
                        ? const Center(child: Text('Tidak ada data'))
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
                                    children: _items.asMap().entries.map((entry) {
                                      final index = entry.key;
                                      final item = entry.value;
                                      final isLast = index == _items.length - 1;

                                      return Column(
                                        children: [
                                          ListTile(
                                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                            leading: CircleAvatar(
                                              backgroundColor: Colors.green.withOpacity(0.1),
                                              child: const Icon(LucideIcons.calendarDays, color: Colors.green),
                                            ),
                                            title: Text(item['name'] ?? item['title'] ?? item['id']?.toString() ?? 'ID: ${item["id"]}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                            subtitle: const SizedBox.shrink(),
                                            trailing: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                IconButton(
                                                  icon: Icon(LucideIcons.edit2, size: 18, color: ShadTheme.of(context).colorScheme.primary),
                                                  onPressed: () => _navigateToForm(item),
                                                ),
                                                IconButton(
                                                  icon: const Icon(LucideIcons.trash2, size: 18, color: Colors.red),
                                                  onPressed: () => _deleteItem(item['id']),
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
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  ShadButton.outline(
                                    enabled: _currentPage > 1,
                                    onPressed: () {
                                      setState(() => _currentPage--);
                                      _fetchItems();
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
                                      _fetchItems();
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
