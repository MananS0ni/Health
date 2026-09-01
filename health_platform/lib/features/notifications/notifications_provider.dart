import 'package:flutter_riverpod/flutter_riverpod.dart';

class NotificationItem {
  final String id;
  final String message;
  final bool read;
  final String createdAt;
  final String type; // e.g. 'lab_report', 'appointment', 'admission', 'prescription'
  final String? refId;

  const NotificationItem({
    required this.id,
    required this.message,
    required this.read,
    required this.createdAt,
    required this.type,
    this.refId,
  });

  NotificationItem copyWith({
    String? id,
    String? message,
    bool? read,
    String? createdAt,
    String? type,
    String? refId,
  }) {
    return NotificationItem(
      id: id ?? this.id,
      message: message ?? this.message,
      read: read ?? this.read,
      createdAt: createdAt ?? this.createdAt,
      type: type ?? this.type,
      refId: refId ?? this.refId,
    );
  }
}

class NotificationsNotifier extends Notifier<List<NotificationItem>> {
  @override
  List<NotificationItem> build() {
    return [
      const NotificationItem(
        id: 'notif_001',
        message: 'Your Complete Blood Count (CBC) lab report is ready for viewing.',
        read: false,
        createdAt: '10 mins ago',
        type: 'lab_report',
        refId: 'REP001',
      ),
      const NotificationItem(
        id: 'notif_002',
        message: 'Dr. Max Patel added a new prescription & diagnosis for Acute Pharyngitis.',
        read: false,
        createdAt: '1 hour ago',
        type: 'prescription',
        refId: 'REC001',
      ),
      const NotificationItem(
        id: 'notif_003',
        message: 'Inpatient Admission updated: Ward B-104 (General Male Ward).',
        read: true,
        createdAt: 'Yesterday',
        type: 'admission',
        refId: 'ADM001',
      ),
      const NotificationItem(
        id: 'notif_004',
        message: 'Reminder: Upcoming appointment with Dr. S. K. Gupta tomorrow at 10:00 AM.',
        read: true,
        createdAt: '2 days ago',
        type: 'appointment',
        refId: 'APT001',
      ),
    ];
  }

  void markAsRead(String id) {
    state = [
      for (final item in state)
        if (item.id == id) item.copyWith(read: true) else item
    ];
  }

  void markAllAsRead() {
    state = [for (final item in state) item.copyWith(read: true)];
  }

  void clearAll() {
    state = [];
  }
}

final notificationsProvider =
    NotifierProvider<NotificationsNotifier, List<NotificationItem>>(
        NotificationsNotifier.new);

final unreadNotificationsCountProvider = Provider<int>((ref) {
  final notifs = ref.watch(notificationsProvider);
  return notifs.where((n) => !n.read).length;
});
