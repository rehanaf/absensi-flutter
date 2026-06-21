import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../../../../data/services/api_service.dart';
import 'admin_form_field_form_screen.dart';

class AdminFormFieldsScreen extends StatefulWidget {
  const AdminFormFieldsScreen({super.key});

  @override
  State<AdminFormFieldsScreen> createState() => _AdminFormFieldsScreenState();
}

class _AdminFormFieldsScreenState extends State<AdminFormFieldsScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  String? _error;
  List<dynamic> _fields = [];

  @override
  void initState() {
    super.initState();
    _fetchFields();
  }

  Future<void> _fetchFields() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final fields = await _apiService.getFormFields();
      setState(() {
        _fields = fields;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteField(int id) async {
    final bool? confirm = await showDialog(
      context: context,
      builder: (context) => ShadDialog(
        title: const Text('Hapus Kolom'),
        description: const Text('Apakah Anda yakin ingin menghapus kolom profil ini? Data terkait pengguna mungkin akan hilang.'),
        actions: [
          ShadButton.outline(
            child: const Text('Batal'),
            onPressed: () => Navigator.pop(context, false),
          ),
          ShadButton.destructive(
            child: const Text('Hapus'),
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _apiService.deleteFormField(id);
      if (mounted) {
        ShadToaster.of(context).show(const ShadToast(description: Text('Kolom berhasil dihapus')));
        _fetchFields();
      }
    } catch (e) {
      if (mounted) {
        ShadToaster.of(context).show(ShadToast.destructive(description: Text('Gagal menghapus kolom: $e')));
      }
    }
  }

  void _navigateToForm([Map<String, dynamic>? field]) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AdminFormFieldFormScreen(formField: field),
      ),
    );

    if (result == true) {
      _fetchFields(); // Refresh after create/update
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manajemen Kolom Profil'),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.refreshCw),
            onPressed: _fetchFields,
          )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Gagal memuat kolom profil', style: ShadTheme.of(context).textTheme.large),
                      Text(_error!, style: const TextStyle(color: Colors.red)),
                      const SizedBox(height: 16),
                      ShadButton(onPressed: _fetchFields, child: const Text('Coba Lagi')),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _fields.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final field = _fields[index];
                    final isRequired = field['is_required'] == 1 || field['is_required'] == true;
                    final isEditable = field['is_editable'] == 1 || field['is_editable'] == true;

                    return Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: ShadTheme.of(context).colorScheme.border),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.purple.withOpacity(0.1),
                          child: const Icon(LucideIcons.formInput, color: Colors.purple),
                        ),
                        title: Text(field['field_label'] ?? 'No Label', style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Variabel: ${field['field_name']} • Tipe: ${field['field_type']}'),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                if (isRequired)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    margin: const EdgeInsets.only(right: 8),
                                    decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                                    child: const Text('Wajib', style: TextStyle(color: Colors.red, fontSize: 10)),
                                  ),
                                if (isEditable)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                                    child: const Text('Bisa Diedit', style: TextStyle(color: Colors.green, fontSize: 10)),
                                  )
                                else
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(color: Colors.grey.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                                    child: const Text('Hanya Baca', style: TextStyle(color: Colors.grey, fontSize: 10)),
                                  ),
                              ],
                            )
                          ],
                        ),
                        isThreeLine: true,
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(LucideIcons.edit2, size: 20),
                              onPressed: () => _navigateToForm(field),
                            ),
                            IconButton(
                              icon: const Icon(LucideIcons.trash2, size: 20, color: Colors.red),
                              onPressed: () => _deleteField(field['id']),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToForm(),
        child: const Icon(LucideIcons.plus),
      ),
    );
  }
}
