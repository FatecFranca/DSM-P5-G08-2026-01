part of '../main.dart';

String profileLabel(String? profile) {
  return switch (profile) {
    'Saudavel_Ativo' => 'Saudavel ativo',
    'Moderado' => 'Moderado',
    'Sedentario' => 'Sedentario',
    'Em_Risco' => 'Em risco',
    _ => 'Perfil em analise',
  };
}

Color profileColor(String? profile) {
  return switch (profile) {
    'Saudavel_Ativo' => const Color(0xFF22C55E),
    'Moderado' => const Color(0xFFF59E0B),
    'Sedentario' => const Color(0xFFF97316),
    'Em_Risco' => const Color(0xFFEF4444),
    _ => teal600,
  };
}

String modelLabel(String modelVersion) {
  if (modelVersion.toLowerCase().startsWith('ml')) {
    return 'Modelo IA $modelVersion';
  }
  if (modelVersion == 'rules-v1') return 'Regras locais';
  return modelVersion;
}

bool isMlModel(String? modelVersion) {
  return modelVersion != null && modelVersion.toLowerCase().startsWith('ml');
}

Color impactColor(BuildContext context, String impact) {
  return switch (impact) {
    'positive' => Theme.of(context).colorScheme.primary,
    'negative' => Theme.of(context).colorScheme.error,
    _ => Theme.of(context).colorScheme.secondary,
  };
}

IconData impactIcon(String impact) {
  return switch (impact) {
    'positive' => Icons.trending_up,
    'negative' => Icons.warning_amber,
    _ => Icons.remove_circle_outline,
  };
}

String formatMetric(Object? value) {
  if (value is num) {
    final rounded = value.toDouble();
    if (rounded == rounded.roundToDouble()) return rounded.round().toString();
    return rounded.toStringAsFixed(1);
  }
  return value?.toString() ?? '-';
}

TextStyle monoStyle(
  BuildContext context, {
  double? fontSize,
  FontWeight? fontWeight,
  Color? color,
}) {
  return GoogleFonts.jetBrainsMono(
    fontSize: fontSize,
    fontWeight: fontWeight,
    color: color ?? Theme.of(context).colorScheme.onSurface,
  );
}

String compactSteps(int value) {
  if (value >= 1000) {
    final k = value / 1000;
    return '${k.toStringAsFixed(k == k.roundToDouble() ? 0 : 1)}k';
  }
  return value.toString();
}

List<Map<String, dynamic>> mapList(Object? value) {
  if (value is List) {
    return value
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }
  if (value is Map) {
    return value.values
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }
  return const [];
}

String mealLabel(String type) {
  return switch (type) {
    'breakfast' => 'Cafe da manha',
    'lunch' => 'Almoco',
    'dinner' => 'Jantar',
    'snack' => 'Lanche',
    _ => 'Refeicao',
  };
}

IconData _mealIcon(String type) {
  return switch (type) {
    'breakfast' => Icons.free_breakfast,
    'lunch' => Icons.lunch_dining,
    'dinner' => Icons.dinner_dining,
    'snack' => Icons.local_cafe,
    _ => Icons.restaurant,
  };
}

Color _mealColor(BuildContext context, String type) {
  final scheme = Theme.of(context).colorScheme;
  return switch (type) {
    'breakfast' => const Color(0xFFE0962D),
    'lunch' => scheme.primary,
    'dinner' => scheme.tertiary,
    'snack' => const Color(0xFFB05A8C),
    _ => scheme.secondary,
  };
}

IconData _focusIcon(String focus) {
  final value = focus.toLowerCase();
  if (value.contains('forca') || value.contains('treino')) {
    return Icons.fitness_center;
  }
  if (value.contains('cardio') ||
      value.contains('caminhada') ||
      value.contains('movimento')) {
    return Icons.directions_walk;
  }
  if (value.contains('alimentacao') || value.contains('nutricional')) {
    return Icons.restaurant;
  }
  if (value.contains('sono') ||
      value.contains('descanso') ||
      value.contains('recuperacao')) {
    return Icons.bedtime;
  }
  if (value.contains('planejamento') || value.contains('rotina')) {
    return Icons.event_note;
  }
  if (value.contains('hidratacao')) return Icons.water_drop;
  return Icons.spa;
}

Color _dayColor(BuildContext context, String dayName) {
  final scheme = Theme.of(context).colorScheme;
  return switch (dayName.toLowerCase()) {
    'segunda' => scheme.primary,
    'terca' || 'terça' => scheme.tertiary,
    'quarta' => scheme.secondary,
    'quinta' => const Color(0xFF2F8C7D),
    'sexta' => const Color(0xFF7A6AC7),
    'sabado' || 'sábado' => const Color(0xFFB05A2A),
    'domingo' => const Color(0xFF58708F),
    _ => scheme.primary,
  };
}

String _pretty(Object? value) {
  if (value is Map) {
    return value.entries
        .map((entry) => '${entry.key}: ${_pretty(entry.value)}')
        .join('\n');
  }
  if (value is List) return value.map(_pretty).join('\n');
  return value?.toString() ?? '';
}

String _fallbackMessage(int statusCode) {
  return switch (statusCode) {
    400 => 'Dados invalidos',
    401 => 'E-mail ou senha incorretos',
    403 => 'Voce nao tem permissao para esta acao',
    404 => 'Registro nao encontrado',
    409 => 'Ja existe um cadastro com esses dados',
    500 => 'Erro interno do servidor',
    _ => 'Erro $statusCode',
  };
}

String? _detailsMessage(Object? details) {
  if (details == null) return null;
  if (details is String && details.trim().isNotEmpty) return details;
  if (details is List) {
    final values = details
        .map((item) => item.toString())
        .where((item) => item.trim().isNotEmpty)
        .toList();
    return values.isEmpty ? null : values.join(', ');
  }
  if (details is Map) {
    final messages = <String>[];
    details.forEach((key, value) {
      if (value is List && value.isNotEmpty) {
        messages.add('${_fieldLabel(key.toString())}: ${value.join(', ')}');
      } else if (value != null && value.toString().trim().isNotEmpty) {
        messages.add('${_fieldLabel(key.toString())}: $value');
      }
    });
    return messages.isEmpty ? null : messages.join('\n');
  }
  return details.toString();
}

String _fieldLabel(String field) {
  return switch (field) {
    'name' => 'Nome',
    'email' => 'E-mail',
    'password' => 'Senha',
    'currentPassword' => 'Senha atual',
    'newPassword' => 'Nova senha',
    _ => field,
  };
}

Object _authErrorMessage(Object error, {required bool isRegister}) {
  if (error is! ApiException) return error;
  if (!isRegister && error.statusCode == 401) {
    return ApiException(
      'E-mail ou senha incorretos. Confira os dados e tente novamente.',
    );
  }
  if (isRegister && error.statusCode == 409) {
    return ApiException(
      'Este e-mail ja esta cadastrado. Entre com sua conta ou use outro e-mail.',
    );
  }
  if (error.statusCode == 400) {
    return ApiException(
      error.message.replaceFirst('Dados invalidos: ', 'Verifique os campos:\n'),
    );
  }
  return error;
}

void _showResult(BuildContext context, Map<String, dynamic> result) {
  final plan = result['plan'] as Map<String, dynamic>?;
  final classification = result['classification'] as Map<String, dynamic>?;
  final explanation = result['explanation'] as Map<String, dynamic>?;
  final messages = ((explanation?['messages'] as List?) ?? [])
      .map((item) => item.toString())
      .toList();
  final confidence = classification?['confidence'] as num?;
  final modelVersion =
      classification?['modelVersion']?.toString() ??
      explanation?['modelVersion']?.toString();

  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (context) => Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text('Seu perfil', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 10),
            ScoreRing(
              value: ((plan?['profileScore'] as num?)?.toDouble() ?? 0) / 100,
              label: '${plan?['profileScore'] ?? '-'}',
              color: profileColor(plan?['profile']?.toString()),
            ),
            const SizedBox(height: 12),
            Text(
              profileLabel(plan?['profile']?.toString()),
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            Chip(
              label: Text('Cluster: ${plan?['clusterLabel'] ?? 'em analise'}'),
            ),
            if (modelVersion != null) Text(modelLabel(modelVersion)),
            if (confidence != null)
              Text('Confianca: ${(confidence.toDouble() * 100).round()}%'),
            if (messages.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(messages.first),
            ],
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.arrow_forward),
              label: const Text('Ver meu plano personalizado'),
            ),
          ],
        ),
      ),
    ),
  );
}

void _showError(BuildContext context, Object error) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      behavior: SnackBarBehavior.floating,
      showCloseIcon: true,
      content: Text(error is ApiException ? error.message : error.toString()),
    ),
  );
}

void _showPointsToast(BuildContext context, int points) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      behavior: SnackBarBehavior.floating,
      backgroundColor: const Color(0xFF0E1A24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      content: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_circle, color: teal400),
          const SizedBox(width: 10),
          const Text('Lembrete concluido'),
          if (points > 0) ...[
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFF59E0B).withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                '+$points pts',
                style: const TextStyle(
                  color: Color(0xFFF59E0B),
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ],
      ),
    ),
  );
}
