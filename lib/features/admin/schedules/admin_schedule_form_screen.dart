import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../../../../data/services/api_service.dart';

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
  String _selectedDay = 'Monday';
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  bool _isFlexible = false;

  bool _isLoading = false;
  bool _isLoadingGroups = true;
  List<dynamic> _groups = [];

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

    _fetchGroups();
  }

  Future<void> _fetchGroups() async {
    try {
      final groups = await _apiService.getGroups();
      if (mounted) {
        setState(() {
          _groups = groups;
          _isLoadingGroups = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingGroups = false);
        ShadToaster.of(context).show(ShadToast.destructive(description: Text('Gagal memuat grup: $e')));
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
      body: _isLoading || _isLoadingGroups
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
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: ShadTheme.of(context).colorScheme.border),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<int?>(
                          isExpanded: true,
                          value: _selectedGroupId,
                          hint: const Text('Jadwal Default (Semua)'),
                          items: [
                            const DropdownMenuItem<int?>(
                              value: null,
                              child: Text('Jadwal Default (Semua Pengguna)'),
                            ),
                            ..._groups.map<DropdownMenuItem<int?>>((g) {
                              return DropdownMenuItem<int?>(
                                value: g['id'],
                                child: Text(g['name'] ?? 'Unknown Group'),
                              );
                            }),
                          ],
                          onChanged: (val) {
                            setState(() => _selectedGroupId = val);
                          },
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
