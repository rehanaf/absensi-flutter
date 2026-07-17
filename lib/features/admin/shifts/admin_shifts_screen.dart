import 'package:flutter/material.dart';
import 'package:absensi/core/widgets/app_toast.dart';
import '../../../data/services/api_service.dart';
import 'admin_shift_form_screen.dart';

class AdminShiftsScreen extends StatefulWidget {
  const AdminShiftsScreen({super.key});

  @override
  State<AdminShiftsScreen> createState() => _AdminShiftsScreenState();
}

class _AdminShiftsScreenState extends State<AdminShiftsScreen> {
  final ApiService _apiService = ApiService();
  final SearchController _searchController = SearchController();

  List<dynamic> _shifts = [];
  bool _isLoading = false;
  String? _error;

  int _currentPage = 1;
  int _lastPage = 1;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadShifts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadShifts({int page = 1}) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final result = await _apiService.getShifts(page: page, search: _searchQuery);
      setState(() {
        _shifts = result['data'] ?? [];
        _currentPage = result['current_page'] ?? 1;
        _lastPage = result['last_page'] ?? 1;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _onSearch(String value) {
    _searchQuery = value;
    _loadShifts(page: 1);
  }

  Future<void> _confirmDelete(dynamic item) async {
    final cs = Theme.of(context).colorScheme;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('Hapus Shift'),
        content: Text('Hapus shift "${item['name']}"? Tindakan ini tidak dapat dibatalkan.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: cs.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _apiService.deleteShift(item['id']);
        AppToast.showSuccess(context, message: 'Shift berhasil dihapus');
        _loadShifts(page: _currentPage);
      } catch (e) {
        AppToast.showError(context, message: 'Gagal menghapus: $e');
      }
    }
  }

  void _showItemActions(dynamic item) {
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
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    item['name'] ?? 'Shift',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const Divider(height: 8),
              ListTile(
                leading: const Icon(Icons.edit_rounded),
                title: const Text('Edit'),
                onTap: () async {
                  Navigator.pop(ctx);
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AdminShiftFormScreen(item: item),
                    ),
                  );
                  if (result == true) _loadShifts(page: _currentPage);
                },
              ),
              ListTile(
                leading: Icon(Icons.delete_rounded, color: cs.error),
                title: Text('Hapus', style: TextStyle(color: cs.error)),
                onTap: () {
                  Navigator.pop(ctx);
                  _confirmDelete(item);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildShiftItem(dynamic item) {
    final cs = Theme.of(context).colorScheme;
    const iconColor = Color(0xFF26C6DA);
    final title = item['name'] ?? 'Shift';
    final subtitle =
        '${item["check_in"] ?? "--:--"} - ${item["check_out"] ?? "--:--"}';

    return InkWell(
      onTap: () => _showItemActions(item),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.work_history_rounded,
                  color: iconColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant)),
                ],
              ),
            ),
            Icon(Icons.more_vert_rounded,
                size: 18, color: cs.onSurfaceVariant),
          ],
        ),
      ),
    );
  }

  Widget _buildList() {
    final cs = Theme.of(context).colorScheme;
    if (_shifts.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.work_history_rounded, size: 56, color: cs.outlineVariant),
            const SizedBox(height: 12),
            Text('Belum ada shift',
                style: Theme.of(context)
                    .textTheme
                    .bodyLarge
                    ?.copyWith(color: cs.onSurfaceVariant)),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () => _loadShifts(page: 1),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Muat Ulang'),
            ),
          ],
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Material(
        color: cs.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: cs.outlineVariant.withOpacity(0.4)),
        ),
        child: ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _shifts.length,
          separatorBuilder: (_, __) => Divider(
            height: 1,
            indent: 54,
            color: cs.outlineVariant.withOpacity(0.4),
          ),
          itemBuilder: (_, i) => _buildShiftItem(_shifts[i]),
        ),
      ),
    );
  }

  Widget _buildPagination() {
    if (_lastPage <= 1) return const SizedBox.shrink();
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        FilledButton.tonal(
          onPressed: _currentPage > 1
              ? () => _loadShifts(page: _currentPage - 1)
              : null,
          child: const Icon(Icons.chevron_left_rounded),
        ),
        const SizedBox(width: 12),
        Text('$_currentPage / $_lastPage',
            style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(width: 12),
        FilledButton.tonal(
          onPressed: _currentPage < _lastPage
              ? () => _loadShifts(page: _currentPage + 1)
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
      appBar: AppBar(
        title: const Text('Shift Kerja'),
        centerTitle: false,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AdminShiftFormScreen()),
          );
          if (result == true) _loadShifts(page: _currentPage);
        },
        icon: const Icon(Icons.add_rounded),
        label: const Text('Tambah Shift'),
      ),
      body: RefreshIndicator(
        onRefresh: () => _loadShifts(page: _currentPage),
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              sliver: SliverToBoxAdapter(
                child: SearchBar(
                  controller: _searchController,
                  hintText: 'Cari shift...',
                  leading: const Icon(Icons.search_rounded),
                  trailing: [
                    if (_searchQuery.isNotEmpty)
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () {
                          _searchController.clear();
                          _onSearch('');
                        },
                      ),
                  ],
                  onChanged: _onSearch,
                  onSubmitted: _onSearch,
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverToBoxAdapter(
                child: _isLoading
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(48),
                          child: CircularProgressIndicator(),
                        ),
                      )
                    : _error != null
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const SizedBox(height: 48),
                                Icon(Icons.cloud_off_rounded,
                                    size: 56, color: cs.outlineVariant),
                                const SizedBox(height: 12),
                                Text(_error!,
                                    textAlign: TextAlign.center,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(color: cs.onSurfaceVariant)),
                                const SizedBox(height: 16),
                                FilledButton.icon(
                                  onPressed: () => _loadShifts(),
                                  icon: const Icon(Icons.refresh_rounded),
                                  label: const Text('Coba Lagi'),
                                ),
                              ],
                            ),
                          )
                        : _buildList(),
              ),
            ),
            if (!_isLoading && _error == null)
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverToBoxAdapter(child: _buildPagination()),
              ),
            const SliverToBoxAdapter(child: SizedBox(height: 80)),
          ],
        ),
      ),
    );
  }
}
