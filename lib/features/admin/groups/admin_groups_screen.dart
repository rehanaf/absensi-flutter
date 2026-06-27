import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../../../../data/services/api_service.dart';
import 'admin_group_form_screen.dart';
import 'admin_group_members_screen.dart';
import 'dart:async';

class AdminGroupsScreen extends StatefulWidget {
  const AdminGroupsScreen({super.key});

  @override
  State<AdminGroupsScreen> createState() => _AdminGroupsScreenState();
}

class _AdminGroupsScreenState extends State<AdminGroupsScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  String? _error;
  List<dynamic> _groups = [];
  
  int _currentPage = 1;
  int _lastPage = 1;
  String _searchQuery = '';
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _fetchGroups();
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
        _fetchGroups();
      }
    });
  }

  Future<void> _fetchGroups() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await _apiService.getGroups(page: _currentPage, search: _searchQuery);
      setState(() {
        _groups = response['data'] ?? [];
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

  Future<void> _deleteGroup(int id) async {
    final bool? confirm = await showDialog(
      context: context,
      builder: (context) => ShadDialog(
        title: const Text('Hapus Kelompok'),
        description: const Text('Apakah Anda yakin ingin menghapus kelompok ini?'),
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
      await _apiService.deleteGroup(id);
      if (mounted) {
        ShadToaster.of(context).show(const ShadToast(description: Text('Kelompok berhasil dihapus')));
        _fetchGroups();
      }
    } catch (e) {
      if (mounted) {
        ShadToaster.of(context).show(ShadToast.destructive(description: Text('Gagal menghapus kelompok: $e')));
      }
    }
  }

  void _navigateToForm([Map<String, dynamic>? group]) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AdminGroupFormScreen(group: group),
      ),
    );

    if (result == true) {
      _fetchGroups();
    }
  }

  void _navigateToMembers(Map<String, dynamic> group) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AdminGroupMembersScreen(group: group),
      ),
    );
    // Refresh to update member count
    _fetchGroups();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manajemen Kelompok'),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.refreshCw),
            onPressed: _fetchGroups,
          )
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ShadInput(
              placeholder: const Text('Cari kelompok...'),
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
                            ShadButton(onPressed: _fetchGroups, child: const Text('Coba Lagi')),
                          ],
                        ),
                      )
                    : _groups.isEmpty
                        ? const Center(child: Text('Tidak ada data kelompok'))
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
                                    children: _groups.asMap().entries.map((entry) {
                                      final index = entry.key;
                                      final group = entry.value;
                                      final isLast = index == _groups.length - 1;
                                      final memberCount = (group['users'] as List?)?.length ?? 0;

                                      return Column(
                                        children: [
                                          ListTile(
                                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                            leading: CircleAvatar(
                                              backgroundColor: Colors.orange.withOpacity(0.1),
                                              child: const Icon(LucideIcons.layoutGrid, color: Colors.orange),
                                            ),
                                            title: Text(group['name'] ?? 'No Name', style: const TextStyle(fontWeight: FontWeight.bold)),
                                            subtitle: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                const SizedBox(height: 4),
                                                Text('Tipe: ${group['type']}'),
                                                Text('$memberCount Anggota', style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.blue)),
                                              ],
                                            ),
                                            isThreeLine: true,
                                            onTap: () => _navigateToMembers(group),
                                            trailing: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                IconButton(
                                                  icon: Icon(LucideIcons.edit2, size: 18, color: ShadTheme.of(context).colorScheme.primary),
                                                  onPressed: () => _navigateToForm(group),
                                                ),
                                                IconButton(
                                                  icon: const Icon(LucideIcons.trash2, size: 18, color: Colors.red),
                                                  onPressed: () => _deleteGroup(group['id']),
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
                                      _fetchGroups();
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
                                      _fetchGroups();
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

