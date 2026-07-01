import re

def update_login(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()

    # Add form key and api error
    content = content.replace("bool _isLoading = false;", "final _formKey = GlobalKey<FormState>();\n  String? _apiError;\n  bool _isLoading = false;")

    # Wrap AutofillGroup child in Form
    content = content.replace("AutofillGroup(\n                    child: Column(", "Form(\n                    key: _formKey,\n                    child: AutofillGroup(\n                      child: Column(")
    # Close Form
    content = content.replace("                      ],\n                    ),\n                  ),\n                ],", "                      ],\n                    ),\n                  ),\n                  ),\n                ],")

    # Update _login method
    old_login = """
  Future<void> _login() async {
    setState(() {
      _isLoading = true;
    });

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.login(
      _usernameController.text,
      _passwordController.text,
    );

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }

    if (success && mounted) {
      // Notify OS to save credentials
      TextInput.finishAutofillContext();
      context.go('/home');
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.errorMessage ?? 'Login Failed'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }
"""

    new_login = """
  Future<void> _login() async {
    setState(() {
      _apiError = null;
    });
    
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.login(
      _usernameController.text,
      _passwordController.text,
    );

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }

    if (success && mounted) {
      // Notify OS to save credentials
      TextInput.finishAutofillContext();
      context.go('/home');
    } else if (mounted) {
      setState(() {
        _apiError = authProvider.errorMessage ?? 'Login Failed';
      });
    }
  }
"""
    content = content.replace(old_login.strip(), new_login.strip())

    # Add validators to username field
    content = re.sub(
        r"(controller: _usernameController,)",
        r"\1\n                          validator: (value) => (value == null || value.trim().isEmpty) ? 'Username tidak boleh kosong' : null,\n                          onChanged: (_) { if (_apiError != null) setState(() => _apiError = null); },",
        content
    )

    # Add validators and errorText to password field
    content = re.sub(
        r"(controller: _passwordController,)",
        r"\1\n                          validator: (value) => (value == null || value.trim().isEmpty) ? 'Password tidak boleh kosong' : null,\n                          onChanged: (_) { if (_apiError != null) setState(() => _apiError = null); },",
        content
    )
    content = re.sub(
        r"(hintText: 'Password',)",
        r"\1\n                            errorText: _apiError,",
        content
    )

    with open(filepath, 'w', encoding='utf-8') as f:
        f.write(content)

def update_register(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()

    # Add form key and api error
    content = content.replace("bool _isLoading = false;", "final _formKey = GlobalKey<FormState>();\n  String? _apiError;\n  bool _isLoading = false;")

    # Wrap AutofillGroup child in Form
    content = content.replace("AutofillGroup(\n                    child: Column(", "Form(\n                    key: _formKey,\n                    child: AutofillGroup(\n                      child: Column(")
    content = content.replace("                      ],\n                    ),\n                  ),\n                ],", "                      ],\n                    ),\n                  ),\n                  ),\n                ],")

    # Update _register method
    old_register = """
  Future<void> _register() async {
    setState(() {
      _isLoading = true;
    });

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.register({
      'name': _nameController.text,
      'username': _usernameController.text,
      'email': _emailController.text,
      'password': _passwordController.text,
      'password_confirmation': _passwordConfirmController.text,
    });

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }

    if (success && mounted) {
      TextInput.finishAutofillContext();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Registrasi berhasil! Silakan login.'),
          backgroundColor: Theme.of(context).colorScheme.primary,
        ),
      );
      context.pop();
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.errorMessage ?? 'Registrasi Gagal'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }
"""

    new_register = """
  Future<void> _register() async {
    setState(() {
      _apiError = null;
    });
    
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.register({
      'name': _nameController.text,
      'username': _usernameController.text,
      'email': _emailController.text,
      'password': _passwordController.text,
      'password_confirmation': _passwordConfirmController.text,
    });

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }

    if (success && mounted) {
      TextInput.finishAutofillContext();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Registrasi berhasil! Silakan login.'),
          backgroundColor: Theme.of(context).colorScheme.primary,
        ),
      );
      context.pop();
    } else if (mounted) {
      setState(() {
        _apiError = authProvider.errorMessage ?? 'Registrasi Gagal';
      });
    }
  }
"""
    content = content.replace(old_register.strip(), new_register.strip())

    # Add validators to fields
    content = re.sub(
        r"(controller: _nameController,)",
        r"\1\n                          validator: (value) => (value == null || value.trim().isEmpty) ? 'Nama tidak boleh kosong' : null,\n                          onChanged: (_) { if (_apiError != null) setState(() => _apiError = null); },",
        content
    )
    content = re.sub(
        r"(controller: _usernameController,)",
        r"\1\n                          validator: (value) => (value == null || value.trim().isEmpty) ? 'Username tidak boleh kosong' : null,\n                          onChanged: (_) { if (_apiError != null) setState(() => _apiError = null); },",
        content
    )
    content = re.sub(
        r"(controller: _emailController,)",
        r"\1\n                          validator: (value) => (value == null || value.trim().isEmpty) ? 'Email tidak boleh kosong' : null,\n                          onChanged: (_) { if (_apiError != null) setState(() => _apiError = null); },",
        content
    )
    content = re.sub(
        r"(controller: _passwordController,)",
        r"\1\n                          validator: (value) => (value == null || value.trim().isEmpty) ? 'Password tidak boleh kosong' : null,\n                          onChanged: (_) { if (_apiError != null) setState(() => _apiError = null); },",
        content
    )
    content = re.sub(
        r"(controller: _passwordConfirmController,)",
        r"\1\n                          validator: (value) {\n                            if (value == null || value.trim().isEmpty) return 'Konfirmasi tidak boleh kosong';\n                            if (value != _passwordController.text) return 'Password tidak cocok';\n                            return null;\n                          },\n                          onChanged: (_) { if (_apiError != null) setState(() => _apiError = null); },",
        content
    )
    
    content = re.sub(
        r"(hintText: 'Konfirmasi Password',)",
        r"\1\n                            errorText: _apiError,",
        content
    )

    with open(filepath, 'w', encoding='utf-8') as f:
        f.write(content)

try:
    update_login('lib/features/auth/login_screen.dart')
    update_register('lib/features/auth/register_screen.dart')
except Exception as e:
    print(f"Error: {e}")
