part of '../../main.dart';

class RemindersPage extends StatefulWidget {
  const RemindersPage({super.key, required this.api});

  final ApiClient api;

  @override
  State<RemindersPage> createState() => _RemindersPageState();
}

class _RemindersPageState extends State<RemindersPage> {
  late Future<Map<String, dynamic>> _future = _load();
  final _confetti = ConfettiController(
    duration: const Duration(milliseconds: 1200),
  );

  @override
  void dispose() {
    _confetti.dispose();
    super.dispose();
  }

  Future<Map<String, dynamic>> _load() async {
    final data = await widget.api.get('/reminders/today');
    await NotificationService.instance.syncReminders(
      (data['reminders'] as List?) ?? [],
    );
    return data;
  }

  Future<void> _syncNow(List reminders) async {
    await NotificationService.instance.syncReminders(reminders);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Text('Notificacoes dos lembretes sincronizadas.'),
      ),
    );
  }

  Future<void> _complete(String id) async {
    try {
      final result = await widget.api.post('/reminders/$id/complete', {});
      if (!mounted) return;
      _showPointsToast(context, result['pointsEarned'] as int? ?? 0);
      final current = await _load();
      final reminders = (current['reminders'] as List?) ?? [];
      final allDone =
          reminders.isNotEmpty &&
          reminders.every(
            (item) => item is Map && item['completedToday'] == true,
          );
      if (allDone) _confetti.play();
      setState(() => _future = _load());
    } catch (error) {
      if (!mounted) return;
      _showError(context, error);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        DataScaffold(
          future: _future,
          onRefresh: () => setState(() => _future = _load()),
          builder: (data) {
            final reminders = (data['reminders'] as List?) ?? [];
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                SectionTitle(
                  'Hoje',
                  trailing: '${reminders.length}',
                  action: IconButton.filledTonal(
                    tooltip: 'Sincronizar notificacoes',
                    onPressed: reminders.isEmpty
                        ? null
                        : () => _syncNow(reminders),
                    icon: const Icon(Icons.notifications_active),
                  ),
                ),
                if (reminders.isNotEmpty)
                  InfoPanel(
                    icon: Icons.notifications_active,
                    title: 'Notificacoes ativas',
                    body:
                        'O celular avisara no horario de cada lembrete ativo.',
                  ),
                if (reminders.isNotEmpty) const SizedBox(height: 10),
                if (reminders.isEmpty)
                  const EmptyState(
                    text: 'Os lembretes aparecem depois da avaliacao.',
                  ),
                ...reminders.map((item) {
                  final reminder = item as Map<String, dynamic>;
                  final done = reminder['completedToday'] == true;
                  return ReminderCard(
                    item: reminder,
                    action: IconButton.filledTonal(
                      tooltip: done ? 'Concluido' : 'Concluir',
                      onPressed: done
                          ? null
                          : () => _complete(reminder['id'].toString()),
                      icon: Icon(done ? Icons.check_circle : Icons.check),
                    ),
                  );
                }),
              ],
            );
          },
        ),
        Align(
          alignment: Alignment.topCenter,
          child: ConfettiWidget(
            confettiController: _confetti,
            blastDirectionality: BlastDirectionality.explosive,
            numberOfParticles: 60,
            colors: const [
              teal600,
              teal400,
              Color(0xFFF59E0B),
              Color(0xFF7C3AED),
            ],
          ),
        ),
      ],
    );
  }
}
