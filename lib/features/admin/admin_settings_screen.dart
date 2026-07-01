import 'dart:io';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import '../../data/services/api_service.dart';
import '../../providers/app_settings_provider.dart';

class AdminSettingsScreen extends StatefulWidget {
  const AdminSettingsScreen({super.key});

  @override
  State<AdminSettingsScreen> createState() => _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends State<AdminSettingsScreen> {
  final _apiService = ApiService();
  final Map<String, dynamic> _formValues = {};
  final Map<String, TextEditingController> _controllers = {};
  final Map<String, XFile?> _imageFiles = {};
  
  bool _isLoading = false;
  bool _isInitialized = false;

  final ImagePicker _picker = ImagePicker();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      final settingsProvider = Provider.of<AppSettingsProvider>(context, listen: false);
      for (var item in settingsProvider.rawSettings) {
        if (item is Map) {
          final key = item['key'] as String;
          final value = item['value'];
          final type = item['type'] as String;
          
          if (type == 'boolean') {
            _formValues[key] = (value == '1' || value == true);
          } else if (type == 'color') {
            _formValues[key] = value?.toString() ?? '';
          } else if (type == 'image') {
            // Keep image logic separately handled, we track file locally in _imageFiles
          } else {
            _formValues[key] = value?.toString() ?? '';
            _controllers[key] = TextEditingController(text: _formValues[key]);
          }
        }
      }
      _isInitialized = true;
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _pickImage(String key) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        setState(() {
          _imageFiles[key] = pickedFile;
        });
      }
    } catch (e) {
      if (mounted) {
        ShadToaster.of(context).show(ShadToast.destructive(description: Text('Gagal memilih gambar: $e')));
      }
    }
  }

  Future<void> _saveSettings() async {
    setState(() => _isLoading = true);
    try {
      final Map<String, dynamic> payload = {};
      
      // Update text values from controllers
      _controllers.forEach((key, controller) {
        _formValues[key] = controller.text;
      });

      // Serialize payload
      _formValues.forEach((key, value) {
        if (value is bool) {
          payload[key] = value ? '1' : '0';
        } else {
          payload[key] = value;
        }
      });

      // Add image files to payload
      for (var entry in _imageFiles.entries) {
        if (entry.value != null) {
          final bytes = await entry.value!.readAsBytes();
          payload[entry.key] = MultipartFile.fromBytes(bytes, filename: entry.value!.name);
        }
      }

      await _apiService.updateAdminSettings(payload);
      
      if (mounted) {
        // Refresh global settings state
        await Provider.of<AppSettingsProvider>(context, listen: false).fetchSettings();
        
        if (mounted) {
          ShadToaster.of(context).show(
            const ShadToast(description: Text('Pengaturan berhasil disimpan')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ShadToaster.of(context).show(
          ShadToast.destructive(description: Text('Gagal menyimpan: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildField(Map item) {
    final key = item['key'] as String;
    final label = item['label'] as String?;
    final type = item['type'] as String?;
    
    if (type == 'boolean') {
      return Container(
        margin: const EdgeInsets.only(bottom: 24),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: ShadTheme.of(context).colorScheme.border),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(label ?? key, style: const TextStyle(fontWeight: FontWeight.w600)),
            ),
            ShadSwitch(
              value: _formValues[key] == true,
              onChanged: (v) => setState(() => _formValues[key] = v),
            ),
          ],
        ),
      );
    } else if (type == 'select') {
      // Parse options
      List<String> options = [];
      if (item['options'] != null) {
        if (item['options'] is List) {
          options = (item['options'] as List).map((e) => e.toString()).toList();
        } else if (item['options'] is String) {
          try {
            final decoded = jsonDecode(item['options']);
            if (decoded is List) options = decoded.map((e) => e.toString()).toList();
          } catch (_) {}
        }
      }
      return Padding(
        padding: const EdgeInsets.only(bottom: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label ?? key, style: ShadTheme.of(context).textTheme.large),
            const SizedBox(height: 8),
            ShadSelect<String>(
              placeholder: const Text('Pilih Opsi'),
              initialValue: _formValues[key] as String?,
              options: options.map((opt) => ShadOption(value: opt, child: Text(opt.toUpperCase()))).toList(),
              onChanged: (val) {
                if (val != null) {
                  setState(() => _formValues[key] = val);
                }
              },
              selectedOptionBuilder: (context, value) {
                return Text(value.toUpperCase());
              },
            ),
          ],
        ),
      );
    } else if (type == 'color') {
      return Padding(
        padding: const EdgeInsets.only(bottom: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label ?? key, style: ShadTheme.of(context).textTheme.large),
            const SizedBox(height: 8),
            ShadSelect<String>(
              placeholder: const Text('Pilih Warna Tema'),
              initialValue: _formValues[key] as String?,
              options: const [
                ShadOption(value: 'blue', child: Text('🔵 Blue')),
                ShadOption(value: 'zinc', child: Text('🔘 Zinc')),
                ShadOption(value: 'rose', child: Text('🌹 Rose')),
                ShadOption(value: 'violet', child: Text('🟣 Violet')),
                ShadOption(value: 'red', child: Text('🔴 Red')),
                ShadOption(value: 'green', child: Text('🟢 Green')),
                ShadOption(value: 'orange', child: Text('🟠 Orange')),
              ],
              onChanged: (val) {
                if (val != null) {
                  setState(() => _formValues[key] = val);
                }
              },
              selectedOptionBuilder: (context, value) {
                switch(value) {
                  case 'blue': return const Text('🔵 Blue');
                  case 'zinc': return const Text('🔘 Zinc');
                  case 'rose': return const Text('🌹 Rose');
                  case 'violet': return const Text('🟣 Violet');
                  case 'red': return const Text('🔴 Red');
                  case 'green': return const Text('🟢 Green');
                  case 'orange': return const Text('🟠 Orange');
                  default: return Text(value);
                }
              },
            ),
          ],
        ),
      );
    } else if (type == 'image') {
      final imageUrl = item['image_url'] as String?;
      final localFile = _imageFiles[key];

      return Padding(
        padding: const EdgeInsets.only(bottom: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label ?? key, style: ShadTheme.of(context).textTheme.large),
            const SizedBox(height: 8),
            Row(
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: ShadTheme.of(context).colorScheme.muted,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: ShadTheme.of(context).colorScheme.border),
                  ),
                  clipBehavior: Clip.hardEdge,
                  child: localFile != null
                      ? (kIsWeb ? Image.network(localFile.path, fit: BoxFit.cover) : Image.file(File(localFile.path), fit: BoxFit.cover))
                      : (imageUrl != null && imageUrl.isNotEmpty)
                          ? Image.network(imageUrl, fit: BoxFit.cover, errorBuilder: (c,e,s) => const Icon(LucideIcons.imageOff))
                          : const Icon(LucideIcons.image),
                ),
                const SizedBox(width: 16),
                ShadButton.outline(
                  onPressed: () => _pickImage(key),
                  child: const Text('Pilih Gambar'),
                ),
                if (localFile != null) ...[
                  const SizedBox(width: 8),
                  ShadButton.ghost(
                    onPressed: () => setState(() => _imageFiles.remove(key)),
                    child: const Text('Batal', style: TextStyle(color: Colors.red)),
                  ),
                ]
              ],
            ),
          ],
        ),
      );
    } else {
      return Padding(
        padding: const EdgeInsets.only(bottom: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label ?? key, style: ShadTheme.of(context).textTheme.large),
            const SizedBox(height: 8),
            if (type == 'textarea')
              ShadInput(
                controller: _controllers[key],
                placeholder: Text('Masukkan $label...'),
                maxLines: 4,
              )
            else
              ShadInput(
                controller: _controllers[key],
                placeholder: Text('Masukkan $label...'),
              ),
          ],
        ),
      );
    }
  }

  IconData? _getGroupIcon(String groupName) {
    switch (groupName.toLowerCase()) {
      case 'umum':
        return Icons.settings;
      case 'personalisasi':
        return Icons.palette;
      case 'absensi':
        return Icons.how_to_reg;
      case 'profil':
        return Icons.person;
      case 'alamat':
        return Icons.location_on;
      case 'berkas':
        return Icons.folder;
      case 'keamanan':
        return Icons.security;
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final settingsProvider = Provider.of<AppSettingsProvider>(context);
    final rawSettings = settingsProvider.rawSettings.whereType<Map>().toList();

    // Group settings
    final Map<String, List<Map>> groupedSettings = {};
    for (var item in rawSettings) {
      final group = item['group'] as String? ?? 'Lainnya';
      if (!groupedSettings.containsKey(group)) {
        groupedSettings[group] = [];
      }
      groupedSettings[group]!.add(item);
    }

    final groups = groupedSettings.keys.toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pengaturan Aplikasi'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: ShadButton(
              onPressed: _isLoading ? null : _saveSettings,
              child: _isLoading 
                  ? SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: ShadTheme.of(context).colorScheme.primaryForeground))
                  : const Text('Simpan'),
            ),
          ),
        ],
      ),
      body: groups.isEmpty
          ? const Center(child: Text('Tidak ada pengaturan tersedia.'))
          : DefaultTabController(
              length: groups.length,
              child: Column(
                children: [
                  TabBar(
                    isScrollable: true,
                    tabAlignment: TabAlignment.start,
                    dividerColor: Colors.transparent,
                    indicatorColor: ShadTheme.of(context).colorScheme.primary,
                    labelColor: ShadTheme.of(context).colorScheme.primary,
                    unselectedLabelColor: ShadTheme.of(context).colorScheme.mutedForeground,
                    tabs: groups.map((g) {
                      final iconData = _getGroupIcon(g);
                      return Tab(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (iconData != null) ...[
                              Icon(iconData, size: 20),
                              const SizedBox(width: 8),
                            ],
                            Text(g),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                  Expanded(
                    child: TabBarView(
                      children: groups.map((g) {
                        final items = groupedSettings[g]!;
                        return ListView(
                          padding: const EdgeInsets.all(24.0),
                          children: [
                            Text('Pengaturan $g', style: ShadTheme.of(context).textTheme.h4),
                            const SizedBox(height: 24),
                            ...items.map(_buildField),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

}
