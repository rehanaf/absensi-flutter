import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/services/api_service.dart';
import '../../providers/auth_provider.dart';
import '../../core/widgets/app_toast.dart';

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
  List<dynamic> _requests = [];
  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;

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
      final response = await _apiService.getParentDashboard(
        month: _selectedMonth,
        year: _selectedYear,
      );
      final reqResponse = await _apiService.getParentChildrenRequests();
      if (mounted) {
        setState(() {
          _children = response['children_status'] ?? [];
          _requests = reqResponse['requests'] ?? [];
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

  void _showConnectChildDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hubungkan Anak'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Masukkan NIS / Username Anak yang ingin dihubungkan:'),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'NIS / Username',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.text,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              final username = controller.text.trim();
              if (username.isEmpty) return;
              Navigator.pop(context);
              
              setState(() => _isLoading = true);
              try {
                final result = await _apiService.connectParentChild(username);
                if (mounted) {
                  AppToast.showSuccess(context, message: result['message'] ?? 'Permintaan berhasil dikirim!');
                  _fetchDashboard();
                }
              } catch (e) {
                if (mounted) {
                  AppToast.showError(context, message: e.toString());
                  setState(() => _isLoading = false);
                }
              }
            },
            child: const Text('Hubungkan'),
          ),
        ],
      ),
    );
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
                usernameWidget,
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _showConnectChildDialog,
                  icon: const Icon(Icons.add),
                  label: const Text('Hubungkan Anak'),
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
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
              ElevatedButton.icon(
                onPressed: _showConnectChildDialog,
                icon: const Icon(Icons.add),
                label: const Text('Hubungkan Anak'),
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildChildMonthlyCalendar(List<dynamic> monthAttendance) {
    try {
      if (monthAttendance.isEmpty) return const SizedBox.shrink();

      final DateTime now = DateTime.now();
      final List<String> weekdays = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];

      // Find the weekday of the first day of this month
      final DateTime firstDayOfMonth = DateTime(now.year, now.month, 1);
      final int firstWeekday = firstDayOfMonth.weekday; // 1 = Mon, 7 = Sun
      final int prefixEmptyCells = firstWeekday - 1;

      // Total cells in the grid = empty cells + days in month
      final int totalCells = prefixEmptyCells + monthAttendance.length;

      return Card(
        elevation: 0,
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withAlpha(127),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16)
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.calendar_month, color: Theme.of(context).colorScheme.primary, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Kehadiran Bulan Ini',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Weekday Headers
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: weekdays.map((day) {
                  return Expanded(
                    child: Center(
                      child: Text(
                        day,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 8),
              // Calendar Grid
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                ),
                itemCount: totalCells,
                itemBuilder: (context, index) {
                  try {
                    if (index < prefixEmptyCells) {
                      return const SizedBox.shrink();
                    }

                    final int dayIndex = index - prefixEmptyCells;
                    if (dayIndex < 0 || dayIndex >= monthAttendance.length) {
                      return const SizedBox.shrink();
                    }
                    
                    final dayData = monthAttendance[dayIndex];
                    if (dayData is! Map) {
                      return const SizedBox.shrink();
                    }
                    
                    final int dayNum = int.tryParse(dayData['day']?.toString() ?? '') ?? (dayIndex + 1);
                    final String status = dayData['status']?.toString() ?? 'absen';
                    final String dateStr = dayData['date']?.toString() ?? '';
                    
                    // Determine if this day is in the future
                    bool isFuture = false;
                    try {
                      if (dateStr.isNotEmpty) {
                        final dayDate = DateTime.parse(dateStr);
                        final todayDate = DateTime(now.year, now.month, now.day);
                        if (dayDate.isAfter(todayDate)) {
                          isFuture = true;
                        }
                      }
                    } catch (_) {}

                    Color? textColor;
                    BoxDecoration? decoration;

                    if (isFuture) {
                      textColor = Theme.of(context).colorScheme.onSurfaceVariant.withAlpha(76);
                    } else {
                      if (status == 'hadir') {
                        textColor = Colors.green;
                        decoration = BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.green, width: 2),
                        );
                      } else if (status == 'sakit' || status == 'izin' || status == 'cuti') {
                        textColor = Colors.orange;
                        decoration = BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.orange, width: 2),
                        );
                      } else if (status == 'libur') {
                        textColor = Theme.of(context).colorScheme.onSurfaceVariant.withAlpha(127);
                        decoration = BoxDecoration(
                          color: Theme.of(context).colorScheme.surfaceContainerHighest.withAlpha(200),
                          shape: BoxShape.circle,
                        );
                      } else {
                        // Absen (Tidak Hadir)
                        textColor = Colors.red;
                        decoration = BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.red.withAlpha(76), width: 1),
                        );
                      }
                    }

                    return Center(
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: decoration,
                        alignment: Alignment.center,
                        child: Text(
                          '$dayNum',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: textColor,
                          ),
                        ),
                      ),
                    );
                  } catch (e) {
                    debugPrint('Error rendering child day cell: $e');
                    return const SizedBox.shrink();
                  }
                },
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      debugPrint('Error building child monthly calendar: $e');
      return const SizedBox.shrink();
    }
  }

  Widget _buildChildItem(Map<String, dynamic> child) {
    final name = child['name'] ?? 'Nama Tidak Diketahui';
    final username = child['username'] ?? '-';
    final monthAttendance = (child['month_attendance'] as List?) ?? [];
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
          const SizedBox(height: 12),
          // Child stats summary
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildChildStatCard('Hadir', '${child['total_attendances'] ?? 0}', Colors.green),
              _buildChildStatCard('Izin', '${child['total_permits'] ?? 0}', Colors.orange),
              _buildChildStatCard('Terlambat', '${child['total_lates'] ?? 0}', Colors.amber),
              _buildChildStatCard('Alpa', '${child['total_alpa'] ?? 0}', Colors.red),
            ],
          ),
          const SizedBox(height: 16),
          _buildChildMonthlyCalendar(monthAttendance),
        ],
      ),
    );
  }

  Widget _buildChildStatCard(String label, String value, Color color) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: color.withAlpha(20),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: color),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(fontSize: 10, color: color.withOpacity(0.8), fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRequestItem(Map<String, dynamic> request) {
    final child = request['child'] ?? {};
    final childName = child['name'] ?? 'Nama Tidak Diketahui';
    final childUsername = child['username'] ?? '-';
    final status = request['status'] ?? 'pending';
    
    Color statusColor = Colors.orange;
    if (status == 'approved') statusColor = Colors.green;
    if (status == 'rejected') statusColor = Colors.red;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Theme.of(context).dividerColor.withAlpha(50))),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: Icon(Icons.person_search, color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(childName, style: const TextStyle(fontWeight: FontWeight.bold)),
                Text('NIS / ID: $childUsername', style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withAlpha(26),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              status.toUpperCase(),
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: statusColor),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    try {

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
              if (_requests.isNotEmpty) ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 24.0, right: 24.0, top: 16.0, bottom: 8.0),
                    child: Text(
                      'Status Pengajuan Hubungan',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => _buildRequestItem(_requests[index]),
                    childCount: _requests.length,
                  ),
                ),
              ],
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(left: 24.0, right: 24.0, top: 16.0, bottom: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Daftar Anak Terhubung',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Row(
                        children: [
                          DropdownButton<int>(
                            value: _selectedMonth,
                            underline: const SizedBox(),
                            borderRadius: BorderRadius.circular(8),
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            items: List.generate(12, (i) {
                              const months = ['Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni', 'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'];
                              return DropdownMenuItem(value: i + 1, child: Text(months[i]));
                            }),
                            onChanged: (val) {
                              if (val != null) {
                                setState(() => _selectedMonth = val);
                                _fetchDashboard();
                              }
                            },
                          ),
                          const SizedBox(width: 8),
                          DropdownButton<int>(
                            value: _selectedYear,
                            underline: const SizedBox(),
                            borderRadius: BorderRadius.circular(8),
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            items: List.generate(5, (i) {
                              final y = DateTime.now().year - i;
                              return DropdownMenuItem(value: y, child: Text(y.toString()));
                            }),
                            onChanged: (val) {
                              if (val != null) {
                                setState(() => _selectedYear = val);
                                _fetchDashboard();
                              }
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
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
    } catch (e, stack) {
      debugPrint('CRITICAL: Error in ParentDashboardScreen.build: $e\n$stack');
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 48),
                const SizedBox(height: 16),
                const Text('Terjadi kesalahan saat memuat halaman wali.'),
                const SizedBox(height: 8),
                Text('$e', style: const TextStyle(color: Colors.grey), textAlign: TextAlign.center),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => _fetchDashboard(),
                  child: const Text('Coba Lagi'),
                ),
              ],
            ),
          ),
        ),
      );
    }
  }
}
