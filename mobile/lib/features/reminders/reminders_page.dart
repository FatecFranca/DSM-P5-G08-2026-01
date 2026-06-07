part of '../../main.dart';

class RemindersPage extends StatefulWidget {
  const RemindersPage({
    super.key,
    required this.api,
    this.refreshSignal = 0,
  });

  final ApiClient api;
  final int refreshSignal;

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

  void _reload() {
    final next = _load();
    setState(() => _future = next);
  }

  @override
  void didUpdateWidget(covariant RemindersPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.refreshSignal != widget.refreshSignal) {
      _reload();
    }
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
        content: Text('Lembretes sincronizados no celular.'),
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
      _reload();
    } catch (error) {
      if (!mounted) return;
      _showError(context, error);
    }
  }

  Future<void> _delete(String id) async {
    try {
      await widget.api.delete('/reminders/$id');
      _reload();
    } catch (error) {
      if (!mounted) return;
      _showError(context, error);
    }
  }

  Future<void> _showEditor({Map<String, dynamic>? reminder}) async {
    final title = TextEditingController(text: reminder?['title']?.toString() ?? '');
    final message = TextEditingController(text: reminder?['message']?.toString() ?? '');
    final time = TextEditingController(text: reminder?['timeOfDay']?.toString() ?? '09:00');
    var type = reminder?['type']?.toString() ?? 'WATER';
    final messenger = ScaffoldMessenger.of(context);

    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: Text(reminder == null ? 'Novo lembrete' : 'Editar lembrete'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: title,
                  decoration: const InputDecoration(labelText: 'Título'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: message,
                  decoration: const InputDecoration(labelText: 'Mensagem (opcional)'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: time,
                  decoration: const InputDecoration(
                    labelText: 'Horário (HH:MM)',
                    hintText: '09:00',
                  ),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Tipo',
                    style: Theme.of(dialogContext).textTheme.labelLarge,
                  ),
                ),
                const SizedBox(height: 4),
                DropdownButton<String>(
                  value: type,
                  isExpanded: true,
                  items: const [
                    DropdownMenuItem(value: 'WATER', child: Text('Água')),
                    DropdownMenuItem(value: 'MEAL', child: Text('Refeição')),
                    DropdownMenuItem(value: 'SLEEP', child: Text('Sono')),
                    DropdownMenuItem(value: 'EXERCISE', child: Text('Exercício')),
                  ],
                  onChanged: (value) =>
                      setDialogState(() => type = value ?? 'WATER'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Salvar'),
            ),
          ],
        ),
      ),
    );

    if (saved != true || !mounted) {
      title.dispose();
      message.dispose();
      time.dispose();
      return;
    }

    try {
      final body = {
        'type': type,
        'title': title.text.trim(),
        'message': message.text.trim().isEmpty ? null : message.text.trim(),
        'timeOfDay': time.text.trim(),
      };
      if (reminder == null) {
        await widget.api.post('/reminders', body);
      } else {
        await widget.api.patch('/reminders/${reminder['id']}', body);
      }
      _reload();
    } catch (error) {
      messenger.showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          showCloseIcon: true,
          content: Text(friendlyErrorMessage(error)),
        ),
      );
    } finally {
      title.dispose();
      message.dispose();
      time.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        DataScaffold(
          future: _future,
          onRefresh: _reload,
          builder: (data) {
            final reminders = (data['reminders'] as List?) ?? [];
            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
              children: [
                SectionTitle(
                  'Hoje',
                  trailing: '${reminders.length}',
                  action: IconButton.filledTonal(
                    tooltip: 'Sincronizar notificações',
                    onPressed: reminders.isEmpty
                        ? null
                        : () => _syncNow(reminders),
                    icon: const Icon(Icons.notifications_active),
                  ),
                ),
                if (reminders.isEmpty)
                  const EmptyState(
                    text: 'Crie lembretes ou responda o questionário para receber sugestões.',
                  ),
                ...reminders.map((item) {
                  final reminder = item as Map<String, dynamic>;
                  final done = reminder['completedToday'] == true;
                  return ReminderCard(
                    item: reminder,
                    action: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          tooltip: 'Editar',
                          onPressed: () => _showEditor(reminder: reminder),
                          icon: const Icon(Icons.edit_outlined),
                        ),
                        IconButton(
                          tooltip: 'Excluir',
                          onPressed: () => _delete(reminder['id'].toString()),
                          icon: const Icon(Icons.delete_outline),
                        ),
                        IconButton.filledTonal(
                          tooltip: done ? 'Concluído' : 'Concluir',
                          onPressed: done
                              ? null
                              : () => _complete(reminder['id'].toString()),
                          icon: Icon(done ? Icons.check_circle : Icons.check),
                        ),
                      ],
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
        Positioned(
          right: 16,
          bottom: 16,
          child: FloatingActionButton.extended(
            onPressed: () => _showEditor(),
            icon: const Icon(Icons.add),
            label: const Text('Novo lembrete'),
          ),
        ),
      ],
    );
  }
}
