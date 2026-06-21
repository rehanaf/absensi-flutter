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

  late TextEditingController _nameController;
  late TextEditingController _toleranceController;
  
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final schedule = widget.schedule;
    
    _nameController = TextEditingController(text: schedule?['name'] ?? '');
    _toleranceController = TextEditingController(text: schedule?['late_tolerance_minutes']?.toString() ?? '15');
    
    if (schedule != null) {
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

  @override
  void dispose() {
    _nameController.dispose();
    _toleranceController.dispose();
    super.dispose();
  }

  String _formatTimeOfDay(TimeOfDay time) {
    final h = time.hour.toString().padLeft(2, '0');
    final m = time.minute.toString().padLeft(2, '0');
    return '$h:$m';
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

    final data = {
      'name': _nameController.text,
      'start_time': _formatTimeOfDay(_startTime!),
      'end_time': _formatTimeOfDay(_endTime!),
      'late_tolerance_minutes': int.tryParse(_toleranceController.text) ?? 0,
    };

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
                    ShadInputFormField(
                      label: const Text('Nama Jadwal'),
                      placeholder: const Text('Contoh: Shift Pagi / Reguler'),
                      controller: _nameController,
                      validator: (v) => v.isEmpty ? 'Nama jadwal tidak boleh kosong' : null,
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

                    ShadInputFormField(
                      label: const Text('Toleransi Terlambat (Menit)'),
                      controller: _toleranceController,
                      keyboardType: TextInputType.number,
                      validator: (v) => v.isEmpty ? 'Toleransi tidak boleh kosong' : null,
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
