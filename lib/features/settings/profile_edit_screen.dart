import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../../data/services/api_service.dart';
import '../../providers/auth_provider.dart';
import '../../providers/app_settings_provider.dart';

class ProfileEditScreen extends StatefulWidget {
  const ProfileEditScreen({super.key});

  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _apiService = ApiService();

  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _usernameController;
  late TextEditingController _phoneController;

  bool _isLoading = false;
  bool _isLoadingFields = true;

  List<dynamic> _formFieldsConfig = [];
  final Map<String, TextEditingController> _customFieldControllers = {};

  @override
  void initState() {
    super.initState();
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final user = auth.user;

    _nameController = TextEditingController(text: user?['name'] ?? '');
    _emailController = TextEditingController(text: user?['email'] ?? '');
    _usernameController = TextEditingController(text: user?['username'] ?? '');
    _phoneController = TextEditingController(text: user?['phone_number'] ?? '');

    _fetchFormFields();
  }

  Future<void> _fetchFormFields() async {
    try {
      final fields = await _apiService.getPublicFormFields();
      if (!mounted) return;

      final auth = Provider.of<AuthProvider>(context, listen: false);
      final userProfile = auth.user?['profile']?['meta_data'] ?? {};

      setState(() {
        _formFieldsConfig = fields;

        for (var field in _formFieldsConfig) {
          final fieldName = field['field_name'];
          _customFieldControllers[fieldName] = TextEditingController(
            text: userProfile[fieldName]?.toString() ?? '',
          );
        }
        _isLoadingFields = false;
      });
    } catch (e) {
      // If fetching fields fails (e.g., 403 Forbidden for non-admins),
      // we just skip rendering dynamic fields or render them from meta_data.
      if (mounted) {
        setState(() => _isLoadingFields = false);
        // Fallback: create controllers from existing meta_data if schema fails
        final auth = Provider.of<AuthProvider>(context, listen: false);
        final userProfile = auth.user?['profile']?['meta_data'] ?? {};
        if (userProfile is Map) {
          userProfile.forEach((key, value) {
            _customFieldControllers[key] = TextEditingController(text: value.toString());
            _formFieldsConfig.add({
              'field_name': key,
              'field_label': key,
              'field_type': 'text',
              'is_editable': true, // Assume editable if we can't fetch schema
              'is_required': false,
            });
          });
        }
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _usernameController.dispose();
    _phoneController.dispose();
    for (var controller in _customFieldControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final settings = Provider.of<AppSettingsProvider>(context, listen: false);
    final data = <String, dynamic>{};

    if (settings.getSetting('user_can_edit_name') == '1') {
      data['name'] = _nameController.text;
    }
    if (settings.getSetting('user_can_edit_email') == '1') {
      data['email'] = _emailController.text;
    }
    if (settings.getSetting('user_can_edit_username') == '1') {
      data['username'] = _usernameController.text;
    }
    if (settings.getSetting('user_can_edit_phone') == '1') {
      data['phone_number'] = _phoneController.text;
    }

    // Append custom fields
    if (_formFieldsConfig.isNotEmpty) {
      final customFields = <String, dynamic>{};
      for (var field in _formFieldsConfig) {
        final isEditable = field['is_editable'] == 1 || field['is_editable'] == true;
        if (isEditable) {
          final fieldName = field['field_name'];
          customFields[fieldName] = _customFieldControllers[fieldName]?.text ?? '';
        }
      }
      if (customFields.isNotEmpty) {
        data['custom_fields'] = customFields;
      }
    }

    try {
      await _apiService.updateMyProfile(data);
      if (mounted) {
        ShadToaster.of(context).show(const ShadToast(description: Text('Profil berhasil diperbarui')));
        // Refresh global user state
        Provider.of<AuthProvider>(context, listen: false).fetchUser();
        Navigator.pop(context);
      }
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
    final settings = Provider.of<AppSettingsProvider>(context);

    final canEditName = settings.getSetting('user_can_edit_name') == '1';
    final canEditEmail = settings.getSetting('user_can_edit_email') == '1';
    final canEditUsername = settings.getSetting('user_can_edit_username') == '1';
    final canEditPhone = settings.getSetting('user_can_edit_phone') == '1';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profil'),
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
                      enabled: canEditName,
                      validator: canEditName ? (v) => v.isEmpty ? 'Nama tidak boleh kosong' : null : null,
                    ),
                    const SizedBox(height: 16),
                    ShadInputFormField(
                      label: const Text('Email'),
                      controller: _emailController,
                      enabled: canEditEmail,
                      keyboardType: TextInputType.emailAddress,
                      validator: canEditEmail ? (v) => v.isEmpty ? 'Email tidak boleh kosong' : null : null,
                    ),
                    const SizedBox(height: 16),
                    ShadInputFormField(
                      label: const Text('Username'),
                      controller: _usernameController,
                      enabled: canEditUsername,
                      validator: canEditUsername ? (v) => v.isEmpty ? 'Username tidak boleh kosong' : null : null,
                    ),
                    const SizedBox(height: 16),
                    ShadInputFormField(
                      label: const Text('No. HP / WhatsApp'),
                      controller: _phoneController,
                      enabled: canEditPhone,
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 32),
                    
                    if (_formFieldsConfig.isNotEmpty) ...[
                      Text('Data Tambahan', style: ShadTheme.of(context).textTheme.large),
                      const SizedBox(height: 16),
                      ..._formFieldsConfig.map((field) {
                        final label = field['field_label'] ?? field['field_name'];
                        final type = field['field_type'] ?? 'text';
                        final isRequired = field['is_required'] == 1 || field['is_required'] == true;
                        final isEditable = field['is_editable'] == 1 || field['is_editable'] == true;

                        TextInputType keyboardType = TextInputType.text;
                        if (type == 'number') keyboardType = TextInputType.number;
                        if (type == 'email') keyboardType = TextInputType.emailAddress;
                        if (type == 'phone') keyboardType = TextInputType.phone;

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16.0),
                          child: ShadInputFormField(
                            label: Text(label + (isRequired && isEditable ? ' *' : '')),
                            controller: _customFieldControllers[field['field_name']],
                            keyboardType: keyboardType,
                            enabled: isEditable,
                            validator: isRequired && isEditable
                                ? (v) => v.isEmpty ? '$label wajib diisi' : null
                                : null,
                          ),
                        );
                      }),
                      const SizedBox(height: 16),
                    ],

                    ShadButton(
                      onPressed: _submit,
                      child: const Text('Simpan Perubahan'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
