import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/services/api_service.dart';
import '../../providers/auth_provider.dart';

class ParentDashboardScreen extends StatefulWidget {
  const ParentDashboardScreen({super.key});

  @override
  State<ParentDashboardScreen> createState() => _ParentDashboardScreenState();
}

class _ParentDashboardScreenState extends State<ParentDashboardScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  String? _errorMessage;
  List<dynamic> _children = [];

  @override
  void initState() {
    super.initState();
    _fetchDashboard();
  }

  Future<void> _fetchDashboard() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await _apiService.getParentDashboard();
      if (mounted) {
        setState(() {
          _children = response['children_status'] ?? [];
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

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'hadir': return Colors.green;
      case 'absen': return Colors.red;
      case 'izin': return Colors.orange;
      case 'sakit': return Colors.blue;
      case 'terlambat': return Colors.amber;
      default: return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'hadir': return Icons.check_circle;
      case 'absen': return Icons.cancel;
      case 'izin': return Icons.info;
      case 'sakit': return Icons.local_hospital;
      case 'terlambat': return Icons.watch_later;
      default: return Icons.help_outline;
    }
  }

  Widget _buildHeader(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final user = auth.user;
    
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;
        final avatarWidget = CircleAvatar(
          radius: 36,
          backgroundColor: Theme.of(context).colorScheme.primary,
          child: Text(
            (user?['name'] ?? 'U')[0].toUpperCase(),
            style: TextStyle(color: Theme.of(context).colorScheme.onPrimary, fontWeight: FontWeight.bold, fontSize: 32),
          ),
        );
        final nameWidget = Text(
          user?['name'] ?? 'Wali Murid',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.bold),
          textAlign: isMobile ? TextAlign.center : TextAlign.start,
        );
        final usernameWidget = Text(
          user?['username'] ?? 'username',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
          textAlign: isMobile ? TextAlign.center : TextAlign.start,
        );

        if (isMobile) {
          return Padding(
            padding: const EdgeInsets.only(top: 32, bottom: 16, left: 16, right: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                avatarWidget, 
                const SizedBox(height: 16), 
                nameWidget, 
                const SizedBox(height: 4), 
                usernameWidget
              ],
            ),
          );
        }
        return Padding(
          padding: const EdgeInsets.only(top: 32, bottom: 16, left: 16, right: 16),
          child: Row(
            children: [
              avatarWidget, 
              const SizedBox(width: 24),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start, 
                  children: [
                    nameWidget, 
                    const SizedBox(height: 4), 
                    usernameWidget
                  ]
                )
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildChildItem(Map<String, dynamic> child) {
    final name = child['name'] ?? 'Nama Tidak Diketahui';
    final username = child['username'] ?? '-';
    final chart7Days = (child['chart_7_days'] as List?) ?? [];
    final attendances = (child['attendances'] as List?) ?? [];
    
    String todayStatus = 'Belum Absen';
    String todayTime = '';
    if (attendances.isNotEmpty) {
      final todayRecord = attendances.first;
      todayStatus = todayRecord['status'] ?? todayStatus;
      final clockIn = todayRecord['clock_in'] != null ? todayRecord['clock_in'].toString().substring(0,5) : '--:--';
      final clockOut = todayRecord['clock_out'] != null ? todayRecord['clock_out'].toString().substring(0,5) : '--:--';
      todayTime = '$clockIn - $clockOut';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Theme.of(context).dividerColor.withAlpha(50))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                child: Icon(Icons.person, color: Theme.of(context).colorScheme.onPrimaryContainer),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    Text('NIS / ID: $username', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _getStatusColor(todayStatus).withAlpha(26),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(_getStatusIcon(todayStatus), size: 14, color: _getStatusColor(todayStatus)),
                    const SizedBox(width: 4),
                    Text(
                      todayStatus.toUpperCase(),
                      style: TextStyle(color: _getStatusColor(todayStatus), fontWeight: FontWeight.bold, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (todayTime.isNotEmpty) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.access_time, size: 16, color: Theme.of(context).colorScheme.onSurfaceVariant),
                const SizedBox(width: 6),
                Text('Waktu: $todayTime', style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ],
          const SizedBox(height: 16),
          if (chart7Days.isEmpty)
            Text('Belum ada riwayat 7 hari', style: Theme.of(context).textTheme.bodySmall)
          else
            Card(
              color: Theme.of(context).colorScheme.surfaceContainerHighest.withAlpha(127),
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              clipBehavior: Clip.antiAlias,
              margin: EdgeInsets.zero,
              child: Column(
                children: [
                  Container(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest.withAlpha(76),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        Expanded(child: Text('Tanggal', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant))),
                        Text('Status', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant)),
                      ]
                    )
                  ),
                  const Divider(height: 1),
                  ...chart7Days.map((day) {
                    final status = day['status']?.toString() ?? 'unknown';
                    final dateStr = day['date']?.toString() ?? '-';
                    
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Row(
                        children: [
                          Expanded(child: Text(dateStr, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: _getStatusColor(status).withAlpha(26),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              status.toUpperCase(),
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: _getStatusColor(status)),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 48, color: Theme.of(context).colorScheme.error),
              const SizedBox(height: 16),
              Text('Gagal memuat data:\n$_errorMessage', textAlign: TextAlign.center),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _fetchDashboard,
                icon: const Icon(Icons.refresh),
                label: const Text('Coba Lagi'),
              ),
            ],
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 600;
        return RefreshIndicator(
          onRefresh: _fetchDashboard,
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: _buildHeader(context),
              ),
              if (_children.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.family_restroom, size: 64, color: Theme.of(context).colorScheme.surfaceContainerHighest),
                        const SizedBox(height: 16),
                        Text('Belum ada data anak tertaut.', style: Theme.of(context).textTheme.titleMedium),
                      ],
                    ),
                  ),
                )
              else if (isDesktop)
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      if (index % 2 != 0) return const SizedBox.shrink();
                      
                      final item1 = _buildChildItem(_children[index]);
                      final item2 = index + 1 < _children.length 
                          ? _buildChildItem(_children[index + 1]) 
                          : Container();
                      
                      return IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(child: item1),
                            Expanded(child: item2),
                          ],
                        ),
                      );
                    },
                    childCount: _children.length,
                  ),
                )
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => _buildChildItem(_children[index]),
                    childCount: _children.length,
                  ),
                ),
            ],
          ),
        );
      }
    );
  }
}
