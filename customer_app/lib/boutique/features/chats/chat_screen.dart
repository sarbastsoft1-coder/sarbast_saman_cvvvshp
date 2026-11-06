import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/boutique_colors.dart';
import '../../providers/chats_provider.dart';
import '../../widgets/store_components.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key, required this.threadId});
  final String threadId;
  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _input = TextEditingController();

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final chats = context.watch<ChatsProvider>();
    final thread = chats.byId(widget.threadId);
    if (thread == null) {
      return const Scaffold(body: Center(child: Text('گفتوگۆ نەدۆزرایەوە')));
    }
    return Scaffold(
      backgroundColor: BoutiqueColors.cream,
      appBar: AppBar(title: Text(thread.seller)),
      body: Column(
        children: [
          if (thread.productLabel != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: RoniCard(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Row(
                  children: [
                    const Icon(Icons.shopping_bag_outlined, color: BoutiqueColors.dustyPink),
                    const SizedBox(width: 10),
                    Expanded(child: Text(thread.productLabel!, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13))),
                  ],
                ),
              ),
            ),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: StoreNotice(
              'بۆ پاراستنی خۆت، پارە تەنها لە کاتی گەیاندن بدە، و ژمارە یان پارەدان لە دەرەوەی Roni مەکە.',
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: thread.messages.length,
              itemBuilder: (context, i) {
                final m = thread.messages[i];
                return Align(
                  alignment: m.mine ? AlignmentDirectional.centerStart : AlignmentDirectional.centerEnd,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.78),
                    padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
                    decoration: BoxDecoration(
                      color: m.mine ? BoutiqueColors.ink : Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(16),
                        topRight: const Radius.circular(16),
                        bottomLeft: Radius.circular(m.mine ? 4 : 16),
                        bottomRight: Radius.circular(m.mine ? 16 : 4),
                      ),
                    ),
                    child: Text(
                      m.text,
                      style: TextStyle(
                        color: m.mine ? Colors.white : BoutiqueColors.charcoal,
                        height: 1.7,
                        fontSize: 13.5,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
              child: Row(
                children: [
                  IconButton(onPressed: () {}, icon: const Icon(Icons.camera_alt_outlined)),
                  Expanded(
                    child: TextField(
                      controller: _input,
                      decoration: const InputDecoration(hintText: 'نامەیەک بنووسە…'),
                      onSubmitted: (_) => _send(chats),
                    ),
                  ),
                  const SizedBox(width: 6),
                  IconButton.filled(
                    style: IconButton.styleFrom(backgroundColor: BoutiqueColors.ink),
                    onPressed: () => _send(chats),
                    icon: const Icon(Icons.send_rounded, color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _send(ChatsProvider chats) {
    chats.send(widget.threadId, _input.text);
    _input.clear();
  }
}
