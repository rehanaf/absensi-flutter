import 'package:flutter/material.dart';
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
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Berhasil ditambahkan'), backgroundColor: Colors.green));
      } else {
        await _apiService.updateRoster(widget.item!['id'], data);
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
                    TextFormField(decoration: InputDecoration(border: const OutlineInputBorder(), label: Text('User ID')), controller: _userIdController, validator: (v) => (v == null || v.isEmpty) ? 'Wajib diisi' : null),
                    const SizedBox(height: 16),
                    TextFormField(decoration: InputDecoration(border: const OutlineInputBorder(), label: Text('Shift ID')), controller: _shiftIdController, validator: (v) => (v == null || v.isEmpty) ? 'Wajib diisi' : null),
                    const SizedBox(height: 16),
                    TextFormField(decoration: InputDecoration(border: const OutlineInputBorder(), label: Text('Tanggal')), controller: _dateController, validator: (v) => (v == null || v.isEmpty) ? 'Wajib diisi' : null),
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
