import 'package:flutter/material.dart';
import '../../../data/services/api_service.dart';
import '../../../core/widgets/app_toast.dart';
import 'admin_location_form_screen.dart';

class AdminLocationsScreen extends StatefulWidget {
  const AdminLocationsScreen({super.key});

  @override
  State<AdminLocationsScreen> createState() => _AdminLocationsScreenState();
}

class _AdminLocationsScreenState extends State<AdminLocationsScreen> {
  final ApiService _apiService = ApiService();
  final SearchController _searchController = SearchController();

  List<dynamic> _items = [];
  bool _isLoading = false;
  String? _error;
  int _currentPage = 1;
  int _totalPages = 1;
  String _search = '';

  static const Color _iconColor = Color(0xFFEC407A);

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchData({int page = 1}) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final res = await _apiService.getLocations(page: page, search: _search);
      final data = res['data'] ?? res;
      setState(() {
        _items = data is List ? data : (data['data'] ?? []);
        _currentPage = page;
        _totalPages = res['last_page'] ?? res['meta']?['last_page'] ?? 1;
      });
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteItem(dynamic item) async {
    final confirmed = await _showDeleteDialog(
      item['name'] ?? item['title'] ?? 'ID: \${item["id"]}',
    );
    if (!confirmed) return;
    try {
      await _apiService.deleteLocation(item['id']);
      AppToast.showSuccess(context, message: 'Lokasi berhasil dihapus');
      _fetchData(page: _currentPage);
    } catch (e) {
      AppToast.showError(context, message: 'Gagal menghapus: $e');
    }
  }

  Future<bool> _showDeleteDialog(String name) async {
    return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            title: const Text('Hapus Lokasi'),
            content: Text('Yakin ingin menghapus "\$name"?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Batal'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: FilledButton.styleFrom(
                  backgroundColor: Theme.of(ctx).colorScheme.error,
                ),
                child: const Text('Hapus'),
              ),
            ],
          ),
        ) ??
        false;
  }

  void _showItemActions(dynamic item) {
    final cs = Theme.of(context).colorScheme;
    final name = item['name'] ?? item['title'] ?? 'ID: \${item["id"]}';
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
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: cs.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Text(
                name,
                style: Theme.of(ctx)
                    .textTheme
                    .titleSmall
                    ?.copyWith(color: cs.onSurfaceVariant),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.edit_rounded),
              title: const Text('Edit'),
              onTap: () {
                Navigator.pop(ctx);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AdminLocationFormScreen(item: item),
                  ),
                ).then((_) => _fetchData(page: _currentPage));
              },
            ),
            ListTile(
              leading: Icon(Icons.delete_rounded, color: cs.error),
              title: Text('Hapus', style: TextStyle(color: cs.error)),
              onTap: () {
                Navigator.pop(ctx);
                _deleteItem(item);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _onSearchChanged(String value) {
    _search = value;
    _fetchData(page: 1);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cabang / Lokasi'),
        centerTitle: false,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AdminLocationFormScreen()),
        ).then((_) => _fetchData(page: _currentPage)),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Tambah Lokasi'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: SearchBar(
              controller: _searchController,
              hintText: 'Cari lokasi...',
              leading: const Icon(Icons.search_rounded),
              trailing: [
                if (_search.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
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
          Expanded(child: _buildBody(cs)),
          if (!_isLoading && _error == null && _totalPages > 1)
            _buildPagination(cs),
        ],
      ),
    );
  }

  Widget _buildBody(ColorScheme cs) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_rounded, size: 56, color: cs.error),
            const SizedBox(height: 12),
            Text(_error!, style: TextStyle(color: cs.error)),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () => _fetchData(page: _currentPage),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Coba Lagi'),
            ),
          ],
        ),
      );
    }
    if (_items.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.location_off_rounded, size: 56, color: cs.outline),
            const SizedBox(height: 12),
            Text('Tidak ada data lokasi', style: TextStyle(color: cs.outline)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _fetchData(page: _currentPage),
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Material(
              color: cs.surface,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: cs.outlineVariant.withOpacity(0.5)),
              ),
              child: Column(
                children: _items.asMap().entries.map((entry) {
                  final i = entry.key;
                  final item = entry.value;
                  return Column(
                    children: [
                      _buildListItem(item, cs),
                      if (i < _items.length - 1)
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
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildListItem(dynamic item, ColorScheme cs) {
    final name = item['name'] ?? item['title'] ?? 'ID: \${item["id"]}';
    return InkWell(
      onTap: () => _showItemActions(item),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: _iconColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.location_on_rounded,
                color: _iconColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                name,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Icon(Icons.more_vert_rounded, size: 18, color: cs.outline),
          ],
        ),
      ),
    );
  }

  Widget _buildPagination(ColorScheme cs) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FilledButton.tonal(
            onPressed: _currentPage > 1
                ? () => _fetchData(page: _currentPage - 1)
                : null,
            child: const Icon(Icons.chevron_left_rounded),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Hal \$_currentPage / \$_totalPages',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          FilledButton.tonal(
            onPressed: _currentPage < _totalPages
                ? () => _fetchData(page: _currentPage + 1)
                : null,
            child: const Icon(Icons.chevron_right_rounded),
          ),
        ],
      ),
    );
  }
}
