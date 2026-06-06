part of '../../main.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({
    super.key,
    required this.api,
    required this.onStartAssessment,
  });

  final ApiClient api;
  final VoidCallback onStartAssessment;

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  late Future<Map<String, dynamic>> _future = _load();

  Future<Map<String, dynamic>> _load() async {
    final dashboard = await widget.api.get('/dashboard');
    final health = await widget.api
        .get('/health/ready')
        .catchError((_) => <String, dynamic>{});
    final latest = await widget.api
        .get('/assessments/latest')
        .catchError((_) => <String, dynamic>{});
    final clusterStats = await widget.api
        .get('/clusters/me/stats')
        .catchError((_) => <String, dynamic>{});
    final assessment = latest['assessment'] as Map<String, dynamic>?;
    final assessmentId = assessment?['id']?.toString();
    final explanation = assessmentId == null
        ? <String, dynamic>{}
        : await widget.api
              .get('/assessments/$assessmentId/explanation')
              .catchError((_) => <String, dynamic>{});

    return {
      ...dashboard,
      'health': health,
      'latest': assessment,
      'explanationDetails': explanation,
      'clusterStats': clusterStats['stats'],
    };
  }

  @override
  Widget build(BuildContext context) {
    return DataScaffold(
      future: _future,
      onRefresh: () => setState(() => _future = _load()),
      builder: (data) {
        final dashboard = data['dashboard'] as Map<String, dynamic>;
        final summary = dashboard['summary'] as Map<String, dynamic>?;
        final gamification = dashboard['gamification'] as Map<String, dynamic>?;
        final reminders = (dashboard['remindersToday'] as List?) ?? [];
        final recommendations = (dashboard['recommendations'] as List?) ?? [];
        final health = data['health'] as Map<String, dynamic>;
        final latest = data['latest'] as Map<String, dynamic>?;
        final explanationDetails =
            data['explanationDetails'] as Map<String, dynamic>;
        final clusterStats = data['clusterStats'] as Map<String, dynamic>?;

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            MlStatusPanel(health: health),
            const SizedBox(height: 12),
            if (summary == null)
              InfoPanel(
                icon: Icons.assignment_add,
                title: 'Faça sua primeira avaliação',
                body:
                    'Preencha o questionário para gerar perfil, recomendações e lembretes.',
                actionLabel: 'Começar avaliação',
                onAction: widget.onStartAssessment,
              )
            else
              ProfileSummary(
                summary: summary,
                latest: latest,
                explanation: explanationDetails,
              ),
            if (explanationDetails['explanation'] != null) ...[
              const SizedBox(height: 12),
              AiExplanationPanel(data: explanationDetails),
            ],
            if (clusterStats != null) ...[
              const SizedBox(height: 12),
              ClusterStatsPanel(stats: clusterStats),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: MetricTile(
                    label: 'Pontos',
                    value: '${gamification?['points'] ?? 0}',
                    icon: Icons.stars,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: MetricTile(
                    label: 'Nivel',
                    value: '${gamification?['level'] ?? 1}',
                    icon: Icons.trending_up,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SectionTitle('Lembretes de hoje', trailing: '${reminders.length}'),
            ...reminders
                .take(4)
                .map(
                  (item) => ReminderCard(item: item as Map<String, dynamic>),
                ),
            if (reminders.isEmpty)
              const EmptyState(text: 'Nenhum lembrete ativo para hoje.'),
            const SizedBox(height: 16),
            SectionTitle(
              'Recomendacoes ativas',
              trailing: '${recommendations.length}',
            ),
            ...recommendations
                .take(4)
                .map(
                  (item) =>
                      RecommendationCard(item: item as Map<String, dynamic>),
                ),
            if (recommendations.isEmpty)
              const EmptyState(
                text: 'As recomendacoes aparecem depois da avaliacao.',
              ),
          ],
        );
      },
    );
  }
}
