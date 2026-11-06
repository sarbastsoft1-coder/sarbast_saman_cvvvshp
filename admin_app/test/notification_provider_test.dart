import 'package:flutter_test/flutter_test.dart';
import 'package:admin_app/models/notification.dart';
import 'package:admin_app/providers/notification_provider.dart';

/// Stand-in for the server so the feed logic can be exercised without a backend.
class FakeNotificationApi extends NotificationApi {
  FakeNotificationApi({this.fail = false});

  bool fail;
  int feedCalls = 0;
  int? lastSinceId;
  int markedRead = 0;
  int markedAll = 0;
  int removed = 0;
  List<AdminNotification> items = [];

  @override
  Future<NotificationPage> feed({int? sinceId, int limit = 50}) async {
    feedCalls++;
    lastSinceId = sinceId;
    if (fail) throw const NotificationApiException('offline');
    return NotificationPage(
      items: items,
      unreadCount: items.where((n) => !n.isRead).length,
      latestId: items.isEmpty ? 0 : items.first.id,
    );
  }

  @override
  Future<void> markAsRead(int id) async => markedRead++;

  @override
  Future<void> markAllAsRead() async => markedAll++;

  @override
  Future<void> remove(int id) async => removed++;
}

AdminNotification notification(int id, {bool read = false}) {
  return AdminNotification(
    id: id,
    userId: 7,
    type: AdminNotificationType.system,
    title: 'Reward task awaiting review',
    body: 'Submission #$id needs review.',
    actionLabel: 'Review submissions',
    actionRoute: '/reward-tasks',
    readAt: read ? DateTime.now() : null,
    createdAt: DateTime(2026, 10, 1, 12),
  );
}

void main() {
  test('parses a server row, including its action target', () {
    final parsed = AdminNotification.fromJson(const {
      'id': 2,
      'user_id': 7,
      'type': 'system',
      'title': 'Reward task awaiting review',
      'body': 'A customer submitted a reward task.',
      'action_label': 'Review submissions',
      'action_route': '/reward-tasks',
      'action_args': null,
      'read_at': null,
      'created_at': '2026-10-01T10:40:24.000000Z',
    });

    expect(parsed.id, 2);
    expect(parsed.type, AdminNotificationType.system);
    expect(parsed.actionRoute, '/reward-tasks');
    expect(parsed.isRead, isFalse);
  });

  test('an unknown type is still shown, as a system row', () {
    final parsed = AdminNotification.fromJson(const {
      'id': 3,
      'user_id': 7,
      'type': 'something_new',
      'title': 'Heads up',
      'body': '',
      'read_at': '2026-10-01T10:40:24.000000Z',
      'created_at': '2026-10-01T10:40:24.000000Z',
    });

    expect(parsed.type, AdminNotificationType.system);
    expect(parsed.isRead, isTrue);
  });

  test('refresh keeps newest first and remembers the polling cursor', () async {
    final api = FakeNotificationApi()
      ..items = [notification(5), notification(4)];
    final provider = NotificationProvider(api: api);

    await provider.refresh(full: true);
    expect(provider.items.map((n) => n.id), [5, 4]);
    expect(provider.unreadCount, 2);
    expect(provider.offline, isFalse);
    expect(api.lastSinceId, isNull);

    await provider.refresh();
    expect(api.lastSinceId, 5);

    api.items = [notification(9)];
    await provider.refresh();
    expect(provider.items.map((n) => n.id), [9, 5, 4]);

    provider.dispose();
  });

  test('a failed poll flags offline and keeps the rows already on screen',
      () async {
    final api = FakeNotificationApi()..items = [notification(5)];
    final provider = NotificationProvider(api: api);

    await provider.refresh(full: true);
    api.fail = true;
    await provider.refresh(full: true);

    expect(provider.offline, isTrue);
    expect(provider.items.map((n) => n.id), [5]);

    provider.dispose();
  });

  test('marking read is optimistic and confirms with the server', () async {
    final api = FakeNotificationApi()
      ..items = [notification(5), notification(4)];
    final provider = NotificationProvider(api: api);
    await provider.refresh(full: true);

    provider.markAsRead(5);
    expect(provider.unreadCount, 1, reason: 'badge drops before the POST lands');
    expect(provider.items.first.isRead, isTrue);
    await Future<void>.delayed(Duration.zero);
    expect(api.markedRead, 1);

    provider.markAllAsRead();
    expect(provider.unreadCount, 0);
    await Future<void>.delayed(Duration.zero);
    expect(api.markedAll, 1);

    provider.dispose();
  });

  test('only one polling timer ever runs, and reset clears the feed', () async {
    final api = FakeNotificationApi()..items = [notification(5)];
    final provider = NotificationProvider(api: api);

    provider.startPolling();
    provider.startPolling();
    expect(provider.isPolling, isTrue);
    await Future<void>.delayed(Duration.zero);
    expect(api.feedCalls, 1, reason: 'a second start must not refetch');

    provider.stopPolling();
    expect(provider.isPolling, isFalse);

    provider.reset();
    expect(provider.items, isEmpty);
    expect(provider.unreadCount, 0);
    expect(provider.offline, isFalse);

    provider.dispose();
  });
}
