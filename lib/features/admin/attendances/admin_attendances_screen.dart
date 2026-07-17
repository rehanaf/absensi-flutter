import 'package:flutter/material.dart';
import '../../../../data/services/api_service.dart';
import 'admin_attendance_form_screen.dart';

class AdminAttendancesScreen extends StatefulWidget {
  const AdminAttendancesScreen({super.key});

  @override
  State<AdminAttendancesScreen> createState() => _AdminAttendancesScreenState();
}

class _AdminAttendancesScreenState extends State<AdminAttendancesScreen> {
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
      final res = await _apiService.getAttendances(page: page, search: _search);
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

  void _showActionSheet(BuildContext context, dynamic att) {
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
                      builder: (_) => AdminAttendanceFormScreen(attendance: att),
                    ),
                  ).then((_) => _fetchData(page: _currentPage));
                },
              ),
              ListTile(
                leading: Icon(Icons.delete_rounded, color: cs.error),
                title: Text('Hapus', style: TextStyle(color: cs.error)),
                onTap: () {
                  Navigator.pop(context);
                  _confirmDelete(att);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmDelete(dynamic att) {
    final cs = Theme.of(context).colorScheme;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('Hapus Absensi'),
        content: Text(
          'Hapus absensi milik "${att['user']?['name'] ?? 'Unknown'}"?',
        ),
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
                await _apiService.deleteAttendance(att['id']);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Absensi berhasil dihapus')),
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

  Widget _buildAvatar(dynamic att) {
    if (att['photo_url'] != null) {
      return CircleAvatar(
        backgroundImage: NetworkImage(att['photo_url']),
        radius: 20,
      );
    }
    return const CircleAvatar(
      radius: 20,
      backgroundColor: Color(0xFFE8EAF6),
      child: Icon(Icons.person_rounded, color: Color(0xFF5C6BC0), size: 20),
    );
  }

  Widget _buildBadge(dynamic att) {
    final isLate = att['is_late'] == true || att['is_late'] == 1;
    if (!isLate) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.only(top: 4),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Text(
        'Terlambat ${att["late_minutes"]} mnt',
        style: TextStyle(
          fontSize: 11,
          color: Colors.red.shade700,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildItem(dynamic att) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: () => _showActionSheet(context, att),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _buildAvatar(att),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    att['user']?['name'] ?? 'Unknown',
                    style: Theme.of(context)
                        .textTheme
                        .bodyLarge
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${att["date"] ?? "-"} | Masuk: ${att["check_in"] ?? "--:--"}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                  ),
                  Text(
                    'Pulang: ${att["check_out"] ?? "--:--"}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                  ),
                  _buildBadge(att),
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
            Icon(Icons.fact_check_rounded,
                size: 64, color: const Color(0xFF66BB6A).withOpacity(0.4)),
            const SizedBox(height: 16),
            Text('Belum ada data absensi',
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
                    color: const Color(0xFF66BB6A).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.fact_check_rounded,
                    color: Color(0xFF66BB6A),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 10),
                const Text('Rekap Absensi'),
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
                            hintText: 'Cari absensi...',
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
            builder: (_) => const AdminAttendanceFormScreen(),
          ),
        ).then((_) => _fetchData(page: _currentPage)),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Tambah Absensi'),
      ),
    );
  }
}
