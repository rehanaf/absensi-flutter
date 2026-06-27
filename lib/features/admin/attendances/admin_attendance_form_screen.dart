import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../../../../data/services/api_service.dart';
import 'dart:async';

class AdminAttendanceFormScreen extends StatefulWidget {
  final Map<String, dynamic>? attendance;

  const AdminAttendanceFormScreen({super.key, this.attendance});

  @override
  State<AdminAttendanceFormScreen> createState() => _AdminAttendanceFormScreenState();
}

class _AdminAttendanceFormScreenState extends State<AdminAttendanceFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _apiService = ApiService();

  late TextEditingController _statusController;
  late TextEditingController _lateMinutesController;

  int? _selectedUserId;
  String _selectedUserName = 'Pilih Pengguna';
  
  DateTime? _selectedDate;
  TimeOfDay? _checkInTime;
  TimeOfDay? _checkOutTime;
  bool _isLate = false;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final att = widget.attendance;

    _statusController = TextEditingController(text: att?['status'] ?? '');
    _lateMinutesController = TextEditingController(text: att?['late_minutes']?.toString() ?? '0');

    if (att != null) {
      _selectedUserId = att['user_id'];
      _selectedUserName = att['user']?['name'] ?? 'Pengguna #${att['user_id']}';
      
      if (att['date'] != null) {
        _selectedDate = DateTime.tryParse(att['date']);
      }
      if (att['check_in'] != null) {
        final parts = att['check_in'].toString().split(':');
        if (parts.length >= 2) _checkInTime = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
      }
      if (att['check_out'] != null) {
        final parts = att['check_out'].toString().split(':');
        if (parts.length >= 2) _checkOutTime = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
      }
      _isLate = att['is_late'] == 1 || att['is_late'] == true;
    } else {
      _selectedDate = DateTime.now();
    }
  }

  @override
  void dispose() {
    _statusController.dispose();
    _lateMinutesController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime date) {
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '${date.year}-$m-$d';
  }

  String _formatTimeOfDay(TimeOfDay time) {
    final h = time.hour.toString().padLeft(2, '0');
    final m = time.minute.toString().padLeft(2, '0');
    return '$h:$m:00'; // backend expects H:i:s
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _pickTime(bool isStart) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isStart ? (_checkInTime ?? const TimeOfDay(hour: 7, minute: 0)) : (_checkOutTime ?? const TimeOfDay(hour: 16, minute: 0)),
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        if (isStart) _checkInTime = picked;
        else _checkOutTime = picked;
      });
    }
  }

  Future<void> _showUserPicker() async {
    final selectedUser = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => _UserSelectionDialog(apiService: _apiService),
    );

    if (selectedUser != null) {
      setState(() {
        _selectedUserId = selectedUser['id'];
        _selectedUserName = selectedUser['name'] ?? 'Unknown';
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedUserId == null || _selectedDate == null) {
      ShadToaster.of(context).show(const ShadToast.destructive(description: Text('Pengguna dan Tanggal wajib diisi')));
      return;
    }

    setState(() => _isLoading = true);

    final data = <String, dynamic>{
      'user_id': _selectedUserId,
      'date': _formatDate(_selectedDate!),
      'status': _statusController.text.isEmpty ? 'hadir' : _statusController.text,
      'is_late': _isLate,
      'late_minutes': int.tryParse(_lateMinutesController.text) ?? 0,
    };

    if (_checkInTime != null) {
      data['check_in'] = _formatTimeOfDay(_checkInTime!);
    }
    if (_checkOutTime != null) {
      data['check_out'] = _formatTimeOfDay(_checkOutTime!);
    }

    try {
      if (widget.attendance == null) {
        await _apiService.createAttendance(data);
        if (mounted) ShadToaster.of(context).show(const ShadToast(description: Text('Absensi berhasil ditambahkan')));
      } else {
        await _apiService.updateAttendance(widget.attendance!['id'], data);
        if (mounted) ShadToaster.of(context).show(const ShadToast(description: Text('Data absensi berhasil diperbarui')));
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
    final isEditing = widget.attendance != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Absensi' : 'Tambah Absensi Manual'),
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
                    Text('Pengguna', style: ShadTheme.of(context).textTheme.small),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: _showUserPicker,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          border: Border.all(color: ShadTheme.of(context).colorScheme.border),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(_selectedUserName),
                            const Icon(LucideIcons.chevronDown, size: 16),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Tanggal', style: ShadTheme.of(context).textTheme.small),
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: _pickDate,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              border: Border.all(color: ShadTheme.of(context).colorScheme.border),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(_selectedDate != null ? _formatDate(_selectedDate!) : 'Pilih Tanggal'),
                                const Icon(LucideIcons.calendar, size: 16),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Jam Masuk', style: ShadTheme.of(context).textTheme.small),
                              const SizedBox(height: 8),
                              GestureDetector(
                                onTap: () => _pickTime(true),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: ShadTheme.of(context).colorScheme.border),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(_checkInTime != null ? _formatTimeOfDay(_checkInTime!) : '--:--:--'),
                                      const Icon(LucideIcons.clock, size: 16),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Jam Keluar', style: ShadTheme.of(context).textTheme.small),
                              const SizedBox(height: 8),
                              GestureDetector(
                                onTap: () => _pickTime(false),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: ShadTheme.of(context).colorScheme.border),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(_checkOutTime != null ? _formatTimeOfDay(_checkOutTime!) : '--:--:--'),
                                      const Icon(LucideIcons.clock, size: 16),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    ShadInputFormField(
                      label: const Text('Status (Teks Bebas)'),
                      placeholder: const Text('Contoh: hadir, sakit, izin...'),
                      controller: _statusController,
                      validator: (v) => v.isEmpty ? 'Status wajib diisi' : null,
                    ),
                    const SizedBox(height: 24),
                    
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Terlambat?'),
                              Text('Tandai jika pengguna ini terlambat', style: TextStyle(fontSize: 12, color: Colors.grey)),
                            ],
                          ),
                        ),
                        ShadSwitch(
                          value: _isLate,
                          onChanged: (val) {
                            setState(() => _isLate = val);
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    if (_isLate)
                      ShadInputFormField(
                        label: const Text('Jumlah Keterlambatan (Menit)'),
                        controller: _lateMinutesController,
                        keyboardType: TextInputType.number,
                        validator: (v) => v.isEmpty ? 'Isi dengan 0 jika tidak pasti' : null,
                      ),
                    
                    const SizedBox(height: 32),
                    
                    ShadButton(
                      onPressed: _submit,
                      child: const Text('Simpan Absensi'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

class _UserSelectionDialog extends StatefulWidget {
  final ApiService apiService;

  const _UserSelectionDialog({required this.apiService});

  @override
  State<_UserSelectionDialog> createState() => _UserSelectionDialogState();
}

class _UserSelectionDialogState extends State<_UserSelectionDialog> {
  List<dynamic> _searchResults = [];
  bool _isLoading = false;
  String _searchQuery = '';
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _searchUsers('');
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _searchUsers(query);
    });
  }

  Future<void> _searchUsers(String query) async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _searchQuery = query;
    });

    try {
      final response = await widget.apiService.getUsers(search: query);
      if (mounted) {
        setState(() {
          _searchResults = response['data'] as List<dynamic>? ?? [];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        padding: const EdgeInsets.all(24),
        constraints: const BoxConstraints(maxHeight: 600, maxWidth: 400),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Pilih Pengguna', style: ShadTheme.of(context).textTheme.h4),
            const SizedBox(height: 16),
            ShadInput(
              placeholder: const Text('Cari pengguna...'),
              onChanged: _onSearchChanged,
            ),
            const SizedBox(height: 16),
            if (_isLoading)
              const Expanded(child: Center(child: CircularProgressIndicator()))
            else if (_searchResults.isEmpty)
              Expanded(
                child: Center(
                  child: Text(
                    _searchQuery.isEmpty ? 'Tidak ada pengguna tersedia.' : 'Pengguna tidak ditemukan.',
                    style: ShadTheme.of(context).textTheme.muted,
                  ),
                ),
              )
            else
              Expanded(
                child: ListView.separated(
                  itemCount: _searchResults.length,
                  separatorBuilder: (context, index) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final user = _searchResults[index];
                    return ListTile(
                      title: Text(user['name'] ?? 'No Name', style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(user['email'] ?? ''),
                      onTap: () => Navigator.pop(context, user),
                    );
                  },
                ),
              ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: ShadButton.outline(
                child: const Text('Batal'),
                onPressed: () => Navigator.pop(context),
              ),
            )
          ],
        ),
      ),
    );
  }
}

