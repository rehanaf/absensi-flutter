import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
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

  Future<Map<String, dynamic>?> _getLocationAndPhoto(bool requireLocation, bool needPhoto) async {
    double lat = 0.0;
    double lng = 0.0;
    String? photoPath;

    if (requireLocation) {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          ShadToaster.of(context).show(
            const ShadToast.destructive(description: Text('GPS belum diaktifkan.')),
          );
        }
        return null;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            ShadToaster.of(context).show(
              const ShadToast.destructive(description: Text('Izin GPS ditolak.')),
            );
          }
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          ShadToaster.of(context).show(
            const ShadToast.destructive(description: Text('Izin GPS ditolak permanen.')),
          );
        }
        return null;
      }

      final position = await Geolocator.getCurrentPosition();
      lat = position.latitude;
      lng = position.longitude;
    }

    if (needPhoto) {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.front,
        imageQuality: 70, 
      );

      if (image == null) {
        if (mounted) {
          ShadToaster.of(context).show(
            const ShadToast.destructive(description: Text('Foto wajah wajib diambil.')),
          );
        }
        return null;
      }
      photoPath = image.path;
    }

    return {
      'lat': lat,
      'lng': lng,
      'photoPath': photoPath,
    };
  }

  Future<void> _handleCheckIn(bool requireLocation, bool needPhoto) async {
    setState(() => _isLoadingAction = true);
    try {
      final data = await _getLocationAndPhoto(requireLocation, needPhoto);
      if (data == null) {
        setState(() => _isLoadingAction = false);
        return;
      }

      await _apiService.checkIn(data['lat'], data['lng'], photoPath: data['photoPath']);
      
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
    setState(() => _isLoadingAction = true);
    try {
      // CheckOut never requires photo based on new API logic
      final data = await _getLocationAndPhoto(requireLocation, false);
      if (data == null) {
        setState(() => _isLoadingAction = false);
        return;
      }

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
    setState(() => _isLoadingAction = true);
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.front,
        imageQuality: 50,
      );

      if (image == null) {
        if (mounted) {
          ShadToaster.of(context).show(
            const ShadToast.destructive(description: Text('Pendaftaran wajah dibatalkan.')),
          );
        }
        setState(() => _isLoadingAction = false);
        return;
      }

      final bytes = await image.readAsBytes();
      final base64String = base64Encode(bytes);

      await _apiService.registerFace(base64String);

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
    
    // Photo is only mandatory for check-in if both are true
    final needPhotoForCheckIn = requireFace && requirePhoto;

    final hasFaceBiometric = user != null && user['face_biometric'] != null;

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

                        if (user?['can_attend'] == true) ...[
                          if (!hasFaceBiometric) ...[
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
                                    onTap: _isLoadingAction ? null : () => _handleCheckIn(requireLoc, needPhotoForCheckIn),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF10B981).withValues(alpha: _isLoadingAction ? 0.5 : 1.0),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: _isLoadingAction 
                                      ? const Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)))
                                      : const Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            TwemojiText(text: '📥', style: TextStyle(fontSize: 18)),
                                            SizedBox(width: 8),
                                            Text(
                                              'Absen Masuk', 
                                              style: TextStyle(
                                                fontWeight: FontWeight.w700, 
                                                color: Colors.white
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
                                  onTap: _isLoadingAction ? null : () => _handleCheckOut(requireLoc),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFEF4444).withValues(alpha: _isLoadingAction ? 0.5 : 1.0),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: _isLoadingAction 
                                      ? const Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)))
                                      : const Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            TwemojiText(text: '📤', style: TextStyle(fontSize: 18)),
                                            SizedBox(width: 8),
                                            Text(
                                              'Absen Pulang', 
                                              style: TextStyle(
                                                fontWeight: FontWeight.w700,
                                                color: Colors.white
                                              )
                                            ),
                                          ],
                                        ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 32),
                        ],
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
