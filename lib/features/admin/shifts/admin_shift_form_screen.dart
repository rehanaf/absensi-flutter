import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
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
        if (mounted) ShadToaster.of(context).show(const ShadToast(description: Text('Berhasil ditambahkan')));
      } else {
        await _apiService.updateShift(widget.item!['id'], data);
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
                    ShadInputFormField(
                      label: const Text('Nama Shift'),
                      controller: _nameController,
                      validator: (v) => v.isEmpty ? 'Wajib diisi' : null,
                    ),
                    const SizedBox(height: 16),
                    ShadInputFormField(
                      label: const Text('Jam Masuk (HH:MM:SS)'),
                      controller: _checkInController,
                      validator: (v) => v.isEmpty ? 'Wajib diisi' : null,
                    ),
                    const SizedBox(height: 16),
                    ShadInputFormField(
                      label: const Text('Jam Keluar (HH:MM:SS)'),
                      controller: _checkOutController,
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
