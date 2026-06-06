part of '../../main.dart';

class RecommendationsPage extends StatefulWidget {
  const RecommendationsPage({super.key, required this.api});

  final ApiClient api;

  @override
  State<RecommendationsPage> createState() => _RecommendationsPageState();
}

class _RecommendationsPageState extends State<RecommendationsPage> {
  late Future<Map<String, dynamic>> _future = _load();

  Future<Map<String, dynamic>> _load() async {
    final results = await Future.wait([
      widget.api.get('/recommendations'),
      widget.api
          .get('/recommendations/meal-plan')
          .catchError((_) => <String, dynamic>{}),
      widget.api
          .get('/recommendations/weekly-routine')
          .catchError((_) => <String, dynamic>{}),
    ]);
    return {
      'recommendations': results[0]['recommendations'] ?? [],
      'meal': results[1],
      'routine': results[2],
    };
  }

  @override
  Widget build(BuildContext context) {
    return DataScaffold(
      future: _future,
      onRefresh: () => setState(() => _future = _load()),
      builder: (data) {
        final recommendations = data['recommendations'] as List;
        final meal = data['meal'] as Map<String, dynamic>;
        final routine = data['routine'] as Map<String, dynamic>;

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const SectionTitle('Recomendacoes'),
            if (recommendations.isEmpty)
              const EmptyState(
                text: 'Preencha uma avaliacao para receber recomendacoes.',
              ),
            ...recommendations.map(
              (item) => RecommendationCard(item: item as Map<String, dynamic>),
            ),
            const SizedBox(height: 16),
            MealPlanPanel(data: meal['meals']),
            WeeklyRoutinePanel(data: routine['week']),
          ],
        );
      },
    );
  }
}
