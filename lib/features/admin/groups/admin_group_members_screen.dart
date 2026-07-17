import 'package:flutter/material.dart';
import 'package:absensi/core/widgets/app_toast.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../data/services/api_service.dart';
import 'dart:async';

class AdminGroupMembersScreen extends StatefulWidget {
  final Map<String, dynamic> group;

  const AdminGroupMembersScreen({super.key, required this.group});

  @override
  State<AdminGroupMembersScreen> createState() =>
      _AdminGroupMembersScreenState();
}

class _AdminGroupMembersScreenState extends State<AdminGroupMembersScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = false;

  late List<dynamic> _members;

  @override
  void initState() {
    super.initState();
    _members = List.from(widget.group['users'] ?? []);
  }

  Future<void> _fetchGroupMembers() async {
    setState(() => _isLoading = true);
    try {
      // Re-fetch groups and find this group to update members
      // (assuming getGroups without search/page will return it if we use search by group name)
      final groupsData = await _apiService.getGroups(
        search: widget.group['name'],
      );
      final groups = groupsData['data'] as List<dynamic>? ?? [];
      final updatedGroup = groups.firstWhere(
        (g) => g['id'] == widget.group['id'],
        orElse: () => widget.group,
      );
      setState(() {
        _members = List.from(updatedGroup['users'] ?? []);
      });
    } catch (e) {
      if (mounted) AppToast.showError(context, message: 'Gagal merefresh: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _detachUser(int userId) async {
    final bool? confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Keluarkan Anggota'),
        content: const Text(
          'Apakah Anda yakin ingin mengeluarkan pengguna ini dari kelompok?',
        ),
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
            child: const Text('Keluarkan'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);
    try {
      await _apiService.detachUserFromGroup(widget.group['id'], userId);
      if (mounted) {
        AppToast.showSuccess(context, message: 'Anggota berhasil dikeluarkan');
        await _fetchGroupMembers();
      }
    } catch (e) {
      if (mounted) {
        AppToast.showError(context, message: 'Gagal: $e');
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _showAddMemberDialog() async {
    final selectedUserId = await showDialog<int>(
      context: context,
      builder: (context) => _AddMemberDialog(
        apiService: _apiService,
        currentMemberIds: _members.map((m) => m['id']).toSet(),
      ),
    );

    if (selectedUserId != null) {
      _attachUser(selectedUserId);
    }
  }

  Future<void> _attachUser(int userId) async {
    setState(() => _isLoading = true);
    try {
      await _apiService.attachUserToGroup(widget.group['id'], userId);
      if (mounted) {
        AppToast.showSuccess(context, message: 'Anggota berhasil ditambahkan');
        await _fetchGroupMembers();
      }
    } catch (e) {
      if (mounted) {
        AppToast.showError(context, message: 'Gagal menambahkan anggota: $e');
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Anggota: ${widget.group['name']}')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _members.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(LucideIcons.users, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(
                    'Belum ada anggota',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _showAddMemberDialog,
                    child: const Text('Tambah Anggota'),
                  ),
                ],
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
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
                      children: _members.asMap().entries.map((entry) {
                        final index = entry.key;
                        final member = entry.value;
                        final isLast = index == _members.length - 1;

                        return Column(
                          children: [
                            ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              title: Text(
                                member['name'] ?? '',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Text(member['email'] ?? ''),
                              trailing: IconButton(
                                icon: const Icon(
                                  LucideIcons.userMinus,
                                  color: Colors.red,
                                ),
                                onPressed: () => _detachUser(member['id']),
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
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddMemberDialog,
        icon: const Icon(LucideIcons.userPlus),
        label: const Text('Tambah Anggota'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
      ),
    );
  }
}

class _AddMemberDialog extends StatefulWidget {
  final ApiService apiService;
  final Set<dynamic> currentMemberIds;

  const _AddMemberDialog({
    required this.apiService,
    required this.currentMemberIds,
  });

  @override
  State<_AddMemberDialog> createState() => _AddMemberDialogState();
}

class _AddMemberDialogState extends State<_AddMemberDialog> {
  List<dynamic> _searchResults = [];
  bool _isLoading = false;
  String _searchQuery = '';
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _searchUsers('');
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _searchUsers(query);
    });
  }

  Future<void> _searchUsers(String query) async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _searchQuery = query;
    });

    try {
      final response = await widget.apiService.getUsers(search: query);
      if (mounted) {
        setState(() {
          final allUsers = response['data'] as List<dynamic>? ?? [];
          _searchResults = allUsers
              .where((u) => !widget.currentMemberIds.contains(u['id']))
              .toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        padding: const EdgeInsets.all(24),
        constraints: const BoxConstraints(maxHeight: 600, maxWidth: 400),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tambah Anggota',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            TextField(
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                hintText: 'Cari pengguna...',
              ),
              onChanged: _onSearchChanged,
            ),
            const SizedBox(height: 16),
            if (_isLoading)
              const Expanded(child: Center(child: CircularProgressIndicator()))
            else if (_searchResults.isEmpty)
              Expanded(
                child: Center(
                  child: Text(
                    _searchQuery.isEmpty
                        ? 'Tidak ada pengguna tersedia.'
                        : 'Pengguna tidak ditemukan.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              )
            else
              Expanded(
                child: ListView.separated(
                  itemCount: _searchResults.length,
                  separatorBuilder: (context, index) =>
                      const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final user = _searchResults[index];
                    return ListTile(
                      title: Text(
                        user['name'] ?? 'No Name',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(user['email'] ?? ''),
                      onTap: () => Navigator.pop(context, user['id']),
                    );
                  },
                ),
              ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Batal'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
