import 'package:flutter/material.dart';
import 'package:absensi/core/widgets/app_toast.dart';
import '../../../../data/services/api_service.dart';
import 'admin_schedule_form_screen.dart';

class AdminSchedulesScreen extends StatefulWidget {
  const AdminSchedulesScreen({super.key});

  @override
  State<AdminSchedulesScreen> createState() => _AdminSchedulesScreenState();
}

class _AdminSchedulesScreenState extends State<AdminSchedulesScreen> {
  final ApiService _apiService = ApiService();
  final SearchController _searchController = SearchController();

  List<dynamic> _schedules = [];
  bool _isLoading = false;
  String? _error;

  int _currentPage = 1;
  int _lastPage = 1;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadSchedules();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadSchedules({int page = 1}) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final result = await _apiService.getSchedules(page: page, search: _searchQuery);
      setState(() {
        _schedules = result['data'] ?? [];
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
    _loadSchedules(page: 1);
  }

  Future<void> _confirmDelete(dynamic schedule) async {
    final cs = Theme.of(context).colorScheme;
    final name = schedule['group']?['name'] ?? 'Jadwal Default';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('Hapus Jadwal'),
        content: Text('Hapus jadwal "$name"? Tindakan ini tidak dapat dibatalkan.'),
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
        await _apiService.deleteSchedule(schedule['id']);
        AppToast.showSuccess(context, message: 'Jadwal berhasil dihapus');
        _loadSchedules(page: _currentPage);
      } catch (e) {
        AppToast.showError(context, message: 'Gagal menghapus: $e');
      }
    }
  }

  void _showItemActions(dynamic schedule) {
    final cs = Theme.of(context).colorScheme;
    final name = schedule['group']?['name'] ?? 'Jadwal Default';
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
                    name,
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
                      builder: (_) =>
                          AdminScheduleFormScreen(schedule: schedule),
                    ),
                  );
                  if (result == true) _loadSchedules(page: _currentPage);
                },
              ),
              ListTile(
                leading: Icon(Icons.delete_rounded, color: cs.error),
                title: Text('Hapus', style: TextStyle(color: cs.error)),
                onTap: () {
                  Navigator.pop(ctx);
                  _confirmDelete(schedule);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool _isFlexible(dynamic schedule) {
    final v = schedule['is_flexible'];
    if (v == null) return false;
    if (v is bool) return v;
    if (v is int) return v == 1;
    return false;
  }

  Widget _buildScheduleItem(dynamic schedule) {
    final cs = Theme.of(context).colorScheme;
    const iconColor = Color(0xFF26A69A);
    final title = schedule['group']?['name'] ?? 'Jadwal Default';
    final subtitle =
        'Sen-Jum: ${schedule["monday_in"] ?? "07:00"} - ${schedule["monday_out"] ?? "16:00"}';
    final flexible = _isFlexible(schedule);

    return InkWell(
      onTap: () => _showItemActions(schedule),
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
              child: const Icon(Icons.access_time_rounded,
                  color: iconColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (flexible) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'Fleksibel',
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(
                                  color: Colors.green.shade700,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant)),
                ],
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.more_vert_rounded,
                size: 18, color: cs.onSurfaceVariant),
          ],
        ),
      ),
    );
  }

  Widget _buildList() {
    final cs = Theme.of(context).colorScheme;
    if (_schedules.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.calendar_month_rounded,
                size: 56, color: cs.outlineVariant),
            const SizedBox(height: 12),
            Text('Belum ada jadwal',
                style: Theme.of(context)
                    .textTheme
                    .bodyLarge
                    ?.copyWith(color: cs.onSurfaceVariant)),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () => _loadSchedules(page: 1),
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
          itemCount: _schedules.length,
          separatorBuilder: (_, __) => Divider(
            height: 1,
            indent: 54,
            color: cs.outlineVariant.withOpacity(0.4),
          ),
          itemBuilder: (_, i) => _buildScheduleItem(_schedules[i]),
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
              ? () => _loadSchedules(page: _currentPage - 1)
              : null,
          child: const Icon(Icons.chevron_left_rounded),
        ),
        const SizedBox(width: 12),
        Text('$_currentPage / $_lastPage',
            style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(width: 12),
        FilledButton.tonal(
          onPressed: _currentPage < _lastPage
              ? () => _loadSchedules(page: _currentPage + 1)
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
        title: const Text('Jadwal Kerja'),
        centerTitle: false,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const AdminScheduleFormScreen(),
            ),
          );
          if (result == true) _loadSchedules(page: _currentPage);
        },
        icon: const Icon(Icons.add_rounded),
        label: const Text('Tambah Jadwal'),
      ),
      body: RefreshIndicator(
        onRefresh: () => _loadSchedules(page: _currentPage),
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              sliver: SliverToBoxAdapter(
                child: SearchBar(
                  controller: _searchController,
                  hintText: 'Cari jadwal...',
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
                                        ?.copyWith(
                                            color: cs.onSurfaceVariant)),
                                const SizedBox(height: 16),
                                FilledButton.icon(
                                  onPressed: () => _loadSchedules(),
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
