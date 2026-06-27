import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../../../data/services/api_service.dart';

class AdminRosterFormScreen extends StatefulWidget {
  final Map<String, dynamic>? item;
  const AdminRosterFormScreen({super.key, this.item});

  @override
  State<AdminRosterFormScreen> createState() => _AdminRosterFormScreenState();
}

class _AdminRosterFormScreenState extends State<AdminRosterFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _apiService = ApiService();
  bool _isLoading = false;

  late TextEditingController _userIdController;
  late TextEditingController _shiftIdController;
  late TextEditingController _dateController;


  @override
  void initState() {
    super.initState();
    final item = widget.item;
    _userIdController = TextEditingController(text: item?['user_id']?.toString() ?? '');
    _shiftIdController = TextEditingController(text: item?['shift_id']?.toString() ?? '');
    _dateController = TextEditingController(text: item?['date']?.toString() ?? '');

  }

  @override
  void dispose() {
    _userIdController.dispose();
    _shiftIdController.dispose();
    _dateController.dispose();

    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final data = {
      'user_id': _userIdController.text,
      'shift_id': _shiftIdController.text,
      'date': _dateController.text,

    };

    try {
      if (widget.item == null) {
        await _apiService.createRoster(data);
        if (mounted) ShadToaster.of(context).show(const ShadToast(description: Text('Berhasil ditambahkan')));
      } else {
        await _apiService.updateRoster(widget.item!['id'], data);
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
        title: Text(isEditing ? 'Edit Roster Jadwal' : 'Tambah Roster Jadwal'),
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
                      label: const Text('User ID'),
                      controller: _userIdController,
                      validator: (v) => v.isEmpty ? 'Wajib diisi' : null,
                    ),
                    const SizedBox(height: 16),
                    ShadInputFormField(
                      label: const Text('Shift ID'),
                      controller: _shiftIdController,
                      validator: (v) => v.isEmpty ? 'Wajib diisi' : null,
                    ),
                    const SizedBox(height: 16),
                    ShadInputFormField(
                      label: const Text('Tanggal'),
                      controller: _dateController,
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
