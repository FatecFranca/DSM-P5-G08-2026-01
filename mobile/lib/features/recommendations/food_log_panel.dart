part of '../../main.dart';

class FoodLogPanel extends StatefulWidget {
  const FoodLogPanel({super.key, required this.api});

  final ApiClient api;

  @override
  State<FoodLogPanel> createState() => _FoodLogPanelState();
}

class _FoodLogPanelState extends State<FoodLogPanel> {
  final _input = TextEditingController();
  late Future<List<Map<String, dynamic>>> _future = _load();
  String _entryType = 'food';
  bool _saving = false;

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  Future<List<Map<String, dynamic>>> _load() async {
    final data = await widget.api.get('/food-log/today');
    return ((data['entries'] as List?) ?? [])
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  void _reloadEntries() {
    final next = _load();
    setState(() => _future = next);
  }

  Future<void> _add() async {
    final text = _input.text.trim();
    if (text.length < 2) return;
    setState(() => _saving = true);
    try {
      await widget.api.post('/food-log', {
        'description': text,
        'entryType': _entryType,
      });
      _input.clear();
      _reloadEntries();
    } catch (error) {
      if (!mounted) return;
      _showError(context, error);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _remove(String id) async {
    try {
      await widget.api.delete('/food-log/$id');
      _reloadEntries();
    } catch (error) {
      if (!mounted) return;
      _showError(context, error);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle('O que comi e bebi hoje'),
        Material(
          type: MaterialType.transparency,
          child: Wrap(
            spacing: 8,
            children: [
              FilterChip(
                label: const Text('Comida'),
                selected: _entryType == 'food',
                onSelected: (_) => setState(() => _entryType = 'food'),
              ),
              FilterChip(
                label: const Text('Bebida'),
                selected: _entryType == 'drink',
                onSelected: (_) => setState(() => _entryType = 'drink'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _input,
                decoration: const InputDecoration(
                  hintText: 'Ex: arroz, feijão e salada',
                ),
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _saving ? null : _add(),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              onPressed: _saving ? null : _add,
              icon: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.add),
            ),
          ],
        ),
        const SizedBox(height: 12),
        FutureBuilder<List<Map<String, dynamic>>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Center(child: CircularProgressIndicator()),
              );
            }
            final entries = snapshot.data ?? [];
            if (entries.isEmpty) {
              return const EmptyState(
                text: 'Nenhum registro hoje. Anote o que comeu ou bebeu.',
              );
            }
            return Column(
              children: entries.map((entry) {
                final isDrink = entry['entryType'] == 'drink';
                return Dismissible(
                  key: ValueKey(entry['id']),
                  direction: DismissDirection.endToStart,
                  onDismissed: (_) => _remove(entry['id'].toString()),
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 16),
                    color: Theme.of(context).colorScheme.error,
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      isDrink ? Icons.local_drink_outlined : Icons.restaurant,
                    ),
                    title: Text(entry['description']?.toString() ?? ''),
                    subtitle: Text(isDrink ? 'Bebida' : 'Comida'),
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }
}
