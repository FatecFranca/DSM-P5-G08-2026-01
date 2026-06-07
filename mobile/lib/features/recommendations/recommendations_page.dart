part of '../../main.dart';

class RecommendationsPage extends StatefulWidget {
  const RecommendationsPage({
    super.key,
    required this.api,
    this.refreshSignal = 0,
  });

  final ApiClient api;
  final int refreshSignal;

  @override
  State<RecommendationsPage> createState() => _RecommendationsPageState();
}

class _RecommendationsPageState extends State<RecommendationsPage> {
  late Future<Map<String, dynamic>> _future = _load();

  void _reload() {
    final next = _load();
    setState(() => _future = next);
  }

  @override
  void didUpdateWidget(covariant RecommendationsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.refreshSignal != widget.refreshSignal) {
      _reload();
    }
  }

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

  void _openMealPlan() {
    Navigator.of(context).push(
      vitalisRoute<void>(MealPlanPage(api: widget.api)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DataScaffold(
      future: _future,
      onRefresh: _reload,
      builder: (data) {
        final recommendations = data['recommendations'] as List;
        final meal = data['meal'] as Map<String, dynamic>;
        final routine = data['routine'] as Map<String, dynamic>;
        final mealSource = meal['source']?.toString();

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            InfoPanel(
              icon: Icons.restaurant_menu,
              title: 'Seu cardápio',
              body: mealSource == 'gemini'
                  ? 'Cardápio personalizado com inteligência artificial.'
                  : 'Sugestões de refeições para o seu perfil.',
              actionLabel: 'Ver cardápio completo',
              onAction: _openMealPlan,
            ),
            const SizedBox(height: 16),
            const SectionTitle('Dicas para você'),
            if (recommendations.isEmpty)
              const EmptyState(
                text: 'Responda o questionário para receber dicas personalizadas.',
              ),
            ...recommendations.map(
              (item) => RecommendationCard(item: item as Map<String, dynamic>),
            ),
            const SizedBox(height: 16),
            MealPlanPanel(data: meal['meals']),
            WeeklyRoutinePanel(data: routine['week']),
            const SizedBox(height: 16),
            FoodLogPanel(api: widget.api),
          ],
        );
      },
    );
  }
}
