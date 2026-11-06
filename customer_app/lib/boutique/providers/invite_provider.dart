import 'package:flutter/foundation.dart';

class InviteRow {
  InviteRow({
    required this.name,
    required this.status,
    this.reward,
  });
  final String name;
  final String status; // done | pending
  final int? reward;
}

class InviteProvider extends ChangeNotifier {
  InviteProvider();

  final String code = 'SARH75';
  final int monthlyLimit = 3;
  final List<InviteRow> invites = [
    InviteRow(name: 'ئاوات', status: 'done', reward: 75),
    InviteRow(name: 'شیلان', status: 'pending'),
  ];

  int get usedThisMonth => invites.length;
}