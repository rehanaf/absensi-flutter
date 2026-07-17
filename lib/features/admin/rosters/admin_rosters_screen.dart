import 'package:flutter/material.dart';
import '../../../data/services/api_service.dart';
import 'package:absensi/core/widgets/app_toast.dart';
import 'admin_roster_form_screen.dart';

class AdminRostersScreen extends StatefulWidget {
  const AdminRostersScreen({super.key});

  @override
  State<AdminRostersScreen> createState() => _AdminRostersScreenState();
}

class _AdminRostersScreenState extends State<AdminRostersScreen> {
  final ApiService _apiService = ApiService();
  final SearchController _searchController = SearchController();

  List<dynamic> _items = [];
  bool _isLoading = false;
  String? _error;
  int _currentPage = 1;
  int _lastPage = 1;
  String _search = '';

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
      final res = await _apiService.getRosters(page: page, search: _search);
      final data = res['data'] ?? res;
      setState(() {
        _items = data['data'] ?? [];
        _currentPage = data['current_page'] ?? 1;
        _lastPage = data['last_page'] ?? 1;
      });
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _onSearch(String value) {
    _search = value;
    _fetchData(page: 1);
  }

  void _showActionSheet(BuildContext context, dynamic item) {
    final cs = Theme.of(context).colorScheme;
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 32,
                height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: cs.onSurfaceVariant.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
                leading: Icon(Icons.edit_rounded, color: cs.primary),
                title: const Text('Edit'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AdminRosterFormScreen(item: item),
                    ),
                  ).then((_) => _fetchData(page: _currentPage));
                },
              ),
              ListTile(
                leading: Icon(Icons.delete_rounded, color: cs.error),
                title: Text('Hapus', style: TextStyle(color: cs.error)),
                onTap: () {
                  Navigator.pop(context);
                  _confirmDelete(item);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmDelete(dynamic item) {
    final cs = Theme.of(context).colorScheme;
    final name = item['user']?['name'] ?? item['name'] ?? 'Roster';
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('Hapus Roster'),
        content: Text('Hapus roster milik "$name"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: cs.error),
            onPressed: () async {
              Navigator.pop(context);
              try {
                await _apiService.deleteRoster(item['id']);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Roster berhasil dihapus')),
                  );
                  _fetchData(page: _currentPage);
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Gagal menghapus: $e')),
                  );
                }
              }
            },
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  Widget _buildItem(dynamic item) {
    final cs = Theme.of(context).colorScheme;
    final name = item['user']?['name'] ?? item['name'] ?? 'Roster';
    final subtitle =
        '${item["date"] ?? "-"} | Shift: ${item["shift"]?["name"] ?? "-"}';

    return InkWell(
      onTap: () => _showActionSheet(context, item),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: const Color(0xFF42A5F5).withOpacity(0.12),
              child: const Icon(
                Icons.calendar_month_rounded,
                color: Color(0xFF42A5F5),
                size: 20,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: Theme.of(context)
                        .textTheme
                        .bodyLarge
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded,
                size: 20, color: cs.onSurfaceVariant),
          ],
        ),
      ),
    );
  }

  Widget _buildList() {
    if (_items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.calendar_month_rounded,
                size: 64, color: const Color(0xFF42A5F5).withOpacity(0.4)),
            const SizedBox(height: 16),
            Text('Belum ada data roster',
                style: Theme.of(context).textTheme.bodyLarge),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: () => _fetchData(page: 1),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Muat Ulang'),
            ),
          ],
        ),
      );
    }

    final cs = Theme.of(context).colorScheme;

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Material(
        color: cs.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: cs.outlineVariant.withOpacity(0.4)),
        ),
        child: ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _items.length,
          separatorBuilder: (_, __) => Divider(
            height: 1,
            indent: 54,
            color: cs.outlineVariant.withOpacity(0.4),
          ),
          itemBuilder: (_, i) => _buildItem(_items[i]),
        ),
      ),
    );
  }

  Widget _buildPagination() {
    final cs = Theme.of(context).colorScheme;
    return Row(
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
            'Halaman $_currentPage dari $_lastPage',
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: cs.onSurfaceVariant),
          ),
        ),
        FilledButton.tonal(
          onPressed: _currentPage < _lastPage
              ? () => _fetchData(page: _currentPage + 1)
              : null,
          child: const Icon(Icons.chevron_right_rounded),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar.large(
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF42A5F5).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.calendar_month_rounded,
                    color: Color(0xFF42A5F5),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 10),
                const Text('Roster Jadwal'),
              ],
            ),
            floating: true,
            snap: true,
            forceElevated: innerBoxIsScrolled,
          ),
        ],
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.cloud_off_rounded,
                            size: 64,
                            color: cs.error.withOpacity(0.5)),
                        const SizedBox(height: 16),
                        Text('Gagal memuat data',
                            style: Theme.of(context).textTheme.bodyLarge),
                        const SizedBox(height: 4),
                        Text(_error!,
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: cs.onSurfaceVariant),
                            textAlign: TextAlign.center),
                        const SizedBox(height: 12),
                        FilledButton.icon(
                          onPressed: () => _fetchData(page: _currentPage),
                          icon: const Icon(Icons.refresh_rounded),
                          label: const Text('Coba Lagi'),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: () => _fetchData(page: _currentPage),
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                      child: Column(
                        children: [
                          SearchBar(
                            controller: _searchController,
                            hintText: 'Cari roster...',
                            leading: const Icon(Icons.search_rounded),
                            trailing: [
                              if (_search.isNotEmpty)
                                IconButton(
                                  icon: const Icon(Icons.close_rounded),
                                  onPressed: () {
                                    _searchController.clear();
                                    _onSearch('');
                                  },
                                ),
                            ],
                            onChanged: _onSearch,
                            padding: const WidgetStatePropertyAll(
                              EdgeInsets.symmetric(horizontal: 16),
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildList(),
                          if (_lastPage > 1) ...[
                            const SizedBox(height: 16),
                            _buildPagination(),
                          ],
                        ],
                      ),
                    ),
                  ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const AdminRosterFormScreen(),
          ),
        ).then((_) => _fetchData(page: _currentPage)),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Tambah Roster'),
      ),
    );
  }
}
