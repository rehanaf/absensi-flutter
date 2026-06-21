import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../../../../data/services/api_service.dart';
import 'admin_group_form_screen.dart';
import 'admin_group_members_screen.dart';

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

  @override
  void initState() {
    super.initState();
    _fetchGroups();
  }

  Future<void> _fetchGroups() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final groups = await _apiService.getGroups();
      setState(() {
        _groups = groups;
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Gagal memuat kelompok', style: ShadTheme.of(context).textTheme.large),
                      Text(_error!, style: const TextStyle(color: Colors.red)),
                      const SizedBox(height: 16),
                      ShadButton(onPressed: _fetchGroups, child: const Text('Coba Lagi')),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _groups.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final group = _groups[index];
                    final memberCount = (group['users'] as List?)?.length ?? 0;

                    return Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: ShadTheme.of(context).colorScheme.border),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.orange.withOpacity(0.1),
                          child: const Icon(LucideIcons.layoutGrid, color: Colors.orange),
                        ),
                        title: Text(group['name'] ?? 'No Name', style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
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
                              icon: const Icon(LucideIcons.edit2, size: 20),
                              onPressed: () => _navigateToForm(group),
                            ),
                            IconButton(
                              icon: const Icon(LucideIcons.trash2, size: 20, color: Colors.red),
                              onPressed: () => _deleteGroup(group['id']),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToForm(),
        child: const Icon(LucideIcons.plus),
      ),
    );
  }
}
