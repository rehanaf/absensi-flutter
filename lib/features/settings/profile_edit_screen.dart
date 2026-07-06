import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
      if (mounted) {
        setState(() => _isLoadingFields = false);
        final auth = Provider.of<AuthProvider>(context, listen: false);
        final userProfile = auth.user?['profile']?['meta_data'] ?? {};
        if (userProfile is Map) {
          userProfile.forEach((key, value) {
            _customFieldControllers[key] = TextEditingController(text: value.toString());
            _formFieldsConfig.add({
              'field_name': key,
              'field_label': key,
              'field_type': 'text',
              'is_editable': true,
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profil berhasil diperbarui')),
        );
        Provider.of<AuthProvider>(context, listen: false).checkAuthStatus();
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menyimpan: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildTextField(String label, TextEditingController controller, {bool enabled = true, bool isRequired = false, TextInputType? keyboardType}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextFormField(
        controller: controller,
        enabled: enabled,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label + (isRequired && enabled ? ' *' : ''),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: enabled 
              ? Theme.of(context).colorScheme.surfaceContainerHighest.withAlpha(80) 
              : Theme.of(context).colorScheme.surfaceContainerHighest.withAlpha(40),
        ),
        validator: isRequired && enabled
            ? (v) => v == null || v.isEmpty ? '$label tidak boleh kosong' : null
            : null,
      ),
    );
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
                    Text('Informasi Dasar', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    _buildTextField('Nama Lengkap', _nameController, enabled: canEditName, isRequired: true),
                    _buildTextField('Email', _emailController, enabled: canEditEmail, isRequired: true, keyboardType: TextInputType.emailAddress),
                    _buildTextField(settings.getSetting('username_label') ?? 'Username', _usernameController, enabled: canEditUsername, isRequired: true),
                    _buildTextField('No. HP / WhatsApp', _phoneController, enabled: canEditPhone, keyboardType: TextInputType.phone),
                    
                    const SizedBox(height: 16),
                    
                    if (_formFieldsConfig.isNotEmpty) ...[
                      Text('Data Tambahan', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
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

                        return _buildTextField(
                          label,
                          _customFieldControllers[field['field_name']]!,
                          enabled: isEditable,
                          isRequired: isRequired,
                          keyboardType: keyboardType,
                        );
                      }),
                      const SizedBox(height: 16),
                    ],

                    FilledButton.icon(
                      onPressed: _submit,
                      icon: const Icon(Icons.save),
                      label: const Text('Simpan Perubahan'),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
