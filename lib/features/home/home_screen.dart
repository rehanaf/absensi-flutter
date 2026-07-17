import 'package:absensi/core/config.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import '../../core/config.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'widgets/live_location_map.dart';
import '../attendance/face_camera_export.dart';
import '../../providers/auth_provider.dart';
import '../../providers/app_settings_provider.dart';
import '../../data/services/api_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  ImageProvider? _getAvatarImage(Map<String, dynamic>? user) {
    final avatarPath = user?['profile']?['avatar'];
    if (avatarPath != null && avatarPath.toString().isNotEmpty) {
      final String fullUrl = avatarPath.toString().startsWith('http')
          ? avatarPath.toString()
          : AppConfig.baseUrl.replaceAll('/api', '') + '/storage/$avatarPath';
      return NetworkImage('$fullUrl?v=${user?['profile']?['updated_at'] ?? user?['updated_at'] ?? ''}');
    }
    return null;
  }

  final ApiService _apiService = ApiService();
  bool _isLoadingAction = false;

  bool _isInsideArea = false;
  Position? _currentPos;
  bool _isFetching = true;
  Map<String, dynamic>? _dashboardData;
  String? _error;
  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;

  @override
  void initState() {
    super.initState();
    _fetchDashboard();
  }

  Future<void> _fetchDashboard() async {
    setState(() {
      _isFetching = true;
      _error = null;
    });
    try {
      final res = await _apiService.getUserDashboard(
        month: _selectedMonth,
        year: _selectedYear,
      );
      if (mounted) {
        setState(() {
          _dashboardData = res;
          _isFetching = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isFetching = false;
        });
      }
    }
  }

  Future<Map<String, dynamic>?> _getValidAttendanceData(
    bool requireLocation,
    bool needPhoto,
    String cameraTitle, {
    String? registeredFaceBase64,
  }) async {
    double lat = 0.0;
    double lng = 0.0;
    String? photoPath;

    if (requireLocation) {
      if (_currentPos == null) {
        if (mounted)
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Menunggu data lokasi akurat...')),
          );
        return null;
      }
      if (!_isInsideArea) {
        if (mounted)
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Gagal: Anda berada di luar area kantor!'),
            ),
          );
        return null;
      }
      lat = _currentPos!.latitude;
      lng = _currentPos!.longitude;
    }

    if (needPhoto) {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => FaceCameraScreen(
            title: cameraTitle,
            registeredFaceBase64: registeredFaceBase64,
          ),
        ),
      );

      if (result == null || result['path'] == null) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Proses dibatalkan.')));
        }
        return null;
      }
      photoPath = result['path'];
    }

    return {'lat': lat, 'lng': lng, 'photoPath': photoPath};
  }

  Future<void> _handleCheckIn(bool requireLocation, bool needPhoto) async {
    try {
      final user = Provider.of<AuthProvider>(context, listen: false).user;
      final settings = Provider.of<AppSettingsProvider>(context, listen: false);

      final registeredFaceBase64 =
          (settings.attendanceMode == 'recognition' && user != null)
          ? user['face_biometric']?.toString()
          : null;

      final data = await _getValidAttendanceData(
        requireLocation,
        needPhoto,
        'Absen Masuk',
        registeredFaceBase64: registeredFaceBase64,
      );
      if (data == null) {
        setState(() => _isLoadingAction = false);
        return;
      }

      final photoToSend = data['photoPath'];

      setState(() => _isLoadingAction = true);
      await _apiService.checkIn(
        data['lat'],
        data['lng'],
        photoPath: photoToSend,
      );

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Check in berhasil!')));
        _fetchDashboard();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal: ${e.toString()}')));
      }
    } finally {
      if (mounted) setState(() => _isLoadingAction = false);
    }
  }

  Future<void> _handleCheckOut(bool requireLocation) async {
    try {
      final user = Provider.of<AuthProvider>(context, listen: false).user;
      final settings = Provider.of<AppSettingsProvider>(context, listen: false);
      final registeredFaceBase64 =
          (settings.attendanceMode == 'recognition' && user != null)
          ? user['face_biometric']?.toString()
          : null;

      final needCamera =
          settings.attendanceMode == 'selfie' ||
          (settings.attendanceMode == 'recognition' &&
              registeredFaceBase64 != null);
      final data = await _getValidAttendanceData(
        requireLocation,
        needCamera,
        'Absen Pulang',
        registeredFaceBase64: registeredFaceBase64,
      );
      if (data == null) {
        setState(() => _isLoadingAction = false);
        return;
      }

      setState(() => _isLoadingAction = true);
      await _apiService.checkOut(
        data['lat'],
        data['lng'],
        photoPath: data['photoPath'],
      );

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Check out berhasil!')));
        _fetchDashboard();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal: ${e.toString()}')));
      }
    } finally {
      if (mounted) setState(() => _isLoadingAction = false);
    }
  }

  Future<void> _handleRegisterFace() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const FaceCameraScreen(title: 'Daftar Wajah'),
      ),
    );

    if (result == null || result['base64'] == null) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pendaftaran wajah dibatalkan.')),
        );
      return;
    }

    setState(() => _isLoadingAction = true);
    try {
      await _apiService.registerFace(result['base64']);

      if (mounted) {
        final auth = Provider.of<AuthProvider>(context, listen: false);
        await auth.checkAuthStatus();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Wajah berhasil didaftarkan!')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal mendaftarkan wajah: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoadingAction = false);
    }
  }

  String _getDayName(int weekday) {
    const days = [
      'Senin',
      'Selasa',
      'Rabu',
      'Kamis',
      'Jumat',
      'Sabtu',
      'Minggu',
    ];
    return days[weekday - 1];
  }

  String _getMonthName(int month) {
    const months = [
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember',
    ];
    return months[month - 1];
  }

  Widget _buildProfileCard({
    required Map<String, dynamic>? user,
    required bool isMobile,
    required bool canCheckIn,
    required bool canCheckOut,
    required bool requireLoc,
    required bool needCameraForCheckIn,
    required bool needFaceBiometric,
    required bool hasFaceBiometric,
    required String todayStatus,
    required Map<String, dynamic>? todayData,
  }) {
    final String name = user?['name'] ?? 'User';
    final String username = user?['username'] ?? '-';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Load avatar and card preset from backend profile
    final profile = user?['profile'];
    final metaData = profile?['meta_data'];
    final String? cardPreset = metaData?['card_preset'];
    final avatarImage = _getAvatarImage(user);

    // Map presets to gradients
    final cardPresets = {
      'blue': [const Color(0xFF3B82F6), const Color(0xFF1D4ED8)],
      'orange': [const Color(0xFFF97316), const Color(0xFFC2410C)],
      'green': [const Color(0xFF0D9488), const Color(0xFF115E59)],
      'purple': [const Color(0xFF6366F1), const Color(0xFF4338CA)],
      'rose': [const Color(0xFFEC4899), const Color(0xFFBE185D)],
      'slate': [const Color(0xFF475569), const Color(0xFF1E293B)],
    };

    List<Color> gradientColors = [
      Theme.of(context).colorScheme.primary,
      Theme.of(context).colorScheme.primary.withRed(100).withBlue(200),
    ];

    if (cardPreset != null && cardPresets.containsKey(cardPreset)) {
      gradientColors = cardPresets[cardPreset]!;
    }

    final bool isCardColored = true;

    // Determine status text
    String statusText = 'Belum Absen';
    Color statusBadgeColor = Colors.white.withOpacity(0.2);
    if (todayStatus == 'hadir') {
      statusText = 'HADIR';
      if (todayData?['check_in'] != null) {
        final ci = todayData!['check_in'].toString().substring(0, 5);
        final co = todayData['check_out'] != null
            ? todayData['check_out'].toString().substring(0, 5)
            : '--:--';
        statusText = 'HADIR ($ci - $co)';
      }
      statusBadgeColor = Colors.green[700]!.withOpacity(0.4);
    } else if (todayStatus == 'izin' ||
        todayStatus == 'sakit' ||
        todayStatus == 'cuti') {
      statusText = todayStatus.toUpperCase();
      statusBadgeColor = Colors.orange[700]!.withOpacity(0.4);
    } else if (todayStatus == 'libur') {
      statusText = 'LIBUR / HARI NON-AKTIF';
      statusBadgeColor = Colors.grey[700]!.withOpacity(0.4);
    }

    final boxDec = BoxDecoration(
      borderRadius: BorderRadius.circular(24),
      gradient: LinearGradient(
        colors: gradientColors,
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      boxShadow: [
        BoxShadow(
          color: gradientColors.first.withOpacity(isDark ? 0.05 : 0.2),
          blurRadius: 16,
          offset: const Offset(0, 8),
        ),
      ],
    );

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: boxDec,
      child: Stack(
        children: [
          // Background decorative circular shapes
          Positioned(
            right: -24,
            top: -24,
            child: CircleAvatar(
              radius: 64,
              backgroundColor: Colors.white.withOpacity(0.08),
            ),
          ),
          Positioned(
            left: -12,
            bottom: -32,
            child: CircleAvatar(
              radius: 48,
              backgroundColor: Colors.white.withOpacity(0.05),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // User Details Row (Avatar on Left, Name & Username on Right)
                Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2.5),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.15),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: CircleAvatar(
                        radius: 36,
                        backgroundColor: Colors.white,
                        backgroundImage: avatarImage,
                        child: avatarImage == null
                            ? Text(
                                name.isNotEmpty ? name[0].toUpperCase() : 'U',
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 28,
                                ),
                              )
                            : null,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            name,
                            style: TextStyle(
                              color: isCardColored
                                  ? Colors.white
                                  : Theme.of(context).colorScheme.onSurface,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            username,
                            style: TextStyle(
                              color: isCardColored
                                  ? Colors.white.withOpacity(0.85)
                                  : Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),
                Divider(
                  color: isCardColored
                      ? Colors.white.withOpacity(0.2)
                      : Theme.of(context).dividerColor.withOpacity(0.2),
                  height: 1,
                ),
                const SizedBox(height: 16),

                // Official Schedule Hours Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Column(
                      children: [
                        Text(
                          'Jadwal Masuk',
                          style: TextStyle(
                            color: isCardColored
                                ? Colors.white70
                                : Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                            fontSize: 11,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _dashboardData?['schedule_in'] ?? '--:--',
                          style: TextStyle(
                            color: isCardColored
                                ? Colors.white
                                : Theme.of(context).colorScheme.onSurface,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      height: 24,
                      width: 1,
                      color: isCardColored
                          ? Colors.white.withOpacity(0.2)
                          : Theme.of(context).dividerColor.withOpacity(0.2),
                    ),
                    Column(
                      children: [
                        Text(
                          'Jadwal Pulang',
                          style: TextStyle(
                            color: isCardColored
                                ? Colors.white70
                                : Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                            fontSize: 11,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _dashboardData?['schedule_out'] ?? '--:--',
                          style: TextStyle(
                            color: isCardColored
                                ? Colors.white
                                : Theme.of(context).colorScheme.onSurface,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 16),
                Divider(
                  color: isCardColored
                      ? Colors.white.withOpacity(0.2)
                      : Theme.of(context).dividerColor.withOpacity(0.2),
                  height: 1,
                ),
                const SizedBox(height: 16),

                // Attendance Status Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Status Hari Ini:',
                      style: TextStyle(
                        color: isCardColored
                            ? Colors.white
                            : Theme.of(context).colorScheme.onSurface,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: statusBadgeColor,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isCardColored
                              ? Colors.white.withOpacity(0.3)
                              : Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        statusText,
                        style: TextStyle(
                          color: isCardColored
                              ? Colors.white
                              : Theme.of(context).colorScheme.onSurface,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Attendance Action Buttons
                if (user?['can_attend'] == true) ...[
                  if (needFaceBiometric && !hasFaceBiometric) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.warning,
                                color: Colors.amber,
                                size: 18,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Wajah belum terdaftar!',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Harap daftarkan wajah Anda terlebih dahulu.',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 11,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 10),
                          ElevatedButton.icon(
                            onPressed: _isLoadingAction
                                ? null
                                : _handleRegisterFace,
                            icon: _isLoadingAction
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.red,
                                    ),
                                  )
                                : const Icon(Icons.camera_alt),
                            label: const Text('Daftarkan Wajah'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.red[800],
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: (_isLoadingAction || !canCheckIn)
                                ? null
                                : () => _handleCheckIn(
                                    requireLoc,
                                    needCameraForCheckIn,
                                  ),
                            icon: _isLoadingAction
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.green,
                                    ),
                                  )
                                : const Icon(Icons.login),
                            label: const Text('Masuk'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: canCheckIn
                                  ? (isCardColored
                                        ? Colors.white
                                        : Theme.of(context).colorScheme.primary)
                                  : (isCardColored
                                        ? Colors.white.withOpacity(0.2)
                                        : Theme.of(context).colorScheme.primary
                                              .withOpacity(0.12)),
                              foregroundColor: canCheckIn
                                  ? (isCardColored
                                        ? const Color(0xFF0F172A)
                                        : Theme.of(
                                            context,
                                          ).colorScheme.onPrimary)
                                  : (isCardColored
                                        ? Colors.white.withOpacity(0.4)
                                        : Theme.of(context)
                                              .colorScheme
                                              .onSurface
                                              .withOpacity(0.38)),
                              disabledBackgroundColor: isDark
                                  ? Theme.of(context).colorScheme.surfaceVariant
                                        .withOpacity(0.1)
                                  : Colors.white.withOpacity(0.1),
                              disabledForegroundColor: isDark
                                  ? Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant
                                        .withOpacity(0.3)
                                  : Colors.white.withOpacity(0.3),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: (_isLoadingAction || !canCheckOut)
                                ? null
                                : () => _handleCheckOut(requireLoc),
                            icon: _isLoadingAction
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.red,
                                    ),
                                  )
                                : const Icon(Icons.logout),
                            label: const Text('Pulang'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: canCheckOut
                                  ? (isCardColored
                                        ? Colors.white
                                        : Theme.of(context).colorScheme.primary)
                                  : (isCardColored
                                        ? Colors.white.withOpacity(0.2)
                                        : Theme.of(context).colorScheme.primary
                                              .withOpacity(0.12)),
                              foregroundColor: canCheckOut
                                  ? (isCardColored
                                        ? const Color(0xFF0F172A)
                                        : Theme.of(
                                            context,
                                          ).colorScheme.onPrimary)
                                  : (isCardColored
                                        ? Colors.white.withOpacity(0.4)
                                        : Theme.of(context)
                                              .colorScheme
                                              .onSurface
                                              .withOpacity(0.38)),
                              disabledBackgroundColor: isDark
                                  ? Theme.of(context).colorScheme.surfaceVariant
                                        .withOpacity(0.1)
                                  : Colors.white.withOpacity(0.1),
                              disabledForegroundColor: isDark
                                  ? Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant
                                        .withOpacity(0.3)
                                  : Colors.white.withOpacity(0.3),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthlyCalendar() {
    try {
      final monthAttendance = _dashboardData?['month_attendance'];
      if (monthAttendance is! List || monthAttendance.isEmpty)
        return const SizedBox.shrink();

      final DateTime now = DateTime.now();
      final List<String> weekdays = [
        'Sen',
        'Sel',
        'Rab',
        'Kam',
        'Jum',
        'Sab',
        'Min',
      ];

      // Find the weekday of the first day of this month
      final DateTime firstDayOfMonth = DateTime(now.year, now.month, 1);
      final int firstWeekday = firstDayOfMonth.weekday; // 1 = Mon, 7 = Sun
      final int prefixEmptyCells = firstWeekday - 1;

      // Total cells in the grid = empty cells + days in month
      final int totalCells = prefixEmptyCells + monthAttendance.length;

      final isDarkCal = Theme.of(context).brightness == Brightness.dark;
      return Container(
        decoration: BoxDecoration(
          color: isDarkCal
              ? Theme.of(
                  context,
                ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5)
              : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: isDarkCal
              ? null
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 10,
                    spreadRadius: 1,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.calendar_month,
                    color: Theme.of(context).colorScheme.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Kehadiran Bulan Ini',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
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

                    final int dayNum =
                        int.tryParse(dayData['day']?.toString() ?? '') ??
                        (dayIndex + 1);
                    final String status =
                        dayData['status']?.toString() ?? 'absen';
                    final String dateStr = dayData['date']?.toString() ?? '';

                    // Determine if this day is in the future
                    bool isFuture = false;
                    try {
                      if (dateStr.isNotEmpty) {
                        final dayDate = DateTime.parse(dateStr);
                        final todayDate = DateTime(
                          now.year,
                          now.month,
                          now.day,
                        );
                        if (dayDate.isAfter(todayDate)) {
                          isFuture = true;
                        }
                      }
                    } catch (_) {}

                    Color? textColor;
                    BoxDecoration? decoration;

                    if (isFuture) {
                      textColor = Theme.of(
                        context,
                      ).colorScheme.onSurfaceVariant.withValues(alpha: 0.3);
                    } else {
                      if (status == 'hadir') {
                        textColor = Colors.white;
                        decoration = const BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                        );
                      } else if (status == 'sakit' ||
                          status == 'izin' ||
                          status == 'cuti') {
                        textColor = Colors.white;
                        decoration = const BoxDecoration(
                          color: Colors.orange,
                          shape: BoxShape.circle,
                        );
                      } else if (status == 'libur') {
                        textColor = Theme.of(
                          context,
                        ).colorScheme.onSurfaceVariant.withValues(alpha: 0.5);
                        decoration = BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .surfaceContainerHighest
                              .withValues(alpha: 0.8),
                          shape: BoxShape.circle,
                        );
                      } else {
                        // Absen (Tidak Hadir)
                        textColor = Colors.white;
                        decoration = const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
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
                    debugPrint('Error rendering day $index: $e');
                    return const SizedBox.shrink();
                  }
                },
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      debugPrint('Error building monthly calendar: $e');
      return const SizedBox.shrink();
    }
  }

  Widget _buildStatCard(
    String title,
    String value,
    Color color,
    IconData icon,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? Theme.of(
                context,
              ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5)
            : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 10,
                  spreadRadius: 1,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 32),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: color,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    try {
      final auth = Provider.of<AuthProvider>(context);
      final settings = Provider.of<AppSettingsProvider>(context);
      final user = auth.user;

      final latestSettings = _dashboardData?['settings'];
      final requireLoc =
          latestSettings?['require_location']?.toString() == '1' ||
          latestSettings?['require_location']?.toString().toLowerCase() ==
              'true' ||
          settings.requireLocation;
      final attendanceMode =
          latestSettings?['attendance_mode']?.toString() ??
          settings.attendanceMode;

      final latestUser = _dashboardData?['user'] ?? user;
      final needCameraForCheckIn =
          attendanceMode == 'selfie' || attendanceMode == 'recognition';
      final needFaceBiometric = attendanceMode == 'recognition';
      final hasFaceBiometric =
          latestUser != null &&
          latestUser['face_biometric'] != null &&
          latestUser['face_biometric'].toString().trim().isNotEmpty &&
          latestUser['face_biometric'].toString().trim() != 'null';

      final todayStatus = _dashboardData?['today_status'] ?? 'belum_absen';
      final todayData = _dashboardData?['today_data'];

      final bool canCheckIn = todayStatus == 'belum_absen';
      final bool canCheckOut =
          todayStatus == 'hadir' &&
          todayData != null &&
          todayData['check_out'] == null;

      final bool isLocationFlexible =
          user?['is_location_flexible'] == true ||
          user?['is_location_flexible'] == 1;
      final Map<String, dynamic>? userLocation = user?['location'];

      double targetLat = settings.officeLat;
      double targetLng = settings.officeLng;
      String targetLocationName = settings.locationName;
      double targetRadius = settings.officeRadius;

      if (userLocation != null) {
        targetLat =
            double.tryParse(userLocation['latitude']?.toString() ?? '') ??
            targetLat;
        targetLng =
            double.tryParse(userLocation['longitude']?.toString() ?? '') ??
            targetLng;
        targetLocationName = userLocation['name'] ?? targetLocationName;
        targetRadius =
            double.tryParse(userLocation['radius']?.toString() ?? '') ??
            targetRadius;
      }

      return LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 600;

          // --- Helper for Stat Cards ---
          Widget buildStatCards() {
            final cards = [
              _buildStatCard(
                'Hadir',
                '${_dashboardData?['total_attendances'] ?? 0}',
                Colors.green,
                Icons.check_circle,
              ),
              _buildStatCard(
                'Izin',
                '${_dashboardData?['total_permits'] ?? 0}',
                Colors.orange,
                Icons.assignment,
              ),
              _buildStatCard(
                'Terlambat',
                '${_dashboardData?['total_lates'] ?? 0}',
                Colors.redAccent,
                Icons.timer_off,
              ),
              _buildStatCard(
                'Alpa',
                '${_dashboardData?['total_alpa'] ?? 0}',
                Colors.red,
                Icons.cancel,
              ),
            ];

            if (isMobile) {
              return Column(
                children: [
                  cards[0],
                  const SizedBox(height: 12),
                  cards[1],
                  const SizedBox(height: 12),
                  cards[2],
                  const SizedBox(height: 12),
                  cards[3],
                ],
              );
            } else {
              return Row(
                children: [
                  Expanded(child: cards[0]),
                  const SizedBox(width: 16),
                  Expanded(child: cards[1]),
                  const SizedBox(width: 16),
                  Expanded(child: cards[2]),
                  const SizedBox(width: 16),
                  Expanded(child: cards[3]),
                ],
              );
            }
          }

          // --- Helper for History ---
          Widget buildHistory() {
            final isDark = Theme.of(context).brightness == Brightness.dark;
            final historyList =
                (_dashboardData?['recent_history'] as List?) ?? [];
            final listWidget = historyList.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32.0),
                      child: Text(
                        'Belum ada riwayat',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  )
                : Container(
                    decoration: BoxDecoration(
                      color: isDark
                          ? Theme.of(context)
                                .colorScheme
                                .surfaceContainerHighest
                                .withValues(alpha: 0.5)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: isDark
                          ? null
                          : [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.04),
                                blurRadius: 10,
                                spreadRadius: 1,
                                offset: const Offset(0, 4),
                              ),
                            ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      children: [
                        Container(
                          color: isDark
                              ? Theme.of(context)
                                    .colorScheme
                                    .surfaceContainerHighest
                                    .withValues(alpha: 0.3)
                              : const Color(0xFFF1F5F9),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 2,
                                child: Text(
                                  'Tanggal',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  'Masuk',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  'Pulang',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  'Status',
                                  textAlign: TextAlign.right,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Divider(height: 1),
                        ...historyList.asMap().entries.map((entry) {
                          final int idx = entry.key;
                          final h = entry.value;
                          final rawDate = h['date']?.toString() ?? '-';
                          final checkIn = h['check_in'] ?? '--:--';
                          final checkOut = h['check_out'] ?? '--:--';
                          final status = h['status'] ?? '-';

                          Color badgeBg = Theme.of(
                            context,
                          ).colorScheme.primaryContainer;
                          Color badgeText = Theme.of(
                            context,
                          ).colorScheme.onPrimaryContainer;
                          if (status == 'hadir') {
                            badgeBg = Colors.green.withValues(alpha: 0.1);
                            badgeText = Colors.green[800]!;
                          }
                          if (status == 'sakit' || status == 'izin') {
                            badgeBg = Colors.orange.withValues(alpha: 0.1);
                            badgeText = Colors.orange[800]!;
                          }
                          if (status == 'alpha') {
                            badgeBg = Colors.red.withValues(alpha: 0.1);
                            badgeText = Colors.red[800]!;
                          }

                          return Column(
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      flex: 2,
                                      child: Text(
                                        rawDate,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Text(
                                        checkIn,
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(fontSize: 13),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Text(
                                        checkOut,
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(fontSize: 13),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Align(
                                        alignment: Alignment.centerRight,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: badgeBg,
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          child: Text(
                                            status.toString().toUpperCase(),
                                            style: TextStyle(
                                              color: badgeText,
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (idx < historyList.length - 1)
                                const Divider(height: 1),
                            ],
                          );
                        }),
                      ],
                    ),
                  );

            if (isMobile) {
              return listWidget;
            } else {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: listWidget),
                  const SizedBox(width: 16),
                  const Expanded(child: SizedBox()),
                ],
              );
            }
          } // --- Helper for Locations & Kehadiran (Responsive) ---

          Widget buildLokasiKehadiran() {
            if (isMobile) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (requireLoc) ...[
                    Text(
                      'Lokasi Anda',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: LiveLocationMap(
                        officeLat: targetLat,
                        officeLng: targetLng,
                        locationName: targetLocationName,
                        officeRadius: targetRadius,
                        isFlexible: isLocationFlexible,
                        onLocationUpdate: (isInside, pos) {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (mounted) {
                              setState(() {
                                _isInsideArea = isInside;
                                _currentPos = pos;
                              });
                            }
                          });
                        },
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                  Text(
                    'Kehadiran',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildMonthlyCalendar(),
                ],
              );
            } else {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (requireLoc)
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Lokasi Anda',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 16),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: LiveLocationMap(
                              officeLat: targetLat,
                              officeLng: targetLng,
                              locationName: targetLocationName,
                              officeRadius: targetRadius,
                              isFlexible: isLocationFlexible,
                              onLocationUpdate: (isInside, pos) {
                                WidgetsBinding.instance.addPostFrameCallback((
                                  _,
                                ) {
                                  if (mounted) {
                                    setState(() {
                                      _isInsideArea = isInside;
                                      _currentPos = pos;
                                    });
                                  }
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (requireLoc) const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Kehadiran',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 16),
                        _buildMonthlyCalendar(),
                      ],
                    ),
                  ),
                ],
              );
            }
          }

          // --- Layout Start ---
          return Scaffold(
            body: SafeArea(
              child: RefreshIndicator(
                onRefresh: _fetchDashboard,
                child: _isFetching
                    ? const Center(child: CircularProgressIndicator())
                    : _error != null
                    ? ListView(
                        padding: const EdgeInsets.all(16.0),
                        children: [
                          Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Gagal memuat data',
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _error!,
                                  style: const TextStyle(color: Colors.red),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 16),
                                FilledButton.tonal(
                                  onPressed: _fetchDashboard,
                                  child: const Text('Coba Lagi'),
                                ),
                              ],
                            ),
                          ),
                        ],
                      )
                    : SingleChildScrollView(
                        padding: EdgeInsets.zero,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Header Section
                            _buildProfileCard(
                              user: latestUser,
                              isMobile: isMobile,
                              canCheckIn: canCheckIn,
                              canCheckOut: canCheckOut,
                              requireLoc: requireLoc,
                              needCameraForCheckIn: needCameraForCheckIn,
                              needFaceBiometric: needFaceBiometric,
                              hasFaceBiometric: hasFaceBiometric,
                              todayStatus: todayStatus,
                              todayData: todayData,
                            ),

                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16.0,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  // 3. Lokasi & Kehadiran
                                  buildLokasiKehadiran(),
                                  const SizedBox(height: 32),

                                  // 4. Statistik dengan Dropdown
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Statistik',
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.bold,
                                            ),
                                      ),
                                      Row(
                                        children: [
                                          DropdownButton<int>(
                                            value: _selectedMonth,
                                            underline: const SizedBox(),
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                            ),
                                            items: List.generate(12, (i) {
                                              const months = [
                                                'Januari',
                                                'Februari',
                                                'Maret',
                                                'April',
                                                'Mei',
                                                'Juni',
                                                'Juli',
                                                'Agustus',
                                                'September',
                                                'Oktober',
                                                'November',
                                                'Desember',
                                              ];
                                              return DropdownMenuItem(
                                                value: i + 1,
                                                child: Text(months[i]),
                                              );
                                            }),
                                            onChanged: (val) {
                                              if (val != null) {
                                                setState(
                                                  () => _selectedMonth = val,
                                                );
                                                _fetchDashboard();
                                              }
                                            },
                                          ),
                                          const SizedBox(width: 8),
                                          DropdownButton<int>(
                                            value: _selectedYear,
                                            underline: const SizedBox(),
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                            ),
                                            items: List.generate(5, (i) {
                                              final y = DateTime.now().year - i;
                                              return DropdownMenuItem(
                                                value: y,
                                                child: Text(y.toString()),
                                              );
                                            }),
                                            onChanged: (val) {
                                              if (val != null) {
                                                setState(
                                                  () => _selectedYear = val,
                                                );
                                                _fetchDashboard();
                                              }
                                            },
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  buildStatCards(),
                                  const SizedBox(height: 32),

                                  // 5. Riwayat Terbaru
                                  Text(
                                    'Riwayat Terbaru',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 16),
                                  buildHistory(),
                                  const SizedBox(height: 32),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
              ),
            ),
          );
        },
      );
    } catch (e, stack) {
      debugPrint('CRITICAL: Error in HomeScreen.build: $e\n$stack');
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 48),
                const SizedBox(height: 16),
                const Text('Terjadi kesalahan saat memuat halaman beranda.'),
                const SizedBox(height: 8),
                Text(
                  '$e',
                  style: const TextStyle(color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
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
