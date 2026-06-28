import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../../data/services/api_service.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool _isLoading = true;
  List<dynamic> _notifications = [];

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
  }

  Future<void> _fetchNotifications() async {
    setState(() => _isLoading = true);
    try {
      final apiService = ApiService();
      final response = await apiService.getNotifications();
      setState(() {
        if (response is Map) {
          if (response.containsKey('data') && response['data'] is List) {
            _notifications = response['data'];
          } else if (response.containsKey('notifications') && response['notifications'] is List) {
            _notifications = response['notifications'];
          } else {
            var listVal = response.values.firstWhere((v) => v is List, orElse: () => null);
            if (listVal != null) {
              _notifications = listVal;
            } else {
              _notifications = [];
            }
          }
        } else if (response is List) {
          _notifications = response;
        } else {
          _notifications = [];
        }
      });
    } catch (e) {
      if (mounted) {
        ShadToaster.of(context).show(
          ShadToast.destructive(
            title: const Text('Gagal Memuat Notifikasi'),
            description: Text(e.toString()),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _markAsRead(dynamic notification) async {
    // Determine the read status field based on typical Laravel structures
    bool isRead = false;
    if (notification is Map && notification.containsKey('is_read')) {
      isRead = notification['is_read'] == 1 || notification['is_read'] == true;
    } else if (notification is Map && notification.containsKey('read_at')) {
      isRead = notification['read_at'] != null;
    }

    if (isRead) return;

    try {
      final apiService = ApiService();
      if (notification is Map && notification['id'] != null) await apiService.markNotificationAsRead(notification['id']);
      
      setState(() {
        if (notification is Map && notification.containsKey('is_read')) {
          notification['is_read'] = 1;
        } else if (notification is Map && notification.containsKey('read_at')) {
          notification['read_at'] = DateTime.now().toIso8601String();
        }
      });
    } catch (e) {
      if (mounted) {
        ShadToaster.of(context).show(
          ShadToast.destructive(
            title: const Text('Gagal Menandai Dibaca'),
            description: Text(e.toString()),
          ),
        );
      }
    }
  }

  Future<void> _markAllAsRead() async {
    try {
      final apiService = ApiService();
      await apiService.markAllNotificationsAsRead();
      await _fetchNotifications();
    } catch (e) {
      if (mounted) {
        ShadToaster.of(context).show(
          ShadToast.destructive(
            title: const Text('Gagal Menandai Semua Dibaca'),
            description: Text(e.toString()),
          ),
        );
      }
    }
  }

  String _getNotificationTitle(dynamic notification) {
    if (notification is Map && notification.containsKey('title')) return notification['title'];
    if (notification is Map && notification.containsKey('data') && notification['data'] is Map && notification['data'] is Map && notification['data'].containsKey('title')) {
      return notification['data']['title'];
    }
    return 'Notifikasi Baru';
  }

  String _getNotificationMessage(dynamic notification) {
    if (notification is Map && notification.containsKey('message')) return notification['message'];
    if (notification is Map && notification.containsKey('body')) return notification['body'];
    if (notification is Map && notification.containsKey('data') && notification['data'] is Map && notification['data'] is Map && notification['data'].containsKey('message')) {
      return notification['data']['message'];
    }
    return '';
  }

  bool _isNotificationRead(dynamic notification) {
    if (notification is Map && notification.containsKey('is_read')) {
      return notification['is_read'] == 1 || notification['is_read'] == true;
    } else if (notification is Map && notification.containsKey('read_at')) {
      return notification['read_at'] != null;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifikasi'),
        actions: [
          if (_notifications.isNotEmpty)
            IconButton(
              icon: const Icon(LucideIcons.checkCheck),
              tooltip: 'Tandai Semua Dibaca',
              onPressed: _markAllAsRead,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _notifications.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(LucideIcons.bellOff, size: 48, color: ShadTheme.of(context).colorScheme.mutedForeground),
                      const SizedBox(height: 16),
                      Text(
                        'Tidak ada notifikasi',
                        style: ShadTheme.of(context).textTheme.large,
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _fetchNotifications,
                  child: ListView.separated(
                    itemCount: _notifications.length,
                    separatorBuilder: (context, index) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final notification = _notifications[index];
                      final title = _getNotificationTitle(notification);
                      final message = _getNotificationMessage(notification);
                      final isRead = _isNotificationRead(notification);

                      return ListTile(
                        onTap: () => _markAsRead(notification),
                        tileColor: isRead ? null : ShadTheme.of(context).colorScheme.muted.withOpacity(0.3),
                        leading: CircleAvatar(
                          backgroundColor: isRead 
                              ? ShadTheme.of(context).colorScheme.muted 
                              : ShadTheme.of(context).colorScheme.primary,
                          child: Icon(
                            LucideIcons.bell,
                            color: isRead 
                                ? ShadTheme.of(context).colorScheme.mutedForeground 
                                : ShadTheme.of(context).colorScheme.primaryForeground,
                          ),
                        ),
                        title: Text(
                          title,
                          style: TextStyle(
                            fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text(message),
                            if (notification is Map && notification['created_at'] != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                notification['created_at'].toString().split('T')[0],
                                style: TextStyle(
                                  fontSize: 12,
                                  color: ShadTheme.of(context).colorScheme.mutedForeground,
                                ),
                              ),
                            ]
                          ],
                        ),
                        trailing: !isRead 
                            ? Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: ShadTheme.of(context).colorScheme.primary,
                                ),
                              )
                            : null,
                      );
                    },
                  ),
                ),
    );
  }
}
