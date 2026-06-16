part of '../main.dart';

class DataScaffold extends StatelessWidget {
  const DataScaffold({
    super.key,
    required this.future,
    required this.builder,
    required this.onRefresh,
  });

  final Future<Map<String, dynamic>> future;
  final Widget Function(Map<String, dynamic>) builder;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return ConnectionErrorPanel(
            message: friendlyErrorMessage(
              snapshot.error ?? 'Erro desconhecido',
            ),
            onRetry: onRefresh,
          );
        }
        return builder(snapshot.data ?? {});
      },
    );
  }
}

class ProfileSummary extends StatelessWidget {
  const ProfileSummary({
    super.key,
    required this.summary,
    this.latest,
    this.explanation,
  });

  final Map<String, dynamic> summary;
  final Map<String, dynamic>? latest;
  final Map<String, dynamic>? explanation;

  @override
  Widget build(BuildContext context) {
    final classification = latest?['classification'] as Map<String, dynamic>?;
    final confidence =
        (explanation?['confidence'] as num?) ??
        classification?['confidence'] as num?;
    final modelVersion =
        explanation?['modelVersion']?.toString() ??
        classification?['modelVersion']?.toString();
    final fromMl = isMlModel(modelVersion);

    return Stack(
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: panelDecoration(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  ScoreRing(
                    value:
                        ((summary['profileScore'] as num?)?.toDouble() ?? 0) /
                        100,
                    label: '${summary['profileScore'] ?? 0}',
                    size: 70,
                    color: profileColor(summary['profile']?.toString()),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          profileLabel(summary['profile']?.toString()),
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        Text(
                          'Índice de bem-estar',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  Chip(
                    avatar: const Icon(Icons.groups, size: 18),
                    label: Text(
                      summary['clusterLabel']?.toString() ??
                          'Cluster em análise',
                    ),
                  ),
                  if (modelVersion != null && !fromMl)
                    Chip(
                      avatar: const Icon(Icons.rule, size: 18),
                      label: Text(modelLabel(modelVersion)),
                    ),
                  if (confidence != null)
                    Chip(
                      avatar: const Icon(Icons.verified_outlined, size: 18),
                      label: Text(
                        '${(confidence.toDouble() * 100).round()}% confianca',
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
        if (fromMl) const MlMarker(),
      ],
    );
  }
}

class MlMarker extends StatelessWidget {
  const MlMarker({super.key});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 10,
      right: 10,
      child: Tooltip(
        message: 'Gerado por IA',
        child: Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}

class MlStatusPanel extends StatelessWidget {
  const MlStatusPanel({super.key, required this.health});

  final Map<String, dynamic> health;

  @override
  Widget build(BuildContext context) {
    final ml = health['ml'] as Map<String, dynamic>?;
    final available = ml?['available'] == true;
    final color = available
        ? Theme.of(context).colorScheme.primary
        : Theme.of(context).colorScheme.secondary;

    return Stack(
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: panelDecoration(context),
          child: Row(
            children: [
              Icon(available ? Icons.smart_toy : Icons.rule, color: color),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      available ? 'IA conectada' : 'Modo básico ativo',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      available
                          ? 'Suas avaliações usam inteligência artificial.'
                          : 'Tudo funciona, mas a IA está indisponível agora.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (available) const MlMarker(),
      ],
    );
  }
}

class AiExplanationPanel extends StatelessWidget {
  const AiExplanationPanel({super.key, required this.data});

  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    final explanation = data['explanation'] as Map<String, dynamic>;
    final messages = ((explanation['messages'] as List?) ?? [])
        .map((item) => item.toString())
        .toList();
    final factors = ((explanation['factors'] as List?) ?? [])
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
    final geminiSummary = explanation['geminiSummary']?.toString();
    final fromMl = isMlModel(
      data['modelVersion']?.toString() ??
          explanation['modelVersion']?.toString(),
    );

    return Stack(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: panelDecoration(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.auto_awesome,
                    color: Theme.of(context).colorScheme.tertiary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Explicação personalizada',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              if (geminiSummary != null && geminiSummary.isNotEmpty)
                Text(geminiSummary)
              else
                ...messages.take(2).map((message) => Text(message)),
              if (factors.isNotEmpty) ...[
                const SizedBox(height: 12),
                ...factors.take(4).map((factor) => FactorTile(factor: factor)),
              ],
            ],
          ),
        ),
        if (fromMl) const MlMarker(),
      ],
    );
  }
}

class FactorTile extends StatelessWidget {
  const FactorTile({super.key, required this.factor});

  final Map<String, dynamic> factor;

  @override
  Widget build(BuildContext context) {
    final impact = factor['impact']?.toString() ?? 'neutral';
    final color = impactColor(context, impact);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(impactIcon(impact), size: 20, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              factor['detail']?.toString() ??
                  factor['factor']?.toString() ??
                  'Fator analisado',
            ),
          ),
        ],
      ),
    );
  }
}

class ClusterStatsPanel extends StatelessWidget {
  const ClusterStatsPanel({super.key, required this.stats});

  final Map<String, dynamic> stats;

  @override
  Widget build(BuildContext context) {
    final comparison = stats['userComparison'] as Map<String, dynamic>?;
    if (comparison == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: panelDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Comparativo do seu grupo',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          ComparisonRow(
            label: 'Passos',
            item: comparison['dailySteps'],
            suffix: '',
          ),
          ComparisonRow(
            label: 'Sono',
            item: comparison['hoursOfSleep'],
            suffix: 'h',
          ),
          ComparisonRow(
            label: 'Exercício',
            item: comparison['exerciseHoursPerWeek'],
            suffix: 'h/sem',
          ),
          ComparisonRow(label: 'IMC', item: comparison['bmi'], suffix: ''),
        ],
      ),
    );
  }
}

class ComparisonRow extends StatelessWidget {
  const ComparisonRow({
    super.key,
    required this.label,
    required this.item,
    required this.suffix,
  });

  final String label;
  final Object? item;
  final String suffix;

  @override
  Widget build(BuildContext context) {
    final data = item is Map
        ? Map<String, dynamic>.from(item as Map)
        : <String, dynamic>{};
    final yours = data['yours'];
    final avg = data['clusterAvg'];
    if (yours == null || avg == null) return const SizedBox.shrink();

    final muted = Theme.of(context).colorScheme.onSurfaceVariant;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Você: ${formatMetric(yours)}$suffix',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              Text(
                'Grupo: ${formatMetric(avg)}$suffix',
                style: TextStyle(fontSize: 12, color: muted),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class InfoPanel extends StatelessWidget {
  const InfoPanel({
    super.key,
    required this.icon,
    required this.title,
    required this.body,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String body;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: panelDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(icon, size: 34, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    if (body.isNotEmpty) Text(body),
                  ],
                ),
              ),
            ],
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 12),
            FilledButton(onPressed: onAction, child: Text(actionLabel!)),
          ],
        ],
      ),
    );
  }
}

class MetricTile extends StatelessWidget {
  const MetricTile({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: panelDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.tertiary),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          Text(label),
        ],
      ),
    );
  }
}

class RecommendationCard extends StatelessWidget {
  const RecommendationCard({super.key, required this.item});

  final Map<String, dynamic> item;

  @override
  Widget build(BuildContext context) {
    final template = (item['template'] as Map<String, dynamic>?) ?? item;
    return Card(
      child: ListTile(
        leading: const Icon(Icons.check_circle_outline),
        title: Text(template['title']?.toString() ?? 'Recomendação'),
        subtitle: Text(
          template['description']?.toString() ??
              template['category']?.toString() ??
              '',
        ),
      ),
    );
  }
}

class ReminderCard extends StatelessWidget {
  const ReminderCard({super.key, required this.item, this.action, this.onTap});

  final Map<String, dynamic> item;
  final Widget? action;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        onTap: onTap,
        leading: Icon(_reminderIcon(item['type']?.toString())),
        title: Text(item['title']?.toString() ?? 'Lembrete'),
        subtitle: Text(
          '${item['timeOfDay'] ?? ''} ${item['message'] ?? ''}'.trim(),
        ),
        trailing: action,
      ),
    );
  }
}

class PlanPanel extends StatelessWidget {
  const PlanPanel({super.key, required this.title, required this.data});

  final String title;
  final Object? data;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: panelDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(_pretty(data)),
        ],
      ),
    );
  }
}

class MealPlanPanel extends StatelessWidget {
  const MealPlanPanel({super.key, required this.data});

  final Object? data;

  @override
  Widget build(BuildContext context) {
    final meals = mapList(data);
    if (meals.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle('Plano alimentar'),
        ...meals.map((meal) => MealCard(meal: meal)),
        const SizedBox(height: 8),
      ],
    );
  }
}

class MealCard extends StatefulWidget {
  const MealCard({super.key, required this.meal});

  final Map<String, dynamic> meal;

  @override
  State<MealCard> createState() => _MealCardState();
}

class _MealCardState extends State<MealCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final meal = widget.meal;
    final type = meal['mealType']?.toString() ?? 'meal';
    final color = _mealColor(context, type);

    return Pressable(
      onTap: () => setState(() => _expanded = !_expanded),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: panelDecoration(context),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(height: 5, color: color),
              Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(_mealIcon(type), color: color),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            mealLabel(type),
                            style: Theme.of(context).textTheme.labelLarge
                                ?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                ),
                          ),
                          Text(
                            meal['title']?.toString() ?? 'Refeição',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      _expanded
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                    ),
                  ],
                ),
              ),
              AnimatedCrossFade(
                firstChild: const SizedBox.shrink(),
                secondChild: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_mealItems(meal).isNotEmpty) ...[
                        Text(
                          'Alimentos',
                          style: Theme.of(context).textTheme.labelLarge,
                        ),
                        const SizedBox(height: 6),
                        ..._mealItems(meal).map(
                          (entry) => Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('• '),
                                Expanded(
                                  child: Text(
                                    '${entry['name']} — ${entry['quantity']}',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                      Text(meal['description']?.toString() ?? ''),
                      if (meal['tip'] != null) ...[
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Theme.of(
                              context,
                            ).colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.lightbulb_outline,
                                size: 18,
                                color: Theme.of(context).colorScheme.secondary,
                              ),
                              const SizedBox(width: 8),
                              Expanded(child: Text(meal['tip'].toString())),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                crossFadeState: _expanded
                    ? CrossFadeState.showSecond
                    : CrossFadeState.showFirst,
                duration: const Duration(milliseconds: 220),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class WeeklyRoutinePanel extends StatefulWidget {
  const WeeklyRoutinePanel({super.key, required this.data});

  final Object? data;

  @override
  State<WeeklyRoutinePanel> createState() => _WeeklyRoutinePanelState();
}

class _WeeklyRoutinePanelState extends State<WeeklyRoutinePanel> {
  int _selected = 0;

  @override
  Widget build(BuildContext context) {
    final days = mapList(widget.data);
    if (days.isEmpty) return const SizedBox.shrink();
    final day = days[_selected.clamp(0, days.length - 1)];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 4),
        const SectionTitle('Rotina semanal'),
        SizedBox(
          height: 64,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: days.length,
            separatorBuilder: (context, index) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final selected = index == _selected;
              final label = days[index]['day']?.toString() ?? 'Dia';
              return Pressable(
                onTap: () => setState(() => _selected = index),
                child: Container(
                  width: 58,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: selected
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.outlineVariant,
                    ),
                  ),
                  child: Text(
                    label.substring(
                      0,
                      label.length >= 3 ? 3 : label.length,
                    ),
                    style: TextStyle(
                      color: selected
                          ? Colors.white
                          : Theme.of(context).colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        DayRoutineCard(day: day),
      ],
    );
  }
}

class DayRoutineCard extends StatelessWidget {
  const DayRoutineCard({super.key, required this.day});

  final Map<String, dynamic> day;

  @override
  Widget build(BuildContext context) {
    final dayName = day['day']?.toString() ?? 'Dia';
    final focus = day['focus']?.toString() ?? 'Rotina';
    final activities = ((day['activities'] as List?) ?? [])
        .map((item) => item.toString())
        .toList();
    final color = _dayColor(context, dayName);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: panelDecoration(context),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              color: color.withValues(alpha: 0.14),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(_focusIcon(focus), color: color),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          dayName,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        Text(
                          focus,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                        ),
                      ],
                    ),
                  ),
                  Badge(label: Text('${activities.length}')),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
              child: Column(
                children: activities
                    .map(
                      (activity) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.check_circle_outline,
                              size: 19,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            const SizedBox(width: 10),
                            Expanded(child: Text(activity)),
                          ],
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.text, {super.key, this.trailing, this.action});

  final String text;
  final String? trailing;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              text,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
          ),
          if (trailing != null) Badge(label: Text(trailing!)),
          if (action != null) ...[const SizedBox(width: 8), action!],
        ],
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 18),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodyMedium,
      ),
    );
  }
}

class Pressable extends StatefulWidget {
  const Pressable({super.key, required this.child, this.onTap});

  final Widget child;
  final VoidCallback? onTap;

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOutCubic,
        child: widget.child,
      ),
    );
  }
}

class StepBars extends StatelessWidget {
  const StepBars({super.key, required this.current, required this.total});

  final int current;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(total, (index) {
        final active = index <= current;
        return Expanded(
          child: Container(
            height: 5,
            margin: const EdgeInsets.symmetric(horizontal: 3),
            decoration: BoxDecoration(
              color: active
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
        );
      }),
    );
  }
}

class ScoreRing extends StatelessWidget {
  const ScoreRing({
    super.key,
    required this.value,
    required this.label,
    required this.color,
    this.size = 132,
  });

  final double value;
  final String label;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value.clamp(0, 1)),
      duration: const Duration(milliseconds: 1100),
      curve: Curves.easeOutCubic,
      builder: (context, animated, _) {
        return SizedBox(
          width: size,
          height: size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CustomPaint(
                size: Size.square(size),
                painter: ScoreRingPainter(
                  value: animated,
                  color: color,
                  trackColor: Theme.of(
                    context,
                  ).colorScheme.surfaceContainerHighest,
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: monoStyle(
                      context,
                      fontSize: size * 0.26,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  if (size > 90)
                    Text(
                      'de 100',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class ScoreRingPainter extends CustomPainter {
  ScoreRingPainter({
    required this.value,
    required this.color,
    required this.trackColor,
  });

  final double value;
  final Color color;
  final Color trackColor;

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = size.width * 0.08;
    final rect = Offset.zero & size;
    final inset = stroke / 2;
    final arcRect = rect.deflate(inset);
    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..color = trackColor;
    final progress = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..color = color;
    canvas.drawArc(arcRect, -1.5708, 6.283, false, track);
    canvas.drawArc(arcRect, -1.5708, 6.283 * value, false, progress);
  }

  @override
  bool shouldRepaint(covariant ScoreRingPainter oldDelegate) {
    return oldDelegate.value != value ||
        oldDelegate.color != color ||
        oldDelegate.trackColor != trackColor;
  }
}

class QuestionStep extends StatelessWidget {
  const QuestionStep({
    super.key,
    required this.title,
    required this.subtitle,
    required this.children,
  });

  final String title;
  final String subtitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: key,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 22),
        ...children,
      ],
    );
  }
}

class VitalisSlider extends StatelessWidget {
  const VitalisSlider({
    super.key,
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    this.suffix = '',
    this.display,
    this.step = 1,
    this.accent,
    this.errorText,
  });

  final String label;
  final double? value;
  final double min;
  final double max;
  final String suffix;
  final String? display;
  final double step;
  final Color? accent;
  final ValueChanged<double> onChanged;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    final color = accent ?? Theme.of(context).colorScheme.primary;
    final divisions = ((max - min) / step).round();
    final hasValue = value != null;
    final shownValue = value ?? min;
    return Padding(
      padding: const EdgeInsets.only(bottom: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  display ??
                      (hasValue
                          ? '${formatMetric(value!)}$suffix'
                          : 'Informe'),
                  style: monoStyle(
                    context,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ).copyWith(
                    color: hasValue
                        ? null
                        : Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.end,
                ),
              ),
            ],
          ),
          Material(
            type: MaterialType.transparency,
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: color,
                inactiveTrackColor: color.withValues(alpha: 0.08),
                thumbColor: Colors.white,
                overlayColor: color.withValues(alpha: 0.12),
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 11),
                trackHeight: 6,
              ),
              child: Slider(
                value: shownValue.clamp(min, max),
                min: min,
                max: max,
                divisions: divisions > 0 ? divisions : null,
                onChanged: onChanged,
              ),
            ),
          ),
          if (errorText != null) ...[
            const SizedBox(height: 4),
            Text(
              errorText!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.error,
              ),
            ),
          ],
          Row(
            children: [
              Text(
                '${formatMetric(min)}$suffix',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const Spacer(),
              Text(
                '${formatMetric(max)}$suffix',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class StepperField extends StatelessWidget {
  const StepperField({
    super.key,
    required this.label,
    required this.value,
    required this.suffix,
    required this.min,
    required this.max,
    required this.onChanged,
    this.errorText,
  });

  final String label;
  final int? value;
  final String suffix;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    final hasValue = value != null;
    final shownValue = value ?? min;
    return Padding(
      padding: const EdgeInsets.only(bottom: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Material(
            type: MaterialType.transparency,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: panelDecoration(context),
              child: Row(
                children: [
                  IconButton.filledTonal(
                    onPressed: !hasValue || shownValue <= min
                        ? null
                        : () => onChanged(shownValue - 1),
                    icon: const Icon(Icons.remove),
                  ),
                  Expanded(
                    child: Text(
                      hasValue ? '$shownValue $suffix' : 'Informe',
                      textAlign: TextAlign.center,
                      style: monoStyle(
                        context,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ).copyWith(
                        color: hasValue
                            ? null
                            : Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  IconButton.filledTonal(
                    onPressed: !hasValue
                        ? () => onChanged(min)
                        : shownValue >= max
                        ? null
                        : () => onChanged(shownValue + 1),
                    icon: const Icon(Icons.add),
                  ),
                ],
              ),
            ),
          ),
          if (errorText != null) ...[
            const SizedBox(height: 4),
            Text(
              errorText!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.error,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class ToggleRow extends StatelessWidget {
  const ToggleRow({
    super.key,
    required this.label,
    required this.icon,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final IconData icon;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: panelDecoration(context),
        child: Row(
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            Switch(value: value, onChanged: onChanged),
          ],
        ),
      ),
    );
  }
}

class DisclaimerBox extends StatelessWidget {
  const DisclaimerBox({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant,
          style: BorderStyle.solid,
        ),
        color: Theme.of(
          context,
        ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text, style: Theme.of(context).textTheme.bodySmall),
          ),
        ],
      ),
    );
  }
}

class Field extends StatelessWidget {
  const Field({
    super.key,
    required this.controller,
    required this.label,
    required this.min,
    required this.max,
    this.optional = false,
  });

  final TextEditingController controller;
  final String label;
  final num min;
  final num max;
  final bool optional;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(labelText: label),
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        validator: (value) {
          if (optional && (value == null || value.trim().isEmpty)) {
            return null;
          }
          final number = num.tryParse((value ?? '').replaceAll(',', '.'));
          if (number == null) return 'Informe um numero';
          if (number < min || number > max) {
            return 'Use um valor entre $min e $max';
          }
          return null;
        },
      ),
    );
  }
}

class ChoiceField extends StatelessWidget {
  const ChoiceField({
    super.key,
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
    this.errorText,
  });

  final String label;
  final String? value;
  final Map<String, String> options;
  final ValueChanged<String> onChanged;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 8),
          Material(
            type: MaterialType.transparency,
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: options.entries.map((entry) {
                final selected = value == entry.key;
                return FilterChip(
                  label: Text(entry.value),
                  selected: selected,
                  showCheckmark: true,
                  selectedColor: colorScheme.primaryContainer,
                  checkmarkColor: colorScheme.onPrimaryContainer,
                  onSelected: (_) => onChanged(entry.key),
                );
              }).toList(),
            ),
          ),
          if (errorText != null) ...[
            const SizedBox(height: 4),
            Text(
              errorText!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colorScheme.error,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

BoxDecoration panelDecoration(BuildContext context) {
  return BoxDecoration(
    color: Theme.of(context).colorScheme.surface,
    borderRadius: BorderRadius.circular(8),
    border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
  );
}

IconData _reminderIcon(String? type) {
  return switch (type) {
    'WATER' => Icons.water_drop,
    'MEAL' => Icons.restaurant,
    'SLEEP' => Icons.bedtime,
    'EXERCISE' => Icons.directions_run,
    _ => Icons.notifications,
  };
}
