import 'package:flutter/material.dart';
import '../../../data/services/api_service.dart';
import '../../../core/widgets/app_toast.dart';

class AdminParentChildRequestsScreen extends StatefulWidget {
  const AdminParentChildRequestsScreen({super.key});

  @override
  State<AdminParentChildRequestsScreen> createState() =>
      _AdminParentChildRequestsScreenState();
}

class _AdminParentChildRequestsScreenState
    extends State<AdminParentChildRequestsScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  String? _errorMessage;

  List<dynamic> _requests = [];
  int _currentPage = 1;
  int _lastPage = 1;
  String _selectedStatus = ''; // '' for all, 'pending', 'approved', 'rejected'

  @override
  void initState() {
    super.initState();
    _fetchRequests();
  }

  Future<void> _fetchRequests({bool refresh = true}) async {
    if (refresh) {
      setState(() {
        _currentPage = 1;
        _requests = [];
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
          final data = response['data'] as List? ?? [];
          if (refresh) {
            _requests = data;
          } else {
            _requests.addAll(data);
          }
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

  Color _getStatusColor(String status) {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Persetujuan Wali Murid'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('Semua', ''),
                _buildFilterChip('Pending', 'pending'),
                _buildFilterChip('Disetujui', 'approved'),
                _buildFilterChip('Ditolak', 'rejected'),
              ],
            ),
          ),
        ),
      ),
      body: _isLoading && _requests.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 48,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Gagal memuat data:\n$_errorMessage',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () => _fetchRequests(),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Coba Lagi'),
                    ),
                  ],
                ),
              ),
            )
          : _requests.isEmpty
          ? const Center(child: Text('Tidak ada permintaan hubungan.'))
          : RefreshIndicator(
              onRefresh: () => _fetchRequests(),
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount:
                    _requests.length + (_currentPage < _lastPage ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == _requests.length) {
                    _currentPage++;
                    _fetchRequests(refresh: false);
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: CircularProgressIndicator(),
                      ),
                    );
                  }

                  final req = _requests[index];
                  final id = req['id'];
                  final parent = req['parent'] ?? {};
                  final child = req['child'] ?? {};
                  final status = req['status'] ?? 'pending';

                  final parentName = parent['name'] ?? '-';
                  final parentPhone = parent['phone_number'] ?? '-';

                  final childName = child['name'] ?? '-';
                  final childNIS = child['username'] ?? '-';

                  return Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(color: Theme.of(context).dividerColor),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: _getStatusColor(
                                    status,
                                  ).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  status.toUpperCase(),
                                  style: TextStyle(
                                    color: _getStatusColor(status),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                              Text(
                                req['created_at'] != null
                                    ? req['created_at'].toString().substring(
                                        0,
                                        10,
                                      )
                                    : '',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _buildPersonRow(
                            context,
                            'WALI / ORANG TUA',
                            parentName,
                            'HP: $parentPhone',
                            Icons.family_restroom,
                          ),
                          const Divider(height: 24),
                          _buildPersonRow(
                            context,
                            'ANAK / SISWA',
                            childName,
                            'NIS: $childNIS',
                            Icons.school,
                          ),

                          if (status == 'pending') ...[
                            const Divider(height: 24),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                OutlinedButton(
                                  onPressed: () => _rejectRequest(id),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.red,
                                    side: const BorderSide(color: Colors.red),
                                  ),
                                  child: const Text('Tolak'),
                                ),
                                const SizedBox(width: 12),
                                ElevatedButton(
                                  onPressed: () => _approveRequest(id),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    foregroundColor: Colors.white,
                                  ),
                                  child: const Text('Setujui'),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _selectedStatus == value;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (val) {
          if (val) {
            setState(() {
              _selectedStatus = value;
            });
            _fetchRequests();
          }
        },
      ),
    );
  }

  Widget _buildPersonRow(
    BuildContext context,
    String header,
    String name,
    String subtitle,
    IconData icon,
  ) {
    return Row(
      children: [
        Icon(icon, size: 24, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                header,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
