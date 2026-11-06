import 'package:flutter/material.dart';
import 'main_shell.dart';
import 'reward_tasks_screen.dart';

class ChallengesScreen extends StatelessWidget {
  final AppState appState;
  const ChallengesScreen({super.key, required this.appState});
  @override
  Widget build(BuildContext context) => SafeArea(
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: RewardTasksScreen(onBalanceChanged: appState.updateRewardBalance),
    ),
  );
}
