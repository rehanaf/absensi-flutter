import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../../../../data/services/api_service.dart';

class AdminFormFieldFormScreen extends StatefulWidget {
  final Map<String, dynamic>? formField;

  const AdminFormFieldFormScreen({super.key, this.formField});

  @override
  State<AdminFormFieldFormScreen> createState() => _AdminFormFieldFormScreenState();
}

class _AdminFormFieldFormScreenState extends State<AdminFormFieldFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _apiService = ApiService();

  late TextEditingController _labelController;
  late TextEditingController _nameController;

  String _selectedType = 'text';
  bool _isRequired = false;
  bool _isEditable = true;
  bool _isLoading = false;

  final List<String> _typeOptions = ['text', 'number', 'date', 'dropdown', 'email', 'phone'];

  @override
  void initState() {
    super.initState();
    final field = widget.formField;
    
    _labelController = TextEditingController(text: field?['field_label'] ?? '');
    _nameController = TextEditingController(text: field?['field_name'] ?? '');
    
    if (field != null) {
      if (_typeOptions.contains(field['field_type'])) {
        _selectedType = field['field_type'];
      } else {
        // If backend has custom type, append it
        _typeOptions.add(field['field_type']);
        _selectedType = field['field_type'];
      }
      
      _isRequired = field['is_required'] == 1 || field['is_required'] == true;
      _isEditable = field['is_editable'] == 1 || field['is_editable'] == true;
    }
  }

  @override
  void dispose() {
    _labelController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final data = {
      'field_label': _labelController.text,
      'field_name': _nameController.text,
      'field_type': _selectedType,
      'is_required': _isRequired,
      'is_editable': _isEditable,
    };

    try {
      if (widget.formField == null) {
        await _apiService.createFormField(data);
        if (mounted) ShadToaster.of(context).show(const ShadToast(description: Text('Kolom profil berhasil ditambahkan')));
      } else {
        await _apiService.updateFormField(widget.formField!['id'], data);
        if (mounted) ShadToaster.of(context).show(const ShadToast(description: Text('Kolom profil berhasil diperbarui')));
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        // Catch validation errors nicely (especially unique:form_fields)
        String errMsg = e.toString();
        if (errMsg.contains('unique') || errMsg.contains('Duplicate')) {
          errMsg = 'Nama Variabel (field_name) sudah digunakan.';
        }
        ShadToaster.of(context).show(ShadToast.destructive(description: Text('Gagal menyimpan: $errMsg')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.formField != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Kolom Profil' : 'Tambah Kolom Profil'),
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
                      label: const Text('Label Kolom (Yang Tampil ke Pengguna)'),
                      placeholder: const Text('Contoh: NIP Karyawan'),
                      controller: _labelController,
                      validator: (v) => v.isEmpty ? 'Label kolom tidak boleh kosong' : null,
                    ),
                    const SizedBox(height: 16),
                    
                    ShadInputFormField(
                      label: const Text('Nama Variabel (Format Database)'),
                      placeholder: const Text('Contoh: nip_karyawan'),
                      controller: _nameController,
                      validator: (v) {
                        if (v.isEmpty) return 'Nama variabel tidak boleh kosong';
                        if (v.contains(' ')) return 'Tidak boleh mengandung spasi, gunakan underscore (_)';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Tipe Data', style: ShadTheme.of(context).textTheme.small),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            border: Border.all(color: ShadTheme.of(context).colorScheme.border),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              isExpanded: true,
                              value: _selectedType,
                              items: _typeOptions.map<DropdownMenuItem<String>>((t) {
                                return DropdownMenuItem<String>(
                                  value: t,
                                  child: Text(t.toUpperCase()),
                                );
                              }).toList(),
                              onChanged: (val) {
                                if (val != null) setState(() => _selectedType = val);
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Wajib Diisi? (Required)'),
                              Text('Pengguna tidak bisa menyimpan profil tanpa mengisi ini.', style: TextStyle(fontSize: 12, color: Colors.grey)),
                            ],
                          ),
                        ),
                        ShadSwitch(
                          value: _isRequired,
                          onChanged: (val) {
                            setState(() => _isRequired = val);
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Bisa Diedit? (Editable)'),
                              Text('Jika mati, hanya Admin yang bisa mengubah data ini.', style: TextStyle(fontSize: 12, color: Colors.grey)),
                            ],
                          ),
                        ),
                        ShadSwitch(
                          value: _isEditable,
                          onChanged: (val) {
                            setState(() => _isEditable = val);
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    
                    ShadButton(
                      onPressed: _submit,
                      child: const Text('Simpan Kolom'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
