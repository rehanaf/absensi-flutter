import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../../../data/services/api_service.dart';

class AdminAnnouncementFormScreen extends StatefulWidget {
  final Map<String, dynamic>? item;
  const AdminAnnouncementFormScreen({super.key, this.item});

  @override
  State<AdminAnnouncementFormScreen> createState() => _AdminAnnouncementFormScreenState();
}

class _AdminAnnouncementFormScreenState extends State<AdminAnnouncementFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _apiService = ApiService();
  bool _isLoading = false;

  late TextEditingController _titleController;
  late TextEditingController _contentController;


  @override
  void initState() {
    super.initState();
    final item = widget.item;
    _titleController = TextEditingController(text: item?['title']?.toString() ?? '');
    _contentController = TextEditingController(text: item?['content']?.toString() ?? '');

  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();

    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final data = {
      'title': _titleController.text,
      'content': _contentController.text,

    };

    try {
      if (widget.item == null) {
        await _apiService.createAnnouncement(data);
        if (mounted) ShadToaster.of(context).show(const ShadToast(description: Text('Berhasil ditambahkan')));
      } else {
        await _apiService.updateAnnouncement(widget.item!['id'], data);
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
        title: Text(isEditing ? 'Edit Pengumuman' : 'Tambah Pengumuman'),
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
                      label: const Text('Judul'),
                      controller: _titleController,
                      validator: (v) => v.isEmpty ? 'Wajib diisi' : null,
                    ),
                    const SizedBox(height: 16),
                    ShadInputFormField(
                      label: const Text('Isi Pengumuman'),
                      controller: _contentController,
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
