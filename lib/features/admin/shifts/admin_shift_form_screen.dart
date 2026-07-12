import 'package:flutter/material.dart';
import '../../../data/services/api_service.dart';

class AdminShiftFormScreen extends StatefulWidget {
  final Map<String, dynamic>? item;
  const AdminShiftFormScreen({super.key, this.item});

  @override
  State<AdminShiftFormScreen> createState() => _AdminShiftFormScreenState();
}

class _AdminShiftFormScreenState extends State<AdminShiftFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _apiService = ApiService();
  bool _isLoading = false;

  late TextEditingController _nameController;
  late TextEditingController _checkInController;
  late TextEditingController _checkOutController;


  @override
  void initState() {
    super.initState();
    final item = widget.item;
    _nameController = TextEditingController(text: item?['name']?.toString() ?? '');
    _checkInController = TextEditingController(text: item?['check_in']?.toString() ?? '');
    _checkOutController = TextEditingController(text: item?['check_out']?.toString() ?? '');

  }

  @override
  void dispose() {
    _nameController.dispose();
    _checkInController.dispose();
    _checkOutController.dispose();

    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final data = {
      'name': _nameController.text,
      'check_in': _checkInController.text,
      'check_out': _checkOutController.text,

    };

    try {
      if (widget.item == null) {
        await _apiService.createShift(data);
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Berhasil ditambahkan'), backgroundColor: Colors.green));
      } else {
        await _apiService.updateShift(widget.item!['id'], data);
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
        title: Text(isEditing ? 'Edit Shift Kerja' : 'Tambah Shift Kerja'),
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
                    TextFormField(decoration: InputDecoration(border: const OutlineInputBorder(), label: Text('Nama Shift')), controller: _nameController, validator: (v) => (v == null || v.isEmpty) ? 'Wajib diisi' : null),
                    const SizedBox(height: 16),
                    TextFormField(decoration: InputDecoration(border: const OutlineInputBorder(), label: Text('Jam Masuk (HH:MM:SS)')), controller: _checkInController, validator: (v) => (v == null || v.isEmpty) ? 'Wajib diisi' : null),
                    const SizedBox(height: 16),
                    TextFormField(decoration: InputDecoration(border: const OutlineInputBorder(), label: Text('Jam Keluar (HH:MM:SS)')), controller: _checkOutController, validator: (v) => (v == null || v.isEmpty) ? 'Wajib diisi' : null),
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
