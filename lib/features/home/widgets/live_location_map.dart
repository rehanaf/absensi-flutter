import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

class LiveLocationMap extends StatefulWidget {
  final double officeLat;
  final double officeLng;
  final String locationName;
  final double officeRadius;
  final bool isFlexible;
  final Function(bool isInsideArea, Position? currentPos) onLocationUpdate;

  const LiveLocationMap({
    super.key,
    required this.officeLat,
    required this.officeLng,
    this.locationName = 'Area Kantor',
    required this.officeRadius,
    this.isFlexible = false,
    required this.onLocationUpdate,
  });

  @override
  State<LiveLocationMap> createState() => _LiveLocationMapState();
}

class _LiveLocationMapState extends State<LiveLocationMap> {
  final MapController _mapController = MapController();
  StreamSubscription<Position>? _positionStream;
  Position? _currentPosition;
  bool _isInsideArea = false;
  String? _error;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initLocation();
  }

  Future<void> _initLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _error = 'Layanan lokasi tidak aktif.';
          _isLoading = false;
        });
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _error = 'Izin lokasi ditolak.';
            _isLoading = false;
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _error = 'Izin lokasi ditolak permanen.';
          _isLoading = false;
        });
        return;
      }

      // Get initial position first to center map quickly
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      _updatePosition(pos);

      // Start listening to location updates
      _positionStream = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 5, // update every 5 meters
        ),
      ).listen((Position position) {
        _updatePosition(position);
      });
    } catch (e) {
      setState(() {
        _error = 'Gagal mendapatkan lokasi: $e';
        _isLoading = false;
      });
    }
  }

  void _updatePosition(Position pos) {
    if (!mounted) return;
    
    final distance = Geolocator.distanceBetween(
      pos.latitude,
      pos.longitude,
      widget.officeLat,
      widget.officeLng,
    );

    final isInside = widget.isFlexible ? true : (distance <= widget.officeRadius);

    setState(() {
      _currentPosition = pos;
      _isInsideArea = isInside;
      _isLoading = false;
    });

    widget.onLocationUpdate(isInside, pos);
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        height: 200,
        decoration: BoxDecoration(
          color: ShadTheme.of(context).colorScheme.muted,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Container(
        height: 200,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.red.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.red.withValues(alpha: 0.5)),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.location_off, color: Colors.red, size: 32),
              const SizedBox(height: 8),
              Text(_error!, style: const TextStyle(color: Colors.red), textAlign: TextAlign.center),
              const SizedBox(height: 12),
              ShadButton.outline(
                onPressed: () {
                  setState(() {
                    _isLoading = true;
                    _error = null;
                  });
                  _initLocation();
                },
                child: const Text('Coba Lagi'),
              ),
            ],
          ),
        ),
      );
    }

    final officeLatLng = LatLng(widget.officeLat, widget.officeLng);
    final currentLatLng = _currentPosition != null 
        ? LatLng(_currentPosition!.latitude, _currentPosition!.longitude)
        : officeLatLng;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: _isInsideArea 
                ? const Color(0xFF10B981).withValues(alpha: 0.1) 
                : const Color(0xFFEF4444).withValues(alpha: 0.1),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            border: Border.all(
              color: _isInsideArea ? const Color(0xFF10B981) : const Color(0xFFEF4444),
            ),
          ),
          child: Row(
            children: [
              Icon(
                _isInsideArea ? Icons.check_circle : Icons.cancel,
                color: _isInsideArea ? const Color(0xFF10B981) : const Color(0xFFEF4444),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.isFlexible ? 'Lokasi Fleksibel Aktif' : widget.locationName,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                    Text(
                      widget.isFlexible 
                          ? 'Bebas melakukan absen dari mana saja' 
                          : (_isInsideArea ? 'Anda berada di dalam jangkauan' : 'Anda berada di luar jangkauan'),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: _isInsideArea ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 200,
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: currentLatLng,
                initialZoom: 16.0,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.absensi',
                ),
                if (!widget.isFlexible)
                  CircleLayer(
                    circles: [
                      CircleMarker(
                        point: officeLatLng,
                        color: Colors.blue.withValues(alpha: 0.3),
                        borderColor: Colors.blue,
                        borderStrokeWidth: 2,
                        radius: widget.officeRadius, // Radius in meters
                        useRadiusInMeter: true,
                      ),
                    ],
                  ),
                MarkerLayer(
                  markers: [
                    if (_currentPosition != null)
                      Marker(
                        point: currentLatLng,
                        width: 40,
                        height: 40,
                        child: const Icon(Icons.person_pin_circle, color: Colors.red, size: 40),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
