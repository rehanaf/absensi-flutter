import 'package:flutter/material.dart';
import 'package:absensi/core/widgets/app_toast.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
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
      final response = await _apiService.getGroups(
        page: _currentPage,
        search: _searchQuery,
      );
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
      builder: (context) => AlertDialog(
        title: const Text('Hapus Kelompok'),
        content: const Text('Apakah Anda yakin ingin menghapus kelompok ini?'),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _apiService.deleteGroup(id);
      if (mounted) {
        AppToast.showSuccess(context, message: 'Kelompok berhasil dihapus');
        _fetchGroups();
      }
    } catch (e) {
      if (mounted) {
        AppToast.showError(context, message: 'Gagal menghapus kelompok: $e');
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
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                hintText: 'Cari kelompok...',
              ),
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
                        Text(
                          'Gagal memuat',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Text(
                          _error!,
                          style: const TextStyle(color: Colors.red),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _fetchGroups,
                          child: const Text('Coba Lagi'),
                        ),
                      ],
                    ),
                  )
                : _groups.isEmpty
                ? const Center(child: Text('Tidak ada data kelompok'))
                : ListView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Theme.of(context).dividerColor,
                          ),
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
                              final memberCount =
                                  (group['users'] as List?)?.length ?? 0;

                              return Column(
                                children: [
                                  ListTile(
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 8,
                                    ),
                                    leading: CircleAvatar(
                                      backgroundColor: Colors.orange
                                          .withOpacity(0.1),
                                      child: const Icon(
                                        LucideIcons.layoutGrid,
                                        color: Colors.orange,
                                      ),
                                    ),
                                    title: Text(
                                      group['name'] ?? 'No Name',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const SizedBox(height: 4),
                                        Text('Tipe: ${group['type']}'),
                                        Text(
                                          '$memberCount Anggota',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                            color: Colors.blue,
                                          ),
                                        ),
                                      ],
                                    ),
                                    isThreeLine: true,
                                    onTap: () => _navigateToMembers(group),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: Icon(
                                            LucideIcons.edit2,
                                            size: 18,
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.primary,
                                          ),
                                          onPressed: () =>
                                              _navigateToForm(group),
                                        ),
                                        IconButton(
                                          icon: const Icon(
                                            LucideIcons.trash2,
                                            size: 18,
                                            color: Colors.red,
                                          ),
                                          onPressed: () =>
                                              _deleteGroup(group['id']),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (!isLast)
                                    Divider(
                                      height: 1,
                                      color: Theme.of(context).dividerColor,
                                    ),
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
                          OutlinedButton(
                            onPressed: (_currentPage > 1)
                                ? () {
                                    setState(() => _currentPage--);
                                    _fetchGroups();
                                  }
                                : null,
                            child: const Row(
                              children: [
                                Icon(LucideIcons.chevronLeft, size: 16),
                                SizedBox(width: 4),
                                Text('Prev'),
                              ],
                            ),
                          ),
                          Text(
                            'Page $_currentPage of $_lastPage',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                ),
                          ),
                          OutlinedButton(
                            onPressed: (_currentPage < _lastPage)
                                ? () {
                                    setState(() => _currentPage++);
                                    _fetchGroups();
                                  }
                                : null,
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
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        child: const Icon(LucideIcons.plus),
      ),
    );
  }
}
