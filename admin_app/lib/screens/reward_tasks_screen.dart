import 'package:flutter/material.dart';
import '../services/api_service.dart';

class RewardTasksScreen extends StatefulWidget {
  const RewardTasksScreen({super.key});
  @override
  State<RewardTasksScreen> createState() => _RewardTasksScreenState();
}

class _RewardTasksScreenState extends State<RewardTasksScreen> {
  static const bool admin = true;
  List<dynamic> tasks = [], submissions = [];
  bool loading = true, busy = false;
  String? error;
  num balance = 0;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    try {
      final result = await ApiService.get('/reward-tasks');
      if (result['status'] != 'success') {
        throw Exception(result['message'] ?? 'Unable to load tasks');
      }
      List<dynamic> pending = [];
      if (admin) {
        final reviews = await ApiService.get('/admin/task-submissions');
        if (reviews['status'] != 'success') {
          throw Exception(reviews['message'] ?? 'Unable to load submissions');
        }
        pending = reviews['data'];
      }
      if (!mounted) return;
      setState(() {
        tasks = result['data'];
        balance = result['balance'] ?? 0;
        submissions = pending;
        loading = false;
        error = null;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          loading = false;
          error = e.toString();
        });
      }
    }
  }

  Future<void> send(String endpoint, Map<String, dynamic> data) async {
    if (busy) return;
    setState(() => busy = true);
    try {
      final result = await ApiService.post(endpoint, data);
      if (result['status'] != 'success') {
        throw Exception(
          result['message'] ?? 'Please check your input and try again',
        );
      }
      await load();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Saved successfully')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> form({Map<String, dynamic>? task}) async {
    final title = TextEditingController();
    final description = TextEditingController();
    final points = TextEditingController();
    final key = GlobalKey<FormState>();
    final data = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(admin ? 'Create points task' : 'Submit proof'),
        content: SizedBox(
          width: 420,
          child: Form(
            key: key,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (admin)
                    TextFormField(
                      controller: title,
                      maxLength: 150,
                      decoration: const InputDecoration(
                        labelText: 'Task title',
                        hintText: 'Invite a friend',
                      ),
                      validator: (v) => v == null || v.trim().isEmpty
                          ? 'Enter a title'
                          : null,
                    ),
                  TextFormField(
                    controller: description,
                    minLines: 3,
                    maxLines: 5,
                    maxLength: 3000,
                    decoration: InputDecoration(
                      labelText: admin
                          ? 'Instructions and required proof'
                          : 'Proof of completion',
                      hintText: admin
                          ? 'Invite a friend and submit their account email for review.'
                          : 'For an invitation, enter your friend’s account email.',
                    ),
                    validator: (v) => v == null || v.trim().length < 5
                        ? 'Enter at least 5 characters'
                        : null,
                  ),
                  if (admin)
                    TextFormField(
                      controller: points,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Points (TERRA)',
                      ),
                      validator: (v) {
                        final n = int.tryParse(v ?? '');
                        return n == null || n < 1 || n > 100000
                            ? 'Enter 1–100000 whole points'
                            : null;
                      },
                    ),
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (!key.currentState!.validate()) return;
              Navigator.pop(
                context,
                admin
                    ? <String, dynamic>{
                        'title': title.text.trim(),
                        'description': description.text.trim(),
                        'reward_tokens': int.parse(points.text),
                      }
                    : <String, dynamic>{'proof': description.text.trim()},
              );
            },
            child: Text(admin ? 'Create task' : 'Submit for approval'),
          ),
        ],
      ),
    );
    if (data != null && mounted) {
      await send(
        admin ? '/admin/reward-tasks' : '/reward-tasks/${task!['id']}/submit',
        data,
      );
    }
    // Dispose after the dialog route has finished its closing animation.
    await Future<void>.delayed(const Duration(milliseconds: 300));
    title.dispose();
    description.dispose();
    points.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              admin ? 'Points tasks' : 'Earn points',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            IconButton(
              onPressed: busy ? null : load,
              icon: const Icon(Icons.refresh),
            ),
            if (admin)
              FilledButton.icon(
                onPressed: busy ? null : () => form(),
                icon: const Icon(Icons.add),
                label: const Text('Add task'),
              ),
          ],
        ),
        if (!admin) Text('Balance: $balance TERRA points'),
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 12),
          child: Text(
            'Complete a task and submit proof. Points are added after admin approval. Each task can be rewarded once.',
          ),
        ),
        if (loading || busy) const LinearProgressIndicator(),
        if (error != null)
          Text(error!, style: const TextStyle(color: Colors.red)),
        if (!loading && error == null && tasks.isEmpty)
          const Text('No tasks available yet.'),
        for (final task in tasks)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task['title'],
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Text(
                    '${(task['reward_tokens'] as num).toInt()} points',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(task['description']),
                  if (!admin)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child:
                          task['submission_status'] == 'pending' ||
                              task['submission_status'] == 'approved'
                          ? Text(
                              task['submission_status'] == 'approved'
                                  ? 'Approved — points added'
                                  : 'Waiting for admin approval',
                            )
                          : FilledButton(
                              onPressed: busy
                                  ? null
                                  : () => form(
                                      task: Map<String, dynamic>.from(task),
                                    ),
                              child: Text(
                                task['submission_status'] == 'rejected'
                                    ? 'Rejected — submit new proof'
                                    : 'Submit proof',
                              ),
                            ),
                    ),
                ],
              ),
            ),
          ),
        if (admin) ...[
          const SizedBox(height: 24),
          Text(
            'Pending approvals',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          if (submissions.isEmpty && !loading)
            const Text('No submissions awaiting review.'),
          for (final row in submissions)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${row['title']} · ${row['reward_tokens']} points'),
                    Text('${row['name']} (${row['email']})'),
                    SelectableText(row['proof']),
                    Wrap(
                      spacing: 12,
                      children: [
                        FilledButton(
                          onPressed: busy
                              ? null
                              : () => send(
                                  '/admin/task-submissions/${row['id']}/review',
                                  {'decision': 'approved'},
                                ),
                          child: const Text('Approve & award points'),
                        ),
                        TextButton(
                          onPressed: busy
                              ? null
                              : () => send(
                                  '/admin/task-submissions/${row['id']}/review',
                                  {'decision': 'rejected'},
                                ),
                          child: const Text('Reject'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
        ],
      ],
    );
  }
}
