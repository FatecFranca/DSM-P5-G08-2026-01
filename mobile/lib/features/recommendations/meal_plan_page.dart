part of '../../main.dart';

class MealPlanPage extends StatefulWidget {
  const MealPlanPage({super.key, required this.api});

  final ApiClient api;

  @override
  State<MealPlanPage> createState() => _MealPlanPageState();
}

class _MealPlanPageState extends State<MealPlanPage> {
  late Future<Map<String, dynamic>> _future = _load();

  Future<Map<String, dynamic>> _load() => widget.api.get('/recommendations/meal-plan');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Seu cardápio')),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return ConnectionErrorPanel(
              message: friendlyErrorMessage(snapshot.error ?? 'Erro'),
              onRetry: () => setState(() => _future = _load()),
            );
          }
          final data = snapshot.data ?? {};
          final meals = mapList(data['meals']);
          final source = data['source']?.toString() ?? 'static';
          final profile = profileLabel(data['profile']?.toString());

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              InfoPanel(
                icon: Icons.restaurant_menu,
                title: 'Cardápio do dia',
                body: source == 'gemini'
                    ? 'Sugestões personalizadas para o perfil $profile, feitas com inteligência artificial.'
                    : 'Sugestões gerais para o perfil $profile.',
              ),
              const SizedBox(height: 8),
              if (meals.isEmpty)
                const EmptyState(
                  text: 'Faça uma avaliação para receber seu cardápio.',
                ),
              ...meals.map((meal) => MealCard(meal: meal)),
              const SizedBox(height: 12),
              const DisclaimerBox(
                text:
                    'Sugestões de alimentação saudável. Não substituem orientação de nutricionista ou médico.',
              ),
            ],
          );
        },
      ),
    );
  }
}
