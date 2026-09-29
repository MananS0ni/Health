import '../../core/network/api_client.dart';
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
  List<NotificationItem> build() => [];

  Future<void> fetch() async {
    final rows = await ApiClient().getList('/care/notifications/');
    if (!ref.mounted) return;
    state = rows.map((r) => NotificationItem(id:r['id'].toString(),message:r['message'],read:r['read'],createdAt:DateTime.parse(r['created_at']).toLocal().toString(),type:r['type'],refId:r['ref_id'])).toList();
  }
  Future<void> markAsRead(String id) async {
    await ApiClient().patchData('/care/notifications/', {'id':int.parse(id)});
    if (ref.mounted) state = [for(final item in state) if(item.id==id) item.copyWith(read:true) else item];
  }
  Future<void> markAllAsRead() async {
    for (final item in state.where((n) => !n.read).toList()) { await markAsRead(item.id); }
  }
  void clearAll() => state=[];
}

final notificationsProvider =
    NotifierProvider<NotificationsNotifier, List<NotificationItem>>(
        NotificationsNotifier.new);

final unreadNotificationsCountProvider = Provider<int>((ref) {
  final notifs = ref.watch(notificationsProvider);
  return notifs.where((n) => !n.read).length;
});
