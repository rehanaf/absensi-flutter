import 'package:flutter/material.dart';
import '../../../data/services/api_service.dart';
import '../../../core/widgets/app_toast.dart';
import 'dart:async';

class AdminParentChildRequestsScreen extends StatefulWidget {
  const AdminParentChildRequestsScreen({super.key});

  @override
  State<AdminParentChildRequestsScreen> createState() =>
      _AdminParentChildRequestsScreenState();
}

class _AdminParentChildRequestsScreenState
    extends State<AdminParentChildRequestsScreen> {
  final ApiService _apiService = ApiService();
  final SearchController _searchController = SearchController();

  bool _isLoading = true;
  String? _errorMessage;

  List<dynamic> _requests = [];
  int _currentPage = 1;
  int _lastPage = 1;
  String _selectedStatus = ''; // '' for all, 'pending', 'approved', 'rejected'
  String _searchQuery = '';
  Timer? _debounce;

  static const _iconColor = Color(0xFF7E57C2);

  @override
  void initState() {
    super.initState();
    _fetchRequests();
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
        _fetchRequests();
      }
    });
  }

  Future<void> _fetchRequests({bool resetPage = true}) async {
    if (resetPage) {
      setState(() {
        _currentPage = 1;
        _isLoading = true;
        _errorMessage = null;
      });
    } else {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final response = await _apiService.getAdminParentChildRequests(
        page: _currentPage,
        status: _selectedStatus,
      );

      if (mounted) {
        setState(() {
          _requests = response['data'] as List? ?? [];
          _currentPage = response['current_page'] ?? 1;
          _lastPage = response['last_page'] ?? 1;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _approveRequest(int id) async {
    setState(() => _isLoading = true);
    try {
      final result = await _apiService.approveParentChildRequest(id);
      if (mounted) {
        AppToast.showSuccess(
          context,
          message: result['message'] ?? 'Permintaan hubungan disetujui!',
        );
        _fetchRequests();
      }
    } catch (e) {
      if (mounted) {
        AppToast.showError(context, message: e.toString());
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _rejectRequest(int id) async {
    setState(() => _isLoading = true);
    try {
      final result = await _apiService.rejectParentChildRequest(id);
      if (mounted) {
        AppToast.showSuccess(
          context,
          message: result['message'] ?? 'Permintaan hubungan ditolak!',
        );
        _fetchRequests();
      }
    } catch (e) {
      if (mounted) {
        AppToast.showError(context, message: e.toString());
        setState(() => _isLoading = false);
      }
    }
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'pending':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  String _statusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return 'Disetujui';
      case 'rejected':
        return 'Ditolak';
      case 'pending':
        return 'Menunggu';
      default:
        return status.toUpperCase();
    }
  }

  void _showItemActions(Map<String, dynamic> req) {
    final cs = Theme.of(context).colorScheme;
    final id = req['id'] as int;
    final status = (req['status'] ?? 'pending') as String;
    final parentName = (req['parent'] ?? {})['name'] ?? '-';

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
                parentName,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
            const Divider(height: 1),
            if (status.toLowerCase() == 'pending') ...[
              ListTile(
                leading:
                    const Icon(Icons.check_circle_outline, color: Colors.green),
                title: const Text('Setujui'),
                onTap: () {
                  Navigator.pop(ctx);
                  _approveRequest(id);
                },
              ),
              ListTile(
                leading: Icon(Icons.cancel_outlined, color: cs.error),
                title: Text('Tolak', style: TextStyle(color: cs.error)),
                onTap: () {
                  Navigator.pop(ctx);
                  _rejectRequest(id);
                },
              ),
            ] else
              ListTile(
                leading: Icon(Icons.info_outline, color: cs.onSurfaceVariant),
                title: Text(
                  'Status: ${_statusLabel(status)}',
                  style: TextStyle(color: cs.onSurfaceVariant),
                ),
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
        title: const Text('Persetujuan Wali'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _fetchRequests,
            tooltip: 'Refresh',
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Row(
              children: [
                _buildFilterChip('Semua', ''),
                const SizedBox(width: 8),
                _buildFilterChip('Menunggu', 'pending'),
                const SizedBox(width: 8),
                _buildFilterChip('Disetujui', 'approved'),
                const SizedBox(width: 8),
                _buildFilterChip('Ditolak', 'rejected'),
              ],
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: SearchBar(
              controller: _searchController,
              hintText: 'Cari nama wali atau anak...',
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
            child: _isLoading && _requests.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
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
                              Text('Gagal memuat data', style: tt.titleMedium),
                              const SizedBox(height: 4),
                              Text(
                                _errorMessage!,
                                textAlign: TextAlign.center,
                                style: tt.bodySmall
                                    ?.copyWith(color: cs.onSurfaceVariant),
                              ),
                              const SizedBox(height: 24),
                              FilledButton.icon(
                                onPressed: _fetchRequests,
                                icon: const Icon(Icons.refresh_rounded),
                                label: const Text('Coba Lagi'),
                              ),
                            ],
                          ),
                        ),
                      )
                    : _requests.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.family_restroom_rounded,
                                  size: 56,
                                  color: cs.outlineVariant,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Tidak ada permintaan wali',
                                  style: tt.bodyLarge
                                      ?.copyWith(color: cs.onSurfaceVariant),
                                ),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: () => _fetchRequests(),
                            child: ListView(
                              padding:
                                  const EdgeInsets.fromLTRB(16, 4, 16, 100),
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
                                      children: _requests
                                          .asMap()
                                          .entries
                                          .map((entry) {
                                        final index = entry.key;
                                        final req = entry.value
                                            as Map<String, dynamic>;
                                        final isLast =
                                            index == _requests.length - 1;

                                        final parent = req['parent'] ?? {};
                                        final child = req['child'] ?? {};
                                        final status =
                                            (req['status'] ?? 'pending')
                                                as String;

                                        final parentName =
                                            parent['name'] ?? '-';
                                        final childName = child['name'] ?? '-';
                                        final childNIS =
                                            child['username'] ?? '-';
                                        final createdAt =
                                            req['created_at'] != null
                                                ? req['created_at']
                                                    .toString()
                                                    .substring(0, 10)
                                                : '';

                                        final sColor = _statusColor(status);

                                        return Column(
                                          children: [
                                            InkWell(
                                              onTap: () =>
                                                  _showItemActions(req),
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
                                                            BorderRadius
                                                                .circular(10),
                                                      ),
                                                      child: const Icon(
                                                        Icons
                                                            .family_restroom_rounded,
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
                                                          Row(
                                                            children: [
                                                              Expanded(
                                                                child: Text(
                                                                  parentName,
                                                                  style: tt
                                                                      .bodyMedium
                                                                      ?.copyWith(
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w600,
                                                                  ),
                                                                  overflow:
                                                                      TextOverflow
                                                                          .ellipsis,
                                                                ),
                                                              ),
                                                              // Status badge
                                                              Container(
                                                                padding: const EdgeInsets
                                                                    .symmetric(
                                                                    horizontal:
                                                                        6,
                                                                    vertical:
                                                                        2),
                                                                decoration:
                                                                    BoxDecoration(
                                                                  color: sColor
                                                                      .withOpacity(
                                                                          0.12),
                                                                  borderRadius:
                                                                      BorderRadius
                                                                          .circular(
                                                                              6),
                                                                ),
                                                                child: Text(
                                                                  _statusLabel(
                                                                      status),
                                                                  style: tt
                                                                      .labelSmall
                                                                      ?.copyWith(
                                                                    color:
                                                                        sColor,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w600,
                                                                  ),
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                          const SizedBox(
                                                              height: 2),
                                                          Text(
                                                            'Anak: $childName · NIS: $childNIS',
                                                            style: tt.bodySmall
                                                                ?.copyWith(
                                                              color: cs
                                                                  .onSurfaceVariant,
                                                            ),
                                                            overflow:
                                                                TextOverflow
                                                                    .ellipsis,
                                                          ),
                                                          if (createdAt
                                                              .isNotEmpty)
                                                            Text(
                                                              createdAt,
                                                              style: tt
                                                                  .labelSmall
                                                                  ?.copyWith(
                                                                color: cs
                                                                    .outlineVariant,
                                                              ),
                                                            ),
                                                        ],
                                                      ),
                                                    ),
                                                    IconButton(
                                                      icon: Icon(
                                                        Icons.more_vert_rounded,
                                                        color: cs
                                                            .onSurfaceVariant,
                                                      ),
                                                      onPressed: () =>
                                                          _showItemActions(req),
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
                                              _fetchRequests(resetPage: false);
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
                                              _fetchRequests(resetPage: false);
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
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _selectedStatus == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) {
        setState(() => _selectedStatus = value);
        _fetchRequests();
      },
    );
  }
}
