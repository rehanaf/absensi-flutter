import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../../../../data/services/api_service.dart';

class AdminGroupMembersScreen extends StatefulWidget {
  final Map<String, dynamic> group;

  const AdminGroupMembersScreen({super.key, required this.group});

  @override
  State<AdminGroupMembersScreen> createState() => _AdminGroupMembersScreenState();
}

class _AdminGroupMembersScreenState extends State<AdminGroupMembersScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = false;
  
  late List<dynamic> _members;
  List<dynamic> _allUsers = [];
  bool _isLoadingUsers = false;

  @override
  void initState() {
    super.initState();
    _members = List.from(widget.group['users'] ?? []);
  }

  Future<void> _fetchGroupMembers() async {
    setState(() => _isLoading = true);
    try {
      // Re-fetch groups and find this group to update members
      final groups = await _apiService.getGroups();
      final updatedGroup = groups.firstWhere(
        (g) => g['id'] == widget.group['id'],
        orElse: () => widget.group,
      );
      setState(() {
        _members = List.from(updatedGroup['users'] ?? []);
      });
    } catch (e) {
      if (mounted) ShadToaster.of(context).show(ShadToast.destructive(description: Text('Gagal merefresh: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _detachUser(int userId) async {
    final bool? confirm = await showDialog(
      context: context,
      builder: (context) => ShadDialog(
        title: const Text('Keluarkan Anggota'),
        description: const Text('Apakah Anda yakin ingin mengeluarkan pengguna ini dari kelompok?'),
        actions: [
          ShadButton.outline(
            child: const Text('Batal'),
            onPressed: () => Navigator.pop(context, false),
          ),
          ShadButton.destructive(
            child: const Text('Keluarkan'),
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);
    try {
      await _apiService.detachUserFromGroup(widget.group['id'], userId);
      if (mounted) {
        ShadToaster.of(context).show(const ShadToast(description: Text('Anggota berhasil dikeluarkan')));
        await _fetchGroupMembers();
      }
    } catch (e) {
      if (mounted) {
        ShadToaster.of(context).show(ShadToast.destructive(description: Text('Gagal: $e')));
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _showAddMemberDialog() async {
    setState(() => _isLoadingUsers = true);
    try {
      if (_allUsers.isEmpty) {
        _allUsers = await _apiService.getUsers();
      }
    } catch (e) {
      if (mounted) ShadToaster.of(context).show(ShadToast.destructive(description: Text('Gagal memuat pengguna: $e')));
      setState(() => _isLoadingUsers = false);
      return;
    }
    setState(() => _isLoadingUsers = false);

    // Filter out users already in the group
    final memberIds = _members.map((m) => m['id']).toSet();
    final availableUsers = _allUsers.where((u) => !memberIds.contains(u['id'])).toList();

    if (!mounted) return;

    final selectedUserId = await showDialog<int>(
      context: context,
      builder: (context) {
        return Dialog(
          child: Container(
            padding: const EdgeInsets.all(24),
            constraints: const BoxConstraints(maxHeight: 500, maxWidth: 400),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Tambah Anggota', style: ShadTheme.of(context).textTheme.h4),
                const SizedBox(height: 16),
                if (availableUsers.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text('Semua pengguna sudah berada di kelompok ini.'),
                  )
                else
                  Expanded(
                    child: ListView.builder(
                      itemCount: availableUsers.length,
                      itemBuilder: (context, index) {
                        final user = availableUsers[index];
                        return ListTile(
                          title: Text(user['name'] ?? 'No Name'),
                          subtitle: Text(user['email'] ?? ''),
                          onTap: () => Navigator.pop(context, user['id']),
                        );
                      },
                    ),
                  ),
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerRight,
                  child: ShadButton.outline(
                    child: const Text('Batal'),
                    onPressed: () => Navigator.pop(context),
                  ),
                )
              ],
            ),
          ),
        );
      },
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
        ShadToaster.of(context).show(const ShadToast(description: Text('Anggota berhasil ditambahkan')));
        await _fetchGroupMembers();
      }
    } catch (e) {
      if (mounted) {
        ShadToaster.of(context).show(ShadToast.destructive(description: Text('Gagal menambahkan anggota: $e')));
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Anggota: ${widget.group['name']}'),
      ),
      body: _isLoading || _isLoadingUsers
          ? const Center(child: CircularProgressIndicator())
          : _members.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(LucideIcons.users, size: 64, color: Colors.grey),
                      const SizedBox(height: 16),
                      Text('Belum ada anggota', style: ShadTheme.of(context).textTheme.large),
                      const SizedBox(height: 16),
                      ShadButton(
                        onPressed: _showAddMemberDialog,
                        child: const Text('Tambah Anggota'),
                      )
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _members.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final member = _members[index];
                    return Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: ShadTheme.of(context).colorScheme.border),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        title: Text(member['name'] ?? ''),
                        subtitle: Text(member['email'] ?? ''),
                        trailing: IconButton(
                          icon: const Icon(LucideIcons.userMinus, color: Colors.red),
                          onPressed: () => _detachUser(member['id']),
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddMemberDialog,
        icon: const Icon(LucideIcons.userPlus),
        label: const Text('Tambah Anggota'),
      ),
    );
  }
}
