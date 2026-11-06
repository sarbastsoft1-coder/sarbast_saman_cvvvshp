import 'package:flutter/foundation.dart';

class ChallengeItem {
  ChallengeItem({
    required this.id,
    required this.title,
    required this.reward,
    required this.progress,
    required this.goal,
    this.done = false,
    this.sponsored = false,
  });
  final String id;
  final String title;
  final int reward;
  final int progress;
  final int goal;
  bool done;
  final bool sponsored;
  double get ratio => goal == 0 ? 0 : (progress / goal).clamp(0, 1);
}

/// Local weekly challenges for Ronix (HTML demo parity).
class ChallengesProvider extends ChangeNotifier {
  ChallengesProvider() {
    _seed();
  }

  final List<ChallengeItem> items = [];
  int daysLeft = 3;

  int get completedCount => items.where((c) => c.done).length;
  int get bonusReward => completedCount >= items.length ? 30 : 0;

  void _seed() {
    items
      ..clear()
      ..addAll([
        ChallengeItem(
          id: 'kurdistan',
          title: 'لە ٢ فرۆشیاری دروستکراوی کوردستان بکڕە',
          reward: 50,
          progress: 1,
          goal: 2,
        ),
        ChallengeItem(
          id: 'invite',
          title: 'هاوڕێیەک بانگهێشت بکە',
          reward: 75,
          progress: 0,
          goal: 1,
        ),
        ChallengeItem(
          id: 'store',
          title: 'دووکانی نوێی «بووتیکی ڕۆژ» ببینە',
          reward: 15,
          progress: 0,
          goal: 1,
          sponsored: true,
        ),
        ChallengeItem(
          id: 'review',
          title: 'هەڵسەنگاندن بە وێنە بنووسە',
          reward: 20,
          progress: 1,
          goal: 1,
          done: true,
        ),
        ChallengeItem(
          id: 'follow',
          title: '٣ دووکانی نوێ فۆڵۆ بکە',
          reward: 10,
          progress: 3,
          goal: 3,
          done: true,
        ),
      ]);
  }

  void markProgress(String id, {int by = 1}) {
    final item = items.where((c) => c.id == id).firstOrNull;
    if (item == null || item.done) return;
    final next = (item.progress + by).clamp(0, item.goal);
    items[items.indexOf(item)] = ChallengeItem(
      id: item.id,
      title: item.title,
      reward: item.reward,
      progress: next,
      goal: item.goal,
      done: next >= item.goal,
      sponsored: item.sponsored,
    );
    notifyListeners();
  }
}
