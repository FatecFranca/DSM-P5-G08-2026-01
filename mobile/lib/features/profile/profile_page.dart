part of '../../main.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({
    super.key,
    required this.session,
    required this.api,
    this.refreshSignal = 0,
  });

  final SessionStore session;
  final ApiClient api;
  final int refreshSignal;

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late Future<Map<String, dynamic>> _future = _load();

  void _reload() {
    final next = _load();
    setState(() => _future = next);
  }

  @override
  void didUpdateWidget(covariant ProfilePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.refreshSignal != widget.refreshSignal) {
      _reload();
    }
  }

  Future<Map<String, dynamic>> _load() async {
    final results = await Future.wait([
      widget.api.get('/gamification').catchError((_) => <String, dynamic>{}),
      widget.api
          .get('/gamification/achievements')
          .catchError((_) => <String, dynamic>{}),
    ]);
    return {'game': results[0], 'achievements': results[1]};
  }

  @override
  Widget build(BuildContext context) {
    return DataScaffold(
      future: _future,
      onRefresh: _reload,
      builder: (data) {
        final game = data['game'] as Map<String, dynamic>;
        final gamification =
            (game['gamification'] as Map<String, dynamic>?) ?? {};
        final achievements =
            ((data['achievements'] as Map<String, dynamic>)['achievements']
                as List?) ??
            [];

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            InfoPanel(
              icon: Icons.person,
              title:
                  widget.session.user?['name']?.toString() ?? 'Usuario Vitalis',
              body: widget.session.user?['email']?.toString() ?? '',
            ),
            const SizedBox(height: 12),
            Material(
              type: MaterialType.transparency,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: panelDecoration(context),
                child: Row(
                  children: [
                    const Icon(Icons.dark_mode_outlined),
                    const SizedBox(width: 12),
                    const Expanded(child: Text('Tema escuro')),
                    ValueListenableBuilder<ThemeMode>(
                      valueListenable: appThemeMode,
                      builder: (context, mode, _) {
                        return Switch(
                          value: mode == ThemeMode.dark,
                          onChanged: (enabled) {
                            appThemeMode.value = enabled
                                ? ThemeMode.dark
                                : ThemeMode.light;
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: MetricTile(
                    label: 'Pontos',
                    value: '${gamification['points'] ?? 0}',
                    icon: Icons.stars,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: MetricTile(
                    label: 'Sequência',
                    value: '${gamification['currentStreak'] ?? 0}',
                    icon: Icons.local_fire_department,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const SectionTitle('Conquistas'),
            if (achievements.isEmpty)
              const EmptyState(
                text:
                    'Conclua avaliações e lembretes para desbloquear conquistas.',
              ),
            ...achievements.map((item) {
              final achievement = item as Map<String, dynamic>;
              return ListTile(
                leading: const Icon(Icons.workspace_premium),
                title: Text(
                  achievement['title']?.toString() ??
                      achievement['key']?.toString() ??
                      'Conquista',
                ),
                subtitle: Text(achievement['description']?.toString() ?? ''),
              );
            }),
          ],
        );
      },
    );
  }
}
