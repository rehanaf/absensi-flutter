import 'package:flutter/material.dart';
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
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Berhasil ditambahkan'), backgroundColor: Colors.green));
      } else {
        await _apiService.updateLocation(widget.item!['id'], data);
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Berhasil diperbarui'), backgroundColor: Colors.green));
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal menyimpan: $e'), backgroundColor: Colors.red));
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
                    TextFormField(decoration: InputDecoration(border: const OutlineInputBorder(), label: Text('Nama Cabang')), controller: _nameController, validator: (v) => (v == null || v.isEmpty) ? 'Wajib diisi' : null),
                    const SizedBox(height: 16),
                    TextFormField(decoration: InputDecoration(border: const OutlineInputBorder(), label: Text('Latitude')), controller: _latitudeController, validator: (v) => (v == null || v.isEmpty) ? 'Wajib diisi' : null),
                    const SizedBox(height: 16),
                    TextFormField(decoration: InputDecoration(border: const OutlineInputBorder(), label: Text('Longitude')), controller: _longitudeController, validator: (v) => (v == null || v.isEmpty) ? 'Wajib diisi' : null),
                    const SizedBox(height: 16),
                    TextFormField(decoration: InputDecoration(border: const OutlineInputBorder(), label: Text('Radius (m)')), controller: _radiusController, validator: (v) => (v == null || v.isEmpty) ? 'Wajib diisi' : null),
                    const SizedBox(height: 16),

                    const SizedBox(height: 24),
                    ElevatedButton(onPressed: _submit, child: const Text('Simpan')),
                  ],
                ),
              ),
            ),
    );
  }
}
