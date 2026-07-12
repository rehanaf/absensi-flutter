import 'package:flutter/material.dart';
import '../../../data/services/api_service.dart';

class AdminPermitFormScreen extends StatefulWidget {
  final Map<String, dynamic>? item;
  const AdminPermitFormScreen({super.key, this.item});

  @override
  State<AdminPermitFormScreen> createState() => _AdminPermitFormScreenState();
}

class _AdminPermitFormScreenState extends State<AdminPermitFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _apiService = ApiService();
  bool _isLoading = false;

  late TextEditingController _userIdController;
  late TextEditingController _startDateController;
  late TextEditingController _endDateController;
  late TextEditingController _typeController;
  late TextEditingController _reasonController;
  late TextEditingController _statusController;


  @override
  void initState() {
    super.initState();
    final item = widget.item;
    _userIdController = TextEditingController(text: item?['user_id']?.toString() ?? '');
    _startDateController = TextEditingController(text: item?['start_date']?.toString() ?? '');
    _endDateController = TextEditingController(text: item?['end_date']?.toString() ?? '');
    _typeController = TextEditingController(text: item?['type']?.toString() ?? '');
    _reasonController = TextEditingController(text: item?['reason']?.toString() ?? '');
    _statusController = TextEditingController(text: item?['status']?.toString() ?? '');

  }

  @override
  void dispose() {
    _userIdController.dispose();
    _startDateController.dispose();
    _endDateController.dispose();
    _typeController.dispose();
    _reasonController.dispose();
    _statusController.dispose();

    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final data = {
      'user_id': _userIdController.text,
      'start_date': _startDateController.text,
      'end_date': _endDateController.text,
      'type': _typeController.text,
      'reason': _reasonController.text,
      'status': _statusController.text,

    };

    try {
      if (widget.item == null) {
        await _apiService.createPermit(data);
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Berhasil ditambahkan'), backgroundColor: Colors.green));
      } else {
        await _apiService.updatePermit(widget.item!['id'], data);
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
        title: Text(isEditing ? 'Edit Izin & Cuti' : 'Tambah Izin & Cuti'),
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
                    TextFormField(decoration: InputDecoration(border: const OutlineInputBorder(), label: Text('User ID')), controller: _userIdController, validator: (v) => (v == null || v.isEmpty) ? 'Wajib diisi' : null),
                    const SizedBox(height: 16),
                    TextFormField(decoration: InputDecoration(border: const OutlineInputBorder(), label: Text('Tgl Mulai')), controller: _startDateController, validator: (v) => (v == null || v.isEmpty) ? 'Wajib diisi' : null),
                    const SizedBox(height: 16),
                    TextFormField(decoration: InputDecoration(border: const OutlineInputBorder(), label: Text('Tgl Selesai')), controller: _endDateController, validator: (v) => (v == null || v.isEmpty) ? 'Wajib diisi' : null),
                    const SizedBox(height: 16),
                    TextFormField(decoration: InputDecoration(border: const OutlineInputBorder(), label: Text('Tipe')), controller: _typeController, validator: (v) => (v == null || v.isEmpty) ? 'Wajib diisi' : null),
                    const SizedBox(height: 16),
                    TextFormField(decoration: InputDecoration(border: const OutlineInputBorder(), label: Text('Alasan')), controller: _reasonController, validator: (v) => (v == null || v.isEmpty) ? 'Wajib diisi' : null),
                    const SizedBox(height: 16),
                    TextFormField(decoration: InputDecoration(border: const OutlineInputBorder(), label: Text('Status')), controller: _statusController, validator: (v) => (v == null || v.isEmpty) ? 'Wajib diisi' : null),
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
