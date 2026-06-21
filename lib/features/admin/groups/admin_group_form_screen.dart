import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../../../../data/services/api_service.dart';

class AdminGroupFormScreen extends StatefulWidget {
  final Map<String, dynamic>? group;

  const AdminGroupFormScreen({super.key, this.group});

  @override
  State<AdminGroupFormScreen> createState() => _AdminGroupFormScreenState();
}

class _AdminGroupFormScreenState extends State<AdminGroupFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _apiService = ApiService();

  late TextEditingController _nameController;
  late TextEditingController _typeController;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final group = widget.group;
    
    _nameController = TextEditingController(text: group?['name'] ?? '');
    _typeController = TextEditingController(text: group?['type'] ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _typeController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final data = {
      'name': _nameController.text,
      'type': _typeController.text,
    };

    try {
      if (widget.group == null) {
        await _apiService.createGroup(data);
        if (mounted) ShadToaster.of(context).show(const ShadToast(description: Text('Kelompok berhasil ditambahkan')));
      } else {
        await _apiService.updateGroup(widget.group!['id'], data);
        if (mounted) ShadToaster.of(context).show(const ShadToast(description: Text('Kelompok berhasil diperbarui')));
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
    final isEditing = widget.group != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Kelompok' : 'Tambah Kelompok'),
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
                      label: const Text('Nama Kelompok / Kelas'),
                      placeholder: const Text('Contoh: Kelas X RPL 1'),
                      controller: _nameController,
                      validator: (v) => v.isEmpty ? 'Nama kelompok tidak boleh kosong' : null,
                    ),
                    const SizedBox(height: 16),
                    
                    ShadInputFormField(
                      label: const Text('Tipe'),
                      placeholder: const Text('Contoh: Kelas, Departemen, Shift'),
                      controller: _typeController,
                      validator: (v) => v.isEmpty ? 'Tipe tidak boleh kosong' : null,
                    ),
                    const SizedBox(height: 32),
                    
                    ShadButton(
                      onPressed: _submit,
                      child: const Text('Simpan Kelompok'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
