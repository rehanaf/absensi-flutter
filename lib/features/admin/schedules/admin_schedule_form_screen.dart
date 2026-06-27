import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../../../../data/services/api_service.dart';
import 'dart:async';

class AdminScheduleFormScreen extends StatefulWidget {
  final Map<String, dynamic>? schedule;

  const AdminScheduleFormScreen({super.key, this.schedule});

  @override
  State<AdminScheduleFormScreen> createState() => _AdminScheduleFormScreenState();
}

class _AdminScheduleFormScreenState extends State<AdminScheduleFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _apiService = ApiService();

  int? _selectedGroupId;
  String _selectedGroupName = 'Jadwal Default (Semua)';
  
  String _selectedDay = 'Monday';
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  bool _isFlexible = false;

  bool _isLoading = false;

  final Map<String, String> _daysMap = {
    'Monday': 'Senin',
    'Tuesday': 'Selasa',
    'Wednesday': 'Rabu',
    'Thursday': 'Kamis',
    'Friday': 'Jumat',
    'Saturday': 'Sabtu',
    'Sunday': 'Minggu',
  };

  @override
  void initState() {
    super.initState();
    final schedule = widget.schedule;
    
    if (schedule != null) {
      _selectedGroupId = schedule['group_id'];
      _selectedGroupName = schedule['group']?['name'] ?? (_selectedGroupId == null ? 'Jadwal Default (Semua)' : 'Group #$_selectedGroupId');
      _selectedDay = schedule['day'] ?? 'Monday';
      _isFlexible = schedule['is_flexible'] == 1 || schedule['is_flexible'] == true;

      if (schedule['start_time'] != null) {
        final parts = schedule['start_time'].toString().split(':');
        if (parts.length >= 2) _startTime = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
      }
      if (schedule['end_time'] != null) {
        final parts = schedule['end_time'].toString().split(':');
        if (parts.length >= 2) _endTime = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
      }
    }
  }

  String _formatTimeOfDay(TimeOfDay time) {
    final h = time.hour.toString().padLeft(2, '0');
    final m = time.minute.toString().padLeft(2, '0');
    return '$h:$m:00'; // H:i:s
  }

  Future<void> _pickTime(bool isStart) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isStart ? (_startTime ?? const TimeOfDay(hour: 7, minute: 0)) : (_endTime ?? const TimeOfDay(hour: 16, minute: 0)),
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        if (isStart) _startTime = picked;
        else _endTime = picked;
      });
    }
  }

  Future<void> _showGroupPicker() async {
    final selectedGroup = await showDialog<Map<String, dynamic>?>(
      context: context,
      builder: (context) => _GroupSelectionDialog(apiService: _apiService),
    );

    // If popped with exactly null, it means no selection/canceled, but if we want 'Default' we return an empty map { 'id': null, 'name': '...' }
    if (selectedGroup != null) {
      setState(() {
        _selectedGroupId = selectedGroup['id'];
        _selectedGroupName = selectedGroup['name'] ?? 'Unknown';
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_startTime == null || _endTime == null) {
      ShadToaster.of(context).show(const ShadToast.destructive(description: Text('Jam masuk dan pulang wajib diisi')));
      return;
    }

    setState(() => _isLoading = true);

    final data = <String, dynamic>{
      'day': _selectedDay,
      'start_time': _formatTimeOfDay(_startTime!),
      'end_time': _formatTimeOfDay(_endTime!),
      'is_flexible': _isFlexible,
    };

    if (_selectedGroupId != null) {
      data['group_id'] = _selectedGroupId;
    }

    try {
      if (widget.schedule == null) {
        await _apiService.createSchedule(data);
        if (mounted) ShadToaster.of(context).show(const ShadToast(description: Text('Jadwal berhasil ditambahkan')));
      } else {
        await _apiService.updateSchedule(widget.schedule!['id'], data);
        if (mounted) ShadToaster.of(context).show(const ShadToast(description: Text('Jadwal berhasil diperbarui')));
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
    final isEditing = widget.schedule != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Jadwal' : 'Tambah Jadwal'),
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
                    Text('Grup', style: ShadTheme.of(context).textTheme.small),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: _showGroupPicker,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          border: Border.all(color: ShadTheme.of(context).colorScheme.border),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(_selectedGroupName),
                            const Icon(LucideIcons.chevronDown, size: 16),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    Text('Hari', style: ShadTheme.of(context).textTheme.small),
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
                          value: _selectedDay,
                          items: _daysMap.entries.map<DropdownMenuItem<String>>((entry) {
                            return DropdownMenuItem<String>(
                              value: entry.key,
                              child: Text(entry.value),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) setState(() => _selectedDay = val);
                          },
                        ),
                      ),
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
                                      Text(_startTime != null ? _formatTimeOfDay(_startTime!) : 'Pilih Waktu'),
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
                              Text('Jam Pulang', style: ShadTheme.of(context).textTheme.small),
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
                                      Text(_endTime != null ? _formatTimeOfDay(_endTime!) : 'Pilih Waktu'),
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

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Waktu Fleksibel?'),
                              Text('Aktifkan jika tidak ada teguran terlambat', style: TextStyle(fontSize: 12, color: Colors.grey)),
                            ],
                          ),
                        ),
                        ShadSwitch(
                          value: _isFlexible,
                          onChanged: (val) {
                            setState(() => _isFlexible = val);
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    
                    ShadButton(
                      onPressed: _submit,
                      child: const Text('Simpan Jadwal'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

class _GroupSelectionDialog extends StatefulWidget {
  final ApiService apiService;

  const _GroupSelectionDialog({required this.apiService});

  @override
  State<_GroupSelectionDialog> createState() => _GroupSelectionDialogState();
}

class _GroupSelectionDialogState extends State<_GroupSelectionDialog> {
  List<dynamic> _searchResults = [];
  bool _isLoading = false;
  String _searchQuery = '';
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _searchGroups('');
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _searchGroups(query);
    });
  }

  Future<void> _searchGroups(String query) async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _searchQuery = query;
    });

    try {
      final response = await widget.apiService.getGroups(search: query);
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
            Text('Pilih Kelompok', style: ShadTheme.of(context).textTheme.h4),
            const SizedBox(height: 16),
            ShadInput(
              placeholder: const Text('Cari kelompok...'),
              onChanged: _onSearchChanged,
            ),
            const SizedBox(height: 16),
            
            // Option for default (All)
            ListTile(
              leading: const Icon(LucideIcons.users, color: Colors.blue),
              title: const Text('Jadwal Default (Semua Pengguna)', style: TextStyle(fontWeight: FontWeight.bold)),
              onTap: () => Navigator.pop(context, {'id': null, 'name': 'Jadwal Default (Semua)'}),
            ),
            const Divider(),

            if (_isLoading)
              const Expanded(child: Center(child: CircularProgressIndicator()))
            else if (_searchResults.isEmpty)
              Expanded(
                child: Center(
                  child: Text(
                    _searchQuery.isEmpty ? 'Tidak ada kelompok tersedia.' : 'Kelompok tidak ditemukan.',
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
                    final group = _searchResults[index];
                    return ListTile(
                      title: Text(group['name'] ?? 'No Name', style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(group['type'] ?? ''),
                      onTap: () => Navigator.pop(context, group),
                    );
                  },
                ),
              ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: ShadButton.outline(
                child: const Text('Batal'),
                onPressed: () => Navigator.pop(context), // returns null
              ),
            )
          ],
        ),
      ),
    );
  }
}

