import 'package:flutter/material.dart';
import 'package:absensi/core/widgets/app_toast.dart';
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

  static const List<Color> _avatarColors = [
    Color(0xFF5C6BC0),
    Color(0xFF26A69A),
    Color(0xFFEF5350),
    Color(0xFFAB47BC),
    Color(0xFF42A5F5),
    Color(0xFFFF7043),
    Color(0xFF66BB6A),
    Color(0xFFEC407A),
    Color(0xFF8D6E63),
    Color(0xFF78909C),
  ];

  Color _avatarColor(String name) {
    if (name.isEmpty) return _avatarColors[0];
    return _avatarColors[name.codeUnitAt(0) % _avatarColors.length];
  }

  @override
  void initState() {
    super.initState();
    _members = List.from(widget.group['users'] ?? []);
  }

  Future<void> _fetchGroupMembers() async {
    setState(() => _isLoading = true);
    try {
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

  Future<void> _detachUser(int userId, String userName) async {
    final bool? confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red, size: 22),
            SizedBox(width: 8),
            Text('Keluarkan Anggota', style: TextStyle(fontSize: 16)),
          ],
        ),
        content: Text(
          'Apakah Anda yakin ingin mengeluarkan $userName dari kelompok ini?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
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
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text('Anggota: ${widget.group['name']}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _fetchGroupMembers,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _members.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.group_off_rounded, size: 52, color: Colors.grey[400]),
                      const SizedBox(height: 12),
                      Text(
                        'Belum ada anggota',
                        style: TextStyle(color: Colors.grey[600], fontSize: 15),
                      ),
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        onPressed: _showAddMemberDialog,
                        icon: const Icon(Icons.person_add_alt_1_rounded),
                        label: const Text('Tambah Anggota'),
                      ),
                    ],
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8, left: 4),
                      child: Text(
                        '${_members.length} anggota terdaftar',
                        style: TextStyle(
                          fontSize: 12,
                          color: cs.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Material(
                        color: cs.surfaceContainerLowest,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                          side: BorderSide(color: cs.outlineVariant.withOpacity(0.5)),
                        ),
                        child: Column(
                          children: _members.asMap().entries.map((entry) {
                            final index = entry.key;
                            final member = entry.value;
                            final isLast = index == _members.length - 1;
                            final name = member['name'] ?? '';
                            final email = member['email'] ?? '';
                            final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
                            final color = _avatarColor(name);

                            return Column(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 10,
                                  ),
                                  child: Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 19,
                                        backgroundColor: color,
                                        child: Text(
                                          initial,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              name.isEmpty ? 'Tanpa Nama' : name,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w600,
                                                fontSize: 14,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              email,
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: cs.onSurfaceVariant,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.person_remove_rounded,
                                          color: Colors.red,
                                          size: 20,
                                        ),
                                        onPressed: () => _detachUser(member['id'], name),
                                      ),
                                    ],
                                  ),
                                ),
                                if (!isLast)
                                  Divider(
                                    height: 1,
                                    indent: 54,
                                    endIndent: 0,
                                    color: cs.outlineVariant.withOpacity(0.4),
                                  ),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 80),
                  ],
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddMemberDialog,
        icon: const Icon(Icons.person_add_rounded),
        label: const Text('Tambah Anggota'),
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
  final TextEditingController _dialogSearchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchUsers('');
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _dialogSearchController.dispose();
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
    final cs = Theme.of(context).colorScheme;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(20),
        constraints: const BoxConstraints(maxHeight: 500, maxWidth: 400),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tambah Anggota',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            SearchBar(
              controller: _dialogSearchController,
              hintText: 'Cari pengguna...',
              leading: const Icon(Icons.search_rounded, size: 20),
              trailing: [
                if (_searchQuery.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 18),
                    onPressed: () {
                      _dialogSearchController.clear();
                      _onSearchChanged('');
                    },
                  ),
              ],
              padding: const WidgetStatePropertyAll(
                EdgeInsets.symmetric(horizontal: 16),
              ),
              elevation: const WidgetStatePropertyAll(0),
              side: WidgetStatePropertyAll(
                BorderSide(color: cs.outlineVariant),
              ),
              shape: const WidgetStatePropertyAll(
                RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                ),
              ),
              onChanged: _onSearchChanged,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _searchResults.isEmpty
                      ? Center(
                          child: Text(
                            _searchQuery.isEmpty
                                ? 'Tidak ada pengguna tersedia.'
                                : 'Pengguna tidak ditemukan.',
                            style: TextStyle(
                              color: cs.onSurfaceVariant,
                              fontSize: 14,
                            ),
                          ),
                        )
                      : ListView.separated(
                          itemCount: _searchResults.length,
                          separatorBuilder: (context, index) => Divider(
                            height: 1,
                            color: cs.outlineVariant.withOpacity(0.4),
                          ),
                          itemBuilder: (context, index) {
                            final user = _searchResults[index];
                            final name = user['name'] ?? 'No Name';
                            return ListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text(
                                name,
                                style: const TextStyle(fontWeight: FontWeight.w600),
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
