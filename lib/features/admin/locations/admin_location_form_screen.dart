import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../../../data/services/api_service.dart';

class AdminLocationFormScreen extends StatefulWidget {
  final Map<String, dynamic>? item;
  const AdminLocationFormScreen({super.key, this.item});

  @override
  State<AdminLocationFormScreen> createState() => _AdminLocationFormScreenState();
}

class _AdminLocationFormScreenState extends State<AdminLocationFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _apiService = ApiService();
  bool _isLoading = false;

  late TextEditingController _nameController;
  late TextEditingController _latitudeController;
  late TextEditingController _longitudeController;
  late TextEditingController _radiusController;


  @override
  void initState() {
    super.initState();
    final item = widget.item;
    _nameController = TextEditingController(text: item?['name']?.toString() ?? '');
    _latitudeController = TextEditingController(text: item?['latitude']?.toString() ?? '');
    _longitudeController = TextEditingController(text: item?['longitude']?.toString() ?? '');
    _radiusController = TextEditingController(text: item?['radius']?.toString() ?? '');

  }

  @override
  void dispose() {
    _nameController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    _radiusController.dispose();

    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final data = {
      'name': _nameController.text,
      'latitude': _latitudeController.text,
      'longitude': _longitudeController.text,
      'radius': _radiusController.text,

    };

    try {
      if (widget.item == null) {
        await _apiService.createLocation(data);
        if (mounted) ShadToaster.of(context).show(const ShadToast(description: Text('Berhasil ditambahkan')));
      } else {
        await _apiService.updateLocation(widget.item!['id'], data);
        if (mounted) ShadToaster.of(context).show(const ShadToast(description: Text('Berhasil diperbarui')));
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ShadToaster.of(context).show(ShadToast.destructive(description: Text('Gagal menyimpan: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.item != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Cabang / Lokasi' : 'Tambah Cabang / Lokasi'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ShadInputFormField(
                      label: const Text('Nama Cabang'),
                      controller: _nameController,
                      validator: (v) => v.isEmpty ? 'Wajib diisi' : null,
                    ),
                    const SizedBox(height: 16),
                    ShadInputFormField(
                      label: const Text('Latitude'),
                      controller: _latitudeController,
                      validator: (v) => v.isEmpty ? 'Wajib diisi' : null,
                    ),
                    const SizedBox(height: 16),
                    ShadInputFormField(
                      label: const Text('Longitude'),
                      controller: _longitudeController,
                      validator: (v) => v.isEmpty ? 'Wajib diisi' : null,
                    ),
                    const SizedBox(height: 16),
                    ShadInputFormField(
                      label: const Text('Radius (m)'),
                      controller: _radiusController,
                      validator: (v) => v.isEmpty ? 'Wajib diisi' : null,
                    ),
                    const SizedBox(height: 16),

                    const SizedBox(height: 24),
                    ShadButton(
                      onPressed: _submit,
                      child: const Text('Simpan'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
