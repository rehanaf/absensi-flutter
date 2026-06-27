import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../../../data/services/api_service.dart';
import 'admin_user_form_screen.dart';
import 'dart:async';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  String? _error;
  List<dynamic> _users = [];
  
  int _currentPage = 1;
  int _lastPage = 1;
  String _searchQuery = '';
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _fetchUsers();
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
          _currentPage = 1; // reset to first page on new search
        });
        _fetchUsers();
      }
    });
  }

  Future<void> _fetchUsers() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await _apiService.getUsers(page: _currentPage, search: _searchQuery);
      setState(() {
        _users = response['data'] ?? [];
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

  Future<void> _deleteUser(int id) async {
    final bool? confirm = await showDialog(
      context: context,
      builder: (context) => ShadDialog(
        title: const Text('Hapus Pengguna'),
        description: const Text('Apakah Anda yakin ingin menghapus pengguna ini? Tindakan ini tidak dapat dibatalkan.'),
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
      await _apiService.deleteUser(id);
      if (mounted) {
        ShadToaster.of(context).show(const ShadToast(description: Text('Pengguna berhasil dihapus')));
        _fetchUsers();
      }
    } catch (e) {
      if (mounted) {
        ShadToaster.of(context).show(ShadToast.destructive(description: Text('Gagal menghapus pengguna: $e')));
      }
    }
  }

  void _navigateToForm([Map<String, dynamic>? user]) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AdminUserFormScreen(user: user),
      ),
    );

    if (result == true) {
      _fetchUsers(); 
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manajemen Pengguna'),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.refreshCw),
            onPressed: _fetchUsers,
          )
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ShadInput(
              placeholder: const Text('Cari pengguna...'),
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
                            ShadButton(onPressed: _fetchUsers, child: const Text('Coba Lagi')),
                          ],
                        ),
                      )
                    : _users.isEmpty
                        ? const Center(child: Text('Tidak ada data pengguna'))
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
                                    children: _users.asMap().entries.map((entry) {
                                      final index = entry.key;
                                      final user = entry.value;
                                      final isLast = index == _users.length - 1;
                                      final roleName = user['role'] != null ? user['role']['name'] : 'Unknown Role';
                                      final initial = user['name']?.toString().isNotEmpty == true 
                                          ? user['name'].toString().substring(0, 1).toUpperCase() 
                                          : '?';

                                      return Column(
                                        children: [
                                          ListTile(
                                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                            leading: CircleAvatar(
                                              backgroundColor: ShadTheme.of(context).colorScheme.primary.withOpacity(0.1),
                                              child: Text(initial, style: TextStyle(color: ShadTheme.of(context).colorScheme.primary, fontWeight: FontWeight.bold)),
                                            ),
                                            title: Text(user['name'] ?? 'No Name', style: const TextStyle(fontWeight: FontWeight.bold)),
                                            subtitle: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                const SizedBox(height: 4),
                                                Text(user['email'] ?? '', style: const TextStyle(fontSize: 12)),
                                                const SizedBox(height: 4),
                                                ShadBadge(
                                                  child: Text(roleName.toUpperCase(), style: const TextStyle(fontSize: 10)),
                                                ),
                                              ],
                                            ),
                                            isThreeLine: true,
                                            trailing: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                IconButton(
                                                  icon: Icon(LucideIcons.edit2, size: 18, color: ShadTheme.of(context).colorScheme.primary),
                                                  onPressed: () => _navigateToForm(user),
                                                ),
                                                IconButton(
                                                  icon: const Icon(LucideIcons.trash2, size: 18, color: Colors.red),
                                                  onPressed: () => _deleteUser(user['id']),
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
                                      _fetchUsers();
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
                                      _fetchUsers();
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

