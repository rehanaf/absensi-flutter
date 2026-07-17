import 'dart:async';
import 'package:flutter/material.dart';
import '../../../data/services/api_service.dart';
import 'admin_announcement_form_screen.dart';

class AdminAnnouncementsScreen extends StatefulWidget {
  const AdminAnnouncementsScreen({super.key});

  @override
  State<AdminAnnouncementsScreen> createState() =>
      _AdminAnnouncementsScreenState();
}

class _AdminAnnouncementsScreenState extends State<AdminAnnouncementsScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  String? _error;
  List<dynamic> _items = [];

  int _currentPage = 1;
  int _lastPage = 1;
  String _searchQuery = '';
  Timer? _debounce;

  static const _iconColor = Color(0xFFFF7043);

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
      final data = await _apiService.getAnnouncements(
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
    final cs = Theme.of(context).colorScheme;
    final bool? confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('Hapus Pengumuman'),
        content: const Text('Apakah Anda yakin ingin menghapus data ini?'),
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
      await _apiService.deleteAnnouncement(id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Berhasil dihapus')),
        );
        _fetchItems();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  void _navigateToForm([Map<String, dynamic>? item]) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AdminAnnouncementFormScreen(item: item),
      ),
    );

    if (result == true) {
      _fetchItems();
    }
  }

  void _showItemActions(Map<String, dynamic> item) {
    final cs = Theme.of(context).colorScheme;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
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
                  color: cs.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
                leading: Icon(Icons.edit_rounded, color: cs.primary),
                title: const Text('Edit'),
                onTap: () {
                  Navigator.pop(ctx);
                  _navigateToForm(item);
                },
              ),
              ListTile(
                leading: Icon(Icons.delete_rounded, color: cs.error),
                title: Text('Hapus', style: TextStyle(color: cs.error)),
                onTap: () {
                  Navigator.pop(ctx);
                  _deleteItem(item['id']);
                },
              ),
            ],
          ),
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
        title: const Text('Pengumuman'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _fetchItems,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: SearchBar(
              hintText: 'Cari pengumuman...',
              leading: const Icon(Icons.search_rounded),
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
                                Icons.cloud_off_rounded,
                                size: 56,
                                color: cs.outlineVariant,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Gagal memuat data',
                                style: tt.titleMedium,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _error!,
                                style: tt.bodySmall?.copyWith(
                                  color: cs.onSurfaceVariant,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 20),
                              FilledButton.icon(
                                onPressed: _fetchItems,
                                icon: const Icon(Icons.refresh_rounded),
                                label: const Text('Coba Lagi'),
                              ),
                            ],
                          ),
                        ),
                      )
                    : _items.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.campaign_rounded,
                                  size: 56,
                                  color: cs.outlineVariant,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Belum ada pengumuman',
                                  style: tt.titleMedium?.copyWith(
                                    color: cs.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Material(
                                  color: cs.surface,
                                  surfaceTintColor: cs.surfaceTint,
                                  elevation: 1,
                                  borderRadius: BorderRadius.circular(12),
                                  child: Column(
                                    children: _items.asMap().entries.map((entry) {
                                      final index = entry.key;
                                      final item = entry.value as Map<String, dynamic>;
                                      final isLast = index == _items.length - 1;
                                      final content = item['content']?.toString() ?? '';
                                      final subtitle = content.length > 60
                                          ? '${content.substring(0, 60)}…'
                                          : content;

                                      return Column(
                                        children: [
                                          InkWell(
                                            onTap: () => _showItemActions(item),
                                            child: Padding(
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 16,
                                                vertical: 10,
                                              ),
                                              child: Row(
                                                children: [
                                                  Container(
                                                    width: 38,
                                                    height: 38,
                                                    decoration: BoxDecoration(
                                                      color: _iconColor.withOpacity(0.12),
                                                      borderRadius:
                                                          BorderRadius.circular(10),
                                                    ),
                                                    child: const Icon(
                                                      Icons.campaign_rounded,
                                                      color: _iconColor,
                                                      size: 20,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 16),
                                                  Expanded(
                                                    child: Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment.start,
                                                      children: [
                                                        Text(
                                                          item['title'] ?? 'ID: ${item["id"]}',
                                                          style: tt.bodyMedium?.copyWith(
                                                            fontWeight: FontWeight.w600,
                                                          ),
                                                        ),
                                                        if (subtitle.isNotEmpty) ...[
                                                          const SizedBox(height: 2),
                                                          Text(
                                                            subtitle,
                                                            style: tt.bodySmall?.copyWith(
                                                              color: cs.onSurfaceVariant,
                                                            ),
                                                            maxLines: 1,
                                                            overflow: TextOverflow.ellipsis,
                                                          ),
                                                        ],
                                                      ],
                                                    ),
                                                  ),
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
                                              color: cs.outlineVariant.withOpacity(0.4),
                                            ),
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
                                  FilledButton.tonal(
                                    onPressed: (_currentPage > 1)
                                        ? () {
                                            setState(() => _currentPage--);
                                            _fetchItems();
                                          }
                                        : null,
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.chevron_left_rounded, size: 18),
                                        SizedBox(width: 4),
                                        Text('Prev'),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    '$_currentPage / $_lastPage',
                                    style: tt.bodyMedium?.copyWith(
                                      color: cs.onSurfaceVariant,
                                    ),
                                  ),
                                  FilledButton.tonal(
                                    onPressed: (_currentPage < _lastPage)
                                        ? () {
                                            setState(() => _currentPage++);
                                            _fetchItems();
                                          }
                                        : null,
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text('Next'),
                                        SizedBox(width: 4),
                                        Icon(Icons.chevron_right_rounded, size: 18),
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
        label: const Text('Tambah'),
      ),
    );
  }
}
