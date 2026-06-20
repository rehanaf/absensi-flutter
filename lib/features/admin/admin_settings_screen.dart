import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
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
  bool _isLoading = false;
  bool _isInitialized = false;

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
                  default: return Text(value);
                }
              },
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
            ShadInput(
              controller: _controllers[key],
              placeholder: Text('Masukkan $label...'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final settingsProvider = Provider.of<AppSettingsProvider>(context);

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24.0),
          children: [
            Text('Konfigurasi Dinamis', style: ShadTheme.of(context).textTheme.h3),
            const SizedBox(height: 8),
            Text('Semua opsi ditarik otomatis dari konfigurasi server (API).', style: ShadTheme.of(context).textTheme.muted),
            const SizedBox(height: 32),
            
            ...settingsProvider.rawSettings.whereType<Map>().map(_buildField),
            
            const SizedBox(height: 24),
            
            ShadButton(
              onPressed: _isLoading ? null : _saveSettings,
              child: _isLoading 
                  ? const CircularProgressIndicator()
                  : const Text('Simpan Pengaturan'),
            ),
          ],
        ),
      ),
    );
  }
}
