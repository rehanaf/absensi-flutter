import 'package:absensi/core/constants/app_messages.dart';
import 'package:flutter/material.dart';
import 'package:absensi/core/widgets/app_toast.dart';
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
  final TextEditingController _searchController = TextEditingController();

  // Warna avatar berdasarkan huruf awal nama
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

  // Warna badge role
  Color _roleColor(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return const Color(0xFFEF5350);
      case 'guru':
      case 'staff':
        return const Color(0xFF42A5F5);
      case 'siswa':
      case 'karyawan':
        return const Color(0xFF66BB6A);
      case 'parent':
      case 'orang tua':
        return const Color(0xFFAB47BC);
      default:
        return const Color(0xFF78909C);
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
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
      final response = await _apiService.getUsers(
        page: _currentPage,
        search: _searchQuery,
      );
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
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red, size: 22),
            SizedBox(width: 8),
            Text('Hapus Pengguna', style: TextStyle(fontSize: 16)),
          ],
        ),
        content: const Text(
          'Pengguna ini akan dihapus secara permanen. Lanjutkan?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _apiService.deleteUser(id);
      if (mounted) {
        AppToast.showSuccess(context, message: 'Pengguna berhasil dihapus');
        _fetchUsers();
      }
    } catch (e) {
      if (mounted) {
        AppToast.showError(context, message: 'Gagal menghapus pengguna: $e');
      }
    }
  }

  void _navigateToForm([Map<String, dynamic>? user]) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AdminUserFormScreen(user: user)),
    );
    if (result == true) _fetchUsers();
  }

  void _showUserActions(Map<String, dynamic> user) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        final name = user['name'] ?? 'Tanpa Nama';
        final roleName = user['role']?['name'] ?? '';
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: _avatarColor(name),
                        child: Text(
                          name.isNotEmpty ? name[0].toUpperCase() : '?',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          Text(
                            AppMessages.get(roleName),
                            style: TextStyle(
                              color: _roleColor(roleName),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.edit_outlined, color: Colors.blue),
                  title: const Text('Edit Pengguna'),
                  onTap: () {
                    Navigator.pop(context);
                    _navigateToForm(user);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.delete_outline, color: Colors.red),
                  title: const Text('Hapus Pengguna',
                      style: TextStyle(color: Colors.red)),
                  onTap: () {
                    Navigator.pop(context);
                    _deleteUser(user['id']);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        title: const Text('Pengguna'),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
            onPressed: _fetchUsers,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: SearchBar(
              controller: _searchController,
              hintText: 'Cari nama atau email...',
              leading: const Icon(Icons.search_rounded, size: 20),
              trailing: [
                if (_searchQuery.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 18),
                    onPressed: () {
                      _searchController.clear();
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
          ),

          // Content
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? _buildError()
                    : _users.isEmpty
                        ? _buildEmpty()
                        : _buildList(cs),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToForm(),
        icon: const Icon(Icons.person_add_rounded),
        label: const Text('Tambah'),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline_rounded, size: 48, color: Colors.red),
          const SizedBox(height: 12),
          Text('Gagal memuat data', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(_error!, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _fetchUsers,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Coba Lagi'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline_rounded,
              size: 52, color: Colors.grey[400]),
          const SizedBox(height: 12),
          Text(
            _searchQuery.isEmpty ? 'Belum ada pengguna' : 'Tidak ditemukan',
            style: TextStyle(color: Colors.grey[600], fontSize: 15),
          ),
        ],
      ),
    );
  }

  Widget _buildList(ColorScheme cs) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      children: [
        // Info count
        Padding(
          padding: const EdgeInsets.only(bottom: 8, left: 4),
          child: Text(
            '${_users.length} pengguna ditemukan',
            style: TextStyle(
              fontSize: 12,
              color: cs.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),

        // Grouped list card
        ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Material(
            color: cs.surfaceContainerLowest,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide(color: cs.outlineVariant.withOpacity(0.5)),
            ),
            child: Column(
              children: _users.asMap().entries.map((entry) {
                final index = entry.key;
                final user = entry.value;
                final isLast = index == _users.length - 1;
                final name = user['name']?.toString() ?? '';
                final email = user['email']?.toString() ?? '';
                final roleName = user['role']?['name']?.toString() ?? '';
                final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
                final color = _avatarColor(name);
                final roleColor = _roleColor(roleName);

                return Column(
                  children: [
                    InkWell(
                      onTap: () => _showUserActions(user),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        child: Row(
                          children: [
                            // Avatar
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

                            // Info
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

                            // Role badge
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: roleColor.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                AppMessages.get(roleName),
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: roleColor,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),

                            // More button
                            Icon(
                              Icons.more_vert_rounded,
                              size: 18,
                              color: cs.onSurfaceVariant,
                            ),
                          ],
                        ),
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

        const SizedBox(height: 16),

        // Pagination
        if (_lastPage > 1)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              FilledButton.tonalIcon(
                onPressed: _currentPage > 1
                    ? () {
                        setState(() => _currentPage--);
                        _fetchUsers();
                      }
                    : null,
                icon: const Icon(Icons.chevron_left_rounded, size: 18),
                label: const Text('Sebelumnya'),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$_currentPage / $_lastPage',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              FilledButton.tonalIcon(
                onPressed: _currentPage < _lastPage
                    ? () {
                        setState(() => _currentPage++);
                        _fetchUsers();
                      }
                    : null,
                icon: const Icon(Icons.chevron_right_rounded, size: 18),
                label: const Text('Berikutnya'),
                iconAlignment: IconAlignment.end,
              ),
            ],
          ),

        const SizedBox(height: 80),
      ],
    );
  }
}
