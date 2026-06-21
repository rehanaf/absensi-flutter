import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../../../data/services/api_service.dart';
import '../../../providers/app_settings_provider.dart';

class AdminUserFormScreen extends StatefulWidget {
  final Map<String, dynamic>? user;

  const AdminUserFormScreen({super.key, this.user});

  @override
  State<AdminUserFormScreen> createState() => _AdminUserFormScreenState();
}

class _AdminUserFormScreenState extends State<AdminUserFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _apiService = ApiService();

  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _usernameController;
  late TextEditingController _phoneController;
  late TextEditingController _passwordController;

  int? _selectedRoleId;
  bool _canAttend = true;
  bool _isLoading = false;
  bool _isLoadingFields = true;

  List<dynamic> _formFieldsConfig = [];
  final Map<String, TextEditingController> _customFieldControllers = {};

  @override
  void initState() {
    super.initState();
    final user = widget.user;
    
    _nameController = TextEditingController(text: user?['name'] ?? '');
    _emailController = TextEditingController(text: user?['email'] ?? '');
    _usernameController = TextEditingController(text: user?['username'] ?? '');
    _phoneController = TextEditingController(text: user?['phone_number'] ?? '');
    _passwordController = TextEditingController();
    
    if (user != null) {
      _selectedRoleId = user['role_id'];
      _canAttend = user['can_attend'] == 1 || user['can_attend'] == true;
    } else {
      // Set default role if available
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final roles = Provider.of<AppSettingsProvider>(context, listen: false).roles;
        if (roles.isNotEmpty && _selectedRoleId == null) {
          setState(() {
            _selectedRoleId = roles.first['id'];
          });
        }
      });
    }

    _fetchFormFields();
  }

  Future<void> _fetchFormFields() async {
    try {
      final fields = await _apiService.getFormFields();
      if (!mounted) return;
      
      setState(() {
        _formFieldsConfig = fields;
        
        final userProfile = widget.user?['profile']?['meta_data'] ?? {};
        
        for (var field in _formFieldsConfig) {
          final fieldName = field['field_name'];
          _customFieldControllers[fieldName] = TextEditingController(
            text: userProfile[fieldName]?.toString() ?? '',
          );
        }
        _isLoadingFields = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingFields = false);
        ShadToaster.of(context).show(ShadToast.destructive(description: Text('Gagal memuat kolom profil: $e')));
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _usernameController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    for (var controller in _customFieldControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedRoleId == null) {
      ShadToaster.of(context).show(const ShadToast.destructive(description: Text('Silakan pilih Role')));
      return;
    }

    setState(() => _isLoading = true);

    final data = {
      'name': _nameController.text,
      'email': _emailController.text,
      'username': _usernameController.text,
      'phone_number': _phoneController.text,
      'role_id': _selectedRoleId,
      'can_attend': _canAttend,
    };

    // Append custom fields
    if (_formFieldsConfig.isNotEmpty) {
      final customFields = <String, dynamic>{};
      for (var field in _formFieldsConfig) {
        final fieldName = field['field_name'];
        customFields[fieldName] = _customFieldControllers[fieldName]?.text ?? '';
      }
      data['custom_fields'] = customFields;
    }

    if (_passwordController.text.isNotEmpty) {
      data['password'] = _passwordController.text;
    } else if (widget.user == null) {
      ShadToaster.of(context).show(const ShadToast.destructive(description: Text('Password wajib diisi untuk pengguna baru')));
      setState(() => _isLoading = false);
      return;
    }

    try {
      if (widget.user == null) {
        await _apiService.createUser(data);
        if (mounted) ShadToaster.of(context).show(const ShadToast(description: Text('Pengguna berhasil ditambahkan')));
      } else {
        await _apiService.updateUser(widget.user!['id'], data);
        if (mounted) ShadToaster.of(context).show(const ShadToast(description: Text('Data pengguna berhasil diperbarui')));
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
    final isEditing = widget.user != null;
    final roles = Provider.of<AppSettingsProvider>(context).roles;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Pengguna' : 'Tambah Pengguna'),
      ),
      body: _isLoading || _isLoadingFields
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('Informasi Dasar', style: ShadTheme.of(context).textTheme.large),
                    const SizedBox(height: 16),
                    
                    ShadInputFormField(
                      label: const Text('Nama Lengkap'),
                      controller: _nameController,
                      validator: (v) => v.isEmpty ? 'Nama tidak boleh kosong' : null,
                    ),
                    const SizedBox(height: 16),
                    
                    ShadInputFormField(
                      label: const Text('Email'),
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      validator: (v) => v.isEmpty ? 'Email tidak boleh kosong' : null,
                    ),
                    const SizedBox(height: 16),
                    
                    ShadInputFormField(
                      label: const Text('Username'),
                      controller: _usernameController,
                      validator: (v) => v.isEmpty ? 'Username tidak boleh kosong' : null,
                    ),
                    const SizedBox(height: 16),
                    
                    ShadInputFormField(
                      label: const Text('No. HP / WhatsApp'),
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 24),
                    
                    Text('Keamanan & Akses', style: ShadTheme.of(context).textTheme.large),
                    const SizedBox(height: 16),
                    
                    ShadInputFormField(
                      label: Text(isEditing ? 'Password Baru (Biarkan kosong jika tidak diubah)' : 'Password'),
                      controller: _passwordController,
                      obscureText: true,
                    ),
                    const SizedBox(height: 16),
                    
                    if (roles.isNotEmpty)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Role / Peran', style: ShadTheme.of(context).textTheme.small),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              border: Border.all(color: ShadTheme.of(context).colorScheme.border),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<int>(
                                isExpanded: true,
                                value: _selectedRoleId,
                                items: roles.map<DropdownMenuItem<int>>((r) {
                                  return DropdownMenuItem<int>(
                                    value: r['id'],
                                    child: Text(r['name'] ?? 'Unknown'),
                                  );
                                }).toList(),
                                onChanged: (val) {
                                  setState(() => _selectedRoleId = val);
                                },
                              ),
                            ),
                          ),
                        ],
                      )
                    else
                      const Text('Memuat Role...', style: TextStyle(color: Colors.grey)),
                    
                    const SizedBox(height: 24),
                    
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Izinkan Melakukan Absensi?'),
                        ShadSwitch(
                          value: _canAttend,
                          onChanged: (val) {
                            setState(() => _canAttend = val);
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),

                    if (_formFieldsConfig.isNotEmpty) ...[
                      Text('Data Tambahan', style: ShadTheme.of(context).textTheme.large),
                      const SizedBox(height: 16),
                      ..._formFieldsConfig.map((field) {
                        final label = field['field_label'];
                        final type = field['field_type'];
                        final isRequired = field['is_required'] == 1 || field['is_required'] == true;
                        
                        TextInputType keyboardType = TextInputType.text;
                        if (type == 'number') keyboardType = TextInputType.number;
                        if (type == 'email') keyboardType = TextInputType.emailAddress;
                        if (type == 'phone') keyboardType = TextInputType.phone;
                        
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16.0),
                          child: ShadInputFormField(
                            label: Text(label + (isRequired ? ' *' : '')),
                            controller: _customFieldControllers[field['field_name']],
                            keyboardType: keyboardType,
                            validator: isRequired 
                                ? (v) => v.isEmpty ? '$label wajib diisi' : null 
                                : null,
                          ),
                        );
                      }),
                      const SizedBox(height: 16),
                    ],
                    
                    ShadButton(
                      onPressed: _submit,
                      child: const Text('Simpan Data Pengguna'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
