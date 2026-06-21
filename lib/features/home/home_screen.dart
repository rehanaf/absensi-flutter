import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geolocator/geolocator.dart';
import 'widgets/live_location_map.dart';
import '../attendance/face_camera_screen.dart';
import '../../providers/auth_provider.dart';
import '../../providers/app_settings_provider.dart';
import '../../data/services/api_service.dart';
import '../../core/widgets/twemoji_text.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoadingAction = false;
  
  bool _isInsideArea = false;
  Position? _currentPos;
  bool _isFetching = true;
  Map<String, dynamic>? _dashboardData;
  String? _error;

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
      final res = await _apiService.getUserDashboard();
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

  Future<Map<String, dynamic>?> _getValidAttendanceData(bool requireLocation, bool needPhoto, String cameraTitle, {String? registeredFaceBase64}) async {
    double lat = 0.0;
    double lng = 0.0;
    String? photoPath;

    if (requireLocation) {
      if (_currentPos == null) {
        if (mounted) ShadToaster.of(context).show(const ShadToast.destructive(description: Text('Menunggu data lokasi akurat...')));
        return null;
      }
      if (!_isInsideArea) {
        if (mounted) ShadToaster.of(context).show(const ShadToast.destructive(description: Text('Gagal: Anda berada di luar area kantor!')));
        return null;
      }
      lat = _currentPos!.latitude;
      lng = _currentPos!.longitude;
    }

    if (needPhoto) {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => FaceCameraScreen(title: cameraTitle, registeredFaceBase64: registeredFaceBase64)),
      );

      if (result == null || result['path'] == null) {
        if (mounted) {
          ShadToaster.of(context).show(
            const ShadToast.destructive(description: Text('Proses dibatalkan.')),
          );
        }
        return null;
      }
      photoPath = result['path'];
    }

    return {
      'lat': lat,
      'lng': lng,
      'photoPath': photoPath,
    };
  }

  Future<void> _handleCheckIn(bool requireLocation, bool needPhoto) async {
    try {
      final user = Provider.of<AuthProvider>(context, listen: false).user;
      final settings = Provider.of<AppSettingsProvider>(context, listen: false);
      
      // Only perform verification if requireFace is true
      final registeredFaceBase64 = (settings.requireFace && user != null) ? user['face_biometric']?.toString() : null;

      final data = await _getValidAttendanceData(requireLocation, needPhoto, 'Absen Masuk', registeredFaceBase64: registeredFaceBase64);
      if (data == null) {
        setState(() => _isLoadingAction = false);
        return;
      }

      // Only send photo to backend if requirePhoto is true
      final photoToSend = settings.requirePhoto ? data['photoPath'] : null;

      setState(() => _isLoadingAction = true);
      await _apiService.checkIn(data['lat'], data['lng'], photoPath: photoToSend);
      
      if (mounted) {
        ShadToaster.of(context).show(
          const ShadToast(description: Text('Check in berhasil!')),
        );
        _fetchDashboard();
      }
    } catch (e) {
      if (mounted) {
        ShadToaster.of(context).show(
          ShadToast.destructive(description: Text('Gagal: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoadingAction = false);
    }
  }

  Future<void> _handleCheckOut(bool requireLocation) async {
    try {
      final user = Provider.of<AuthProvider>(context, listen: false).user;
      final settings = Provider.of<AppSettingsProvider>(context, listen: false);
      final registeredFaceBase64 = (settings.requireFace && user != null) ? user['face_biometric']?.toString() : null;

      // CheckOut never requires photo based on new API logic
      final data = await _getValidAttendanceData(requireLocation, false, 'Absen Pulang', registeredFaceBase64: registeredFaceBase64);
      if (data == null) {
        setState(() => _isLoadingAction = false);
        return;
      }

      setState(() => _isLoadingAction = true);
      await _apiService.checkOut(data['lat'], data['lng'], photoPath: data['photoPath']);
      
      if (mounted) {
        ShadToaster.of(context).show(
          const ShadToast(description: Text('Check out berhasil!')),
        );
        _fetchDashboard();
      }
    } catch (e) {
      if (mounted) {
        ShadToaster.of(context).show(
          ShadToast.destructive(description: Text('Gagal: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoadingAction = false);
    }
  }

  Future<void> _handleRegisterFace() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const FaceCameraScreen(title: 'Daftar Wajah')),
    );

    if (result == null || result['base64'] == null) {
      if (mounted) ShadToaster.of(context).show(const ShadToast.destructive(description: Text('Pendaftaran wajah dibatalkan.')));
      return;
    }

    setState(() => _isLoadingAction = true);
    try {
      await _apiService.registerFace(result['base64']);

      if (mounted) {
        // Update user state locally or refresh
        await Provider.of<AuthProvider>(context, listen: false).checkAuthStatus();
        ShadToaster.of(context).show(
          const ShadToast(description: Text('Wajah berhasil didaftarkan!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ShadToaster.of(context).show(
          ShadToast.destructive(description: Text('Gagal mendaftarkan wajah: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoadingAction = false);
    }
  }

  Widget _buildStatCard(BuildContext context, String title, String value, Color color, String emoji) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: ShadTheme.of(context).colorScheme.border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              TwemojiText(text: emoji, style: const TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
              Expanded(child: Text(title, style: ShadTheme.of(context).textTheme.muted.copyWith(fontSize: 12))),
            ],
          ),
          const SizedBox(height: 12),
          Text(value, style: ShadTheme.of(context).textTheme.h3.copyWith(color: color)),
        ],
      ),
    );
  }

  Widget _buildStatusBanner() {
    final status = _dashboardData?['today_status'] ?? 'belum_absen';
    
    Color bgColor;
    Color textColor;
    String message;
    String emoji;

    if (status == 'hadir') {
      bgColor = Colors.green.withValues(alpha: 0.1);
      textColor = Colors.green[700]!;
      message = 'Anda sudah absen hari ini';
      emoji = '✅';
    } else if (status == 'izin' || status == 'sakit') {
      bgColor = Colors.orange.withValues(alpha: 0.1);
      textColor = Colors.orange[800]!;
      message = 'Anda sedang $status hari ini';
      emoji = '📝';
    } else {
      bgColor = Colors.blue.withValues(alpha: 0.1);
      textColor = Colors.blue[700]!;
      message = 'Anda belum absen hari ini';
      emoji = '👋';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          TwemojiText(text: emoji, style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              message,
              style: TextStyle(fontWeight: FontWeight.w600, color: textColor),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final settings = Provider.of<AppSettingsProvider>(context);
    final user = auth.user;

    final requireLoc = settings.requireLocation;
    final requireFace = settings.requireFace;
    final requirePhoto = settings.requirePhoto;
    
    // Camera opens ONLY if face verification is required
    final needCameraForCheckIn = requireFace;

    final hasFaceBiometric = user != null && user['face_biometric'] != null && user['face_biometric'].toString().trim().isNotEmpty && user['face_biometric'].toString().trim() != 'null';

    final todayStatus = _dashboardData?['today_status'] ?? 'belum_absen';
    final todayData = _dashboardData?['today_data'];
    
    final bool canCheckIn = todayStatus == 'belum_absen';
    final bool canCheckOut = todayStatus == 'hadir' && todayData != null && todayData['check_out'] == null;

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _fetchDashboard,
          child: _isFetching
              ? const Center(child: CircularProgressIndicator())
              : _error != null
                  ? ListView(
                      padding: const EdgeInsets.all(24.0),
                      children: [
                        Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text('Gagal memuat data', style: ShadTheme.of(context).textTheme.large),
                              const SizedBox(height: 8),
                              Text(_error!, style: const TextStyle(color: Colors.red), textAlign: TextAlign.center),
                              const SizedBox(height: 16),
                              ShadButton(onPressed: _fetchDashboard, child: const Text('Coba Lagi')),
                            ],
                          ),
                        )
                      ]
                    )
                  : ListView(
                      padding: const EdgeInsets.all(24.0),
                      children: [
                        Card(
                          elevation: 0,
                          color: ShadTheme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Selamat datang kembali,',
                                  style: ShadTheme.of(context).textTheme.p,
                                ),
                                Text(
                                  user?['name'] ?? 'User',
                                  style: ShadTheme.of(context).textTheme.h3,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        
                        _buildStatusBanner(),
                        const SizedBox(height: 24),

                        if (requireLoc) ...[
                          LiveLocationMap(
                            officeLat: settings.officeLat,
                            officeLng: settings.officeLng,
                            officeRadius: settings.officeRadius,
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
                          const SizedBox(height: 24),
                        ],

                        if (user?['can_attend'] == true) ...[
                          if (requireFace && !hasFaceBiometric) ...[
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.red.withValues(alpha: 0.1),
                                border: Border.all(color: Colors.red.withValues(alpha: 0.5)),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                children: [
                                  const TwemojiText(text: '📸', style: TextStyle(fontSize: 24)),
                                  const SizedBox(height: 8),
                                  const Text(
                                    'Wajah Anda belum terdaftar!',
                                    style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    'Harap daftarkan wajah Anda terlebih dahulu sebelum dapat melakukan absensi.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(fontSize: 12),
                                  ),
                                  const SizedBox(height: 16),
                                  ShadButton(
                                    onPressed: _isLoadingAction ? null : _handleRegisterFace,
                                    child: _isLoadingAction 
                                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                      : const Text('Daftarkan Wajah'),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 32),
                          ] else ...[
                            Row(
                              children: [
                                Expanded(
                                  child: GestureDetector(
                                    onTap: (_isLoadingAction || !canCheckIn) ? null : () => _handleCheckIn(requireLoc, needCameraForCheckIn),
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 200),
                                      padding: const EdgeInsets.symmetric(vertical: 16),
                                      decoration: BoxDecoration(
                                        color: canCheckIn ? const Color(0xFF10B981).withValues(alpha: _isLoadingAction ? 0.5 : 1.0) : Colors.grey.shade300,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: _isLoadingAction 
                                        ? const Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)))
                                        : Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              TwemojiText(text: '📥', style: TextStyle(fontSize: 18, color: canCheckIn ? Colors.white : Colors.grey)),
                                              const SizedBox(width: 8),
                                              Text(
                                                'Absen Masuk', 
                                                style: TextStyle(
                                                  fontWeight: FontWeight.w700, 
                                                  color: canCheckIn ? Colors.white : Colors.grey.shade600
                                                )
                                              ),
                                            ],
                                          ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: GestureDetector(
                                    onTap: (_isLoadingAction || !canCheckOut) ? null : () => _handleCheckOut(requireLoc),
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 200),
                                      padding: const EdgeInsets.symmetric(vertical: 16),
                                      decoration: BoxDecoration(
                                        color: canCheckOut ? const Color(0xFFEF4444).withValues(alpha: _isLoadingAction ? 0.5 : 1.0) : Colors.grey.shade300,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: _isLoadingAction 
                                        ? const Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)))
                                        : Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              TwemojiText(text: '📤', style: TextStyle(fontSize: 18, color: canCheckOut ? Colors.white : Colors.grey)),
                                              const SizedBox(width: 8),
                                              Text(
                                                'Absen Pulang', 
                                                style: TextStyle(
                                                  fontWeight: FontWeight.w700,
                                                  color: canCheckOut ? Colors.white : Colors.grey.shade600
                                                )
                                              ),
                                            ],
                                          ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 32),
                        ],

                        Text('Statistik (${_dashboardData?['month'] ?? '-'})', style: ShadTheme.of(context).textTheme.large),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _buildStatCard(
                                context, 
                                'Total Hadir', 
                                '${_dashboardData?['total_attendances'] ?? 0}', 
                                Colors.green, 
                                '✅'
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildStatCard(
                                context, 
                                'Total Izin', 
                                '${_dashboardData?['total_permits'] ?? 0}', 
                                Colors.orange, 
                                '📝'
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 32),
                        Text('Riwayat Terbaru', style: ShadTheme.of(context).textTheme.large),
                        const SizedBox(height: 16),
                        if (_dashboardData != null && _dashboardData!['recent_history'] != null)
                          ...List.generate(
                            (_dashboardData!['recent_history'] as List).length,
                            (index) {
                              final history = _dashboardData!['recent_history'][index];
                              return Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  border: Border.all(color: ShadTheme.of(context).colorScheme.border),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: [
                                    const TwemojiText(text: '🕒', style: TextStyle(fontSize: 20)),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(history['date'] ?? '-', style: const TextStyle(fontWeight: FontWeight.bold)),
                                          Text('Status: ${history['status'] ?? '-'}', style: ShadTheme.of(context).textTheme.muted),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }
                          )
                        else
                          const Center(child: Text('Belum ada riwayat')),

                      ],
                    ),
        ),
      ),
    );
  }
}
