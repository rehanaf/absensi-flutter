with open('lib/features/admin/admin_settings_screen.dart', 'w', encoding='utf-8') as f:
    f.write("""import 'dart:io';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal memilih gambar: $e'), backgroundColor: Colors.red));
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
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pengaturan berhasil disimpan'), backgroundColor: Colors.green));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal menyimpan: $e'), backgroundColor: Colors.red));
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
          border: Border.all(color: Theme.of(context).dividerColor),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(label ?? key, style: const TextStyle(fontWeight: FontWeight.w600)),
            ),
            Switch(
              value: _formValues[key] == true,
              onChanged: (v) => setState(() => _formValues[key] = v),
            ),
          ],
        ),
      );
    } else if (type == 'select') {
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
            Text(label ?? key, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(border: OutlineInputBorder()),
              hint: const Text('Pilih Opsi'),
              value: _formValues[key] as String?,
              items: options.map((opt) => DropdownMenuItem(value: opt, child: Text(opt.toUpperCase()))).toList(),
              onChanged: (val) {
                if (val != null) {
                  setState(() => _formValues[key] = val);
                }
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
            Text(label ?? key, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(border: OutlineInputBorder()),
              hint: const Text('Pilih Warna Tema'),
              value: _formValues[key] as String?,
              items: const [
                DropdownMenuItem(value: 'blue', child: Text('\uD83D\uDD35 Blue')),
                DropdownMenuItem(value: 'zinc', child: Text('\uD83D\uDD18 Zinc')),
                DropdownMenuItem(value: 'rose', child: Text('\uD83C\uDF39 Rose')),
                DropdownMenuItem(value: 'violet', child: Text('\uD83D\uDFE3 Violet')),
                DropdownMenuItem(value: 'red', child: Text('\uD83D\uDD34 Red')),
                DropdownMenuItem(value: 'green', child: Text('\uD83D\uDFE2 Green')),
                DropdownMenuItem(value: 'orange', child: Text('\uD83D\uDFE0 Orange')),
              ],
              onChanged: (val) {
                if (val != null) {
                  setState(() => _formValues[key] = val);
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
            Text(label ?? key, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Row(
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Theme.of(context).dividerColor),
                  ),
                  clipBehavior: Clip.hardEdge,
                  child: localFile != null
                      ? (kIsWeb ? Image.network(localFile.path, fit: BoxFit.cover) : Image.file(File(localFile.path), fit: BoxFit.cover))
                      : (imageUrl != null && imageUrl.isNotEmpty)
                          ? Image.network(imageUrl, fit: BoxFit.cover, errorBuilder: (c,e,s) => const Icon(Icons.broken_image))
                          : const Icon(Icons.image),
                ),
                const SizedBox(width: 16),
                OutlinedButton(
                  onPressed: () => _pickImage(key),
                  child: const Text('Pilih Gambar'),
                ),
                if (localFile != null) ...[
                  const SizedBox(width: 8),
                  TextButton(
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
            Text(label ?? key, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            TextFormField(
              controller: _controllers[key],
              decoration: InputDecoration(
                hintText: 'Masukkan $label...',
                border: const OutlineInputBorder(),
              ),
              maxLines: type == 'textarea' ? 4 : 1,
            ),
          ],
        ),
      );
    }
  }

  IconData? _getGroupIcon(String groupName) {
    switch (groupName.toLowerCase()) {
      case 'umum': return Icons.settings;
      case 'personalisasi': return Icons.palette;
      case 'absensi': return Icons.how_to_reg;
      case 'profil': return Icons.person;
      case 'alamat': return Icons.location_on;
      case 'berkas': return Icons.folder;
      case 'keamanan': return Icons.security;
      default: return null;
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

    if (groups.isEmpty) {
      return const Center(child: Text('Tidak ada pengaturan tersedia.'));
    }

    return DefaultTabController(
      length: groups.length,
      child: Column(
        children: [
          TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            dividerColor: Colors.transparent,
            indicatorColor: Theme.of(context).colorScheme.primary,
            labelColor: Theme.of(context).colorScheme.primary,
            unselectedLabelColor: Theme.of(context).colorScheme.onSurfaceVariant,
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
                    Text('Pengaturan $g', style: Theme.of(context).textTheme.headlineSmall),
                    const SizedBox(height: 24),
                    ...items.map(_buildField),
                  ],
                );
              }).toList(),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              border: Border(top: BorderSide(color: Theme.of(context).dividerColor)),
            ),
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _saveSettings,
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isLoading 
                  ? SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Theme.of(context).colorScheme.onPrimary))
                  : const Text('Simpan Perubahan'),
            ),
          ),
        ],
      ),
    );
  }
}
""")
