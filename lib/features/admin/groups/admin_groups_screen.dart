import 'package:flutter/material.dart';
import 'package:absensi/core/widgets/app_toast.dart';
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
  final SearchController _searchController = SearchController();

  bool _isLoading = true;
  String? _error;
  List<dynamic> _groups = [];

  int _currentPage = 1;
  int _lastPage = 1;
  String _searchQuery = '';
  Timer? _debounce;

  static const _iconColor = Color(0xFFAB47BC);

  @override
  void initState() {
    super.initState();
    _fetchGroups();
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
    final cs = Theme.of(context).colorScheme;
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('Hapus Kelompok'),
        content: const Text('Apakah Anda yakin ingin menghapus kelompok ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: cs.error,
              foregroundColor: cs.onError,
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
    if (result == true) _fetchGroups();
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

  void _showItemActions(Map<String, dynamic> group) {
    final cs = Theme.of(context).colorScheme;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: cs.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
              child: Text(
                group['name'] ?? '',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
            const Divider(height: 1),
            ListTile(
              leading: Icon(Icons.edit_outlined, color: cs.primary),
              title: const Text('Edit'),
              onTap: () {
                Navigator.pop(ctx);
                _navigateToForm(group);
              },
            ),
            ListTile(
              leading: Icon(Icons.delete_outline, color: cs.error),
              title: Text('Hapus', style: TextStyle(color: cs.error)),
              onTap: () {
                Navigator.pop(ctx);
                _deleteGroup(group['id']);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kelompok / Kelas'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _fetchGroups,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: SearchBar(
              controller: _searchController,
              hintText: 'Cari kelompok...',
              leading: const Icon(Icons.search),
              trailing: [
                if (_searchQuery.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      _searchController.clear();
                      _onSearchChanged('');
                    },
                  ),
              ],
              onChanged: _onSearchChanged,
              padding: const WidgetStatePropertyAll(
                EdgeInsets.symmetric(horizontal: 16),
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.wifi_off_rounded,
                                size: 56,
                                color: cs.error,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Gagal memuat data',
                                style: tt.titleMedium,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _error!,
                                textAlign: TextAlign.center,
                                style: tt.bodySmall?.copyWith(
                                    color: cs.onSurfaceVariant),
                              ),
                              const SizedBox(height: 24),
                              FilledButton.icon(
                                onPressed: _fetchGroups,
                                icon: const Icon(Icons.refresh_rounded),
                                label: const Text('Coba Lagi'),
                              ),
                            ],
                          ),
                        ),
                      )
                    : _groups.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.group_work_rounded,
                                  size: 56,
                                  color: cs.outlineVariant,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Tidak ada data kelompok',
                                  style: tt.bodyLarge?.copyWith(
                                      color: cs.onSurfaceVariant),
                                ),
                              ],
                            ),
                          )
                        : ListView(
                            padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Material(
                                  color: cs.surface,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    side: BorderSide(
                                      color:
                                          cs.outlineVariant.withOpacity(0.5),
                                    ),
                                  ),
                                  child: Column(
                                    children:
                                        _groups.asMap().entries.map((entry) {
                                      final index = entry.key;
                                      final group = entry.value
                                          as Map<String, dynamic>;
                                      final isLast =
                                          index == _groups.length - 1;
                                      final memberCount =
                                          (group['users'] as List?)?.length ??
                                              0;

                                      return Column(
                                        children: [
                                          InkWell(
                                            onTap: () =>
                                                _navigateToMembers(group),
                                            onLongPress: () =>
                                                _showItemActions(group),
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 16,
                                                      vertical: 10),
                                              child: Row(
                                                children: [
                                                  Container(
                                                    width: 38,
                                                    height: 38,
                                                    decoration: BoxDecoration(
                                                      color: _iconColor
                                                          .withOpacity(0.12),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              10),
                                                    ),
                                                    child: const Icon(
                                                      Icons.group_work_rounded,
                                                      color: _iconColor,
                                                      size: 20,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 12),
                                                  Expanded(
                                                    child: Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        Text(
                                                          group['name'] ??
                                                              'No Name',
                                                          style: tt.bodyMedium
                                                              ?.copyWith(
                                                            fontWeight:
                                                                FontWeight.w600,
                                                          ),
                                                        ),
                                                        if (group['type'] !=
                                                            null)
                                                          Text(
                                                            'Tipe: ${group['type']}',
                                                            style: tt.bodySmall
                                                                ?.copyWith(
                                                              color: cs
                                                                  .onSurfaceVariant,
                                                            ),
                                                          ),
                                                        Text(
                                                          '$memberCount Anggota',
                                                          style: tt.bodySmall
                                                              ?.copyWith(
                                                            color: cs.primary,
                                                            fontWeight:
                                                                FontWeight.w500,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  IconButton(
                                                    icon: Icon(
                                                      Icons
                                                          .more_vert_rounded,
                                                      color: cs
                                                          .onSurfaceVariant,
                                                    ),
                                                    onPressed: () =>
                                                        _showItemActions(group),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                          if (!isLast)
                                            Divider(
                                              height: 1,
                                              indent: 54,
                                              color: cs.outlineVariant
                                                  .withOpacity(0.4),
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
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  FilledButton.tonal(
                                    onPressed: (_currentPage > 1)
                                        ? () {
                                            setState(() => _currentPage--);
                                            _fetchGroups();
                                          }
                                        : null,
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.chevron_left, size: 18),
                                        SizedBox(width: 4),
                                        Text('Prev'),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    'Hal $_currentPage dari $_lastPage',
                                    style: tt.bodyMedium?.copyWith(
                                      color: cs.onSurfaceVariant,
                                    ),
                                  ),
                                  FilledButton.tonal(
                                    onPressed: (_currentPage < _lastPage)
                                        ? () {
                                            setState(() => _currentPage++);
                                            _fetchGroups();
                                          }
                                        : null,
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text('Next'),
                                        SizedBox(width: 4),
                                        Icon(Icons.chevron_right, size: 18),
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToForm(),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Tambah Kelompok'),
      ),
    );
  }
}
