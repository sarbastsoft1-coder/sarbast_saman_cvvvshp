import 'package:flutter/foundation.dart';

class ChatMessage {
  ChatMessage({
    required this.text,
    required this.mine,
    required this.at,
  });
  final String text;
  final bool mine;
  final DateTime at;
}

class ChatThread {
  ChatThread({
    required this.id,
    required this.seller,
    required this.preview,
    required this.messages,
    this.unread = 0,
    this.productLabel,
  });
  final String id;
  final String seller;
  String preview;
  int unread;
  final String? productLabel;
  final List<ChatMessage> messages;
}

class ChatsProvider extends ChangeNotifier {
  ChatsProvider() {
    _seed();
  }

  final List<ChatThread> threads = [];

  void _seed() {
    threads
      ..clear()
      ..addAll([
        ChatThread(
          id: 'aso',
          seller: 'هەنگوینی ئاسۆ',
          preview: 'بەڵێ، لە بەشی قەبارە نیو کیلۆ هەڵبژێرە.',
          unread: 1,
          productLabel: 'هەنگوینی شاخی سروشتی',
          messages: [
            ChatMessage(
              text: 'سڵاو، ئەم هەنگوینە تازەیە؟',
              mine: true,
              at: DateTime.now().subtract(const Duration(minutes: 20)),
            ),
            ChatMessage(
              text: 'سڵاو، بەڵێ. لە هاوینی ئەمساڵ لە ناوچەی سۆران کۆکراوەتەوە.',
              mine: false,
              at: DateTime.now().subtract(const Duration(minutes: 12)),
            ),
            ChatMessage(
              text: 'دەتوانم نیو کیلۆ داوا بکەم؟',
              mine: true,
              at: DateTime.now().subtract(const Duration(minutes: 10)),
            ),
            ChatMessage(
              text: 'بەڵێ، لە بەشی قەبارە نیو کیلۆ هەڵبژێرە.',
              mine: false,
              at: DateTime.now().subtract(const Duration(minutes: 8)),
            ),
          ],
        ),
        ChatThread(
          id: 'roj',
          seller: 'بووتیکی ڕۆژ',
          preview: 'قەبارەی M بۆ درێژیی ١٦٥ گونجاوە.',
          unread: 0,
          messages: [
            ChatMessage(
              text: 'قەبارەی M بۆ درێژیی ١٦٥ گونجاوە.',
              mine: false,
              at: DateTime.now().subtract(const Duration(days: 1)),
            ),
          ],
        ),
        ChatThread(
          id: 'support',
          seller: 'پشتیوانیی Roni',
          preview: 'سوپاس، کێشەکەت چارەسەر کرا.',
          unread: 0,
          messages: [
            ChatMessage(
              text: 'سوپاس، کێشەکەت چارەسەر کرا.',
              mine: false,
              at: DateTime.now().subtract(const Duration(days: 3)),
            ),
          ],
        ),
      ]);
  }

  ChatThread? byId(String id) =>
      threads.where((t) => t.id == id).firstOrNull;

  void send(String threadId, String text) {
    final t = byId(threadId);
    if (t == null || text.trim().isEmpty) return;
    t.messages.add(
      ChatMessage(text: text.trim(), mine: true, at: DateTime.now()),
    );
    t.preview = text.trim();
    t.unread = 0;
    notifyListeners();
  }

  void open(String threadId) {
    final t = byId(threadId);
    if (t == null) return;
    t.unread = 0;
    notifyListeners();
  }
}
