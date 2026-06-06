part of '../../main.dart';

class AssessmentPage extends StatefulWidget {
  const AssessmentPage({super.key, required this.api, required this.onDone});

  final ApiClient api;
  final VoidCallback onDone;

  @override
  State<AssessmentPage> createState() => _AssessmentPageState();
}

class _AssessmentPageState extends State<AssessmentPage> {
  final _form = GlobalKey<FormState>();
  final Map<String, TextEditingController> _controllers = {
    'heartRate': TextEditingController(text: '80'),
    'bloodPressureSystolic': TextEditingController(),
    'bloodPressureDiastolic': TextEditingController(),
  };
  int _step = 0;
  int _age = 29;
  double _heightCm = 165;
  double _weightKg = 72;
  int _dailySteps = 8000;
  double _exerciseHoursPerWeek = 2;
  int _caloriesIntake = 2100;
  int _alcoholPerWeek = 3;
  double _hoursOfSleep = 6;
  int _heartRate = 72;
  String _gender = 'Male';
  String _smoker = 'No';
  String _diabetic = 'No';
  String _heartDisease = 'No';
  bool _loading = false;

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final body = {
        'age': _age,
        'gender': _gender,
        'heightCm': _heightCm,
        'weightKg': _weightKg,
        'dailySteps': _dailySteps,
        'caloriesIntake': _caloriesIntake,
        'hoursOfSleep': _hoursOfSleep,
        'heartRate': _heartRate,
        if (_controllers['bloodPressureSystolic']!.text.trim().isNotEmpty)
          'bloodPressureSystolic': _int('bloodPressureSystolic'),
        if (_controllers['bloodPressureDiastolic']!.text.trim().isNotEmpty)
          'bloodPressureDiastolic': _int('bloodPressureDiastolic'),
        'exerciseHoursPerWeek': _exerciseHoursPerWeek,
        'smoker': _smoker,
        'alcoholPerWeek': _alcoholPerWeek,
        'diabetic': _diabetic,
        'heartDisease': _heartDisease,
      };
      final result = await widget.api.post('/assessments', body);
      if (!mounted) return;
      _showResult(context, result);
      widget.onDone();
    } catch (error) {
      _showError(context, error);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  int _int(String key) =>
      int.parse(_controllers[key]!.text.replaceAll(',', '.'));

  void _nextStep() {
    if (_step < 3) {
      setState(() => _step += 1);
    } else {
      _submit();
    }
  }

  void _previousStep() {
    if (_step > 0) setState(() => _step -= 1);
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _form,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Row(
              children: [
                IconButton(
                  tooltip: 'Voltar',
                  onPressed: _step == 0 ? null : _previousStep,
                  icon: const Icon(Icons.arrow_back),
                ),
                Expanded(child: StepBars(current: _step, total: 4)),
                const SizedBox(width: 12),
                Text(
                  '${_step + 1}/4',
                  style: monoStyle(context, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 96),
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 260),
                  child: _stepContent(context),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 18),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              border: Border(
                top: BorderSide(
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
              ),
            ),
            child: Pressable(
              child: FilledButton.icon(
                onPressed: _loading ? null : _nextStep,
                icon: _loading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(
                        _step == 3 ? Icons.psychology_alt : Icons.arrow_forward,
                      ),
                label: Text(_step == 3 ? 'Analisar meu perfil' : 'Continuar'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _stepContent(BuildContext context) {
    return switch (_step) {
      0 => QuestionStep(
        key: const ValueKey('personal'),
        title: 'Sobre você',
        subtitle: 'Dados básicos para calibrar a análise.',
        children: [
          VitalisSlider(
            label: 'Idade',
            value: _age.toDouble(),
            min: 18,
            max: 90,
            suffix: ' anos',
            onChanged: (value) => setState(() => _age = value.round()),
          ),
          ChoiceField(
            label: 'Sexo biológico',
            value: _gender,
            options: const {'Female': 'Feminino', 'Male': 'Masculino'},
            onChanged: (value) => setState(() => _gender = value),
          ),
          VitalisSlider(
            label: 'Altura',
            value: _heightCm,
            min: 140,
            max: 210,
            suffix: ' cm',
            onChanged: (value) =>
                setState(() => _heightCm = value.roundToDouble()),
          ),
          VitalisSlider(
            label: 'Peso',
            value: _weightKg,
            min: 40,
            max: 160,
            suffix: ' kg',
            onChanged: (value) =>
                setState(() => _weightKg = value.roundToDouble()),
          ),
        ],
      ),
      1 => QuestionStep(
        key: const ValueKey('activity'),
        title: 'Atividade física',
        subtitle: 'Como é seu movimento no dia a dia.',
        children: [
          VitalisSlider(
            label: 'Passos diários',
            value: _dailySteps.toDouble(),
            min: 1000,
            max: 20000,
            step: 500,
            display: compactSteps(_dailySteps),
            onChanged: (value) =>
                setState(() => _dailySteps = (value / 500).round() * 500),
          ),
          VitalisSlider(
            label: 'Exercício estruturado por semana',
            value: _exerciseHoursPerWeek,
            min: 0,
            max: 14,
            suffix: 'h',
            onChanged: (value) =>
                setState(() => _exerciseHoursPerWeek = value.roundToDouble()),
          ),
          ChoiceField(
            label: 'Nível de atividade no trabalho',
            value: _exerciseHoursPerWeek >= 5
                ? 'active'
                : _exerciseHoursPerWeek >= 2
                ? 'mixed'
                : 'sitting',
            options: const {
              'sitting': 'Sentado',
              'mixed': 'Misto',
              'active': 'Ativo',
            },
            onChanged: (value) => setState(() {
              if (value == 'active') _exerciseHoursPerWeek = 5;
              if (value == 'mixed') _exerciseHoursPerWeek = 2;
              if (value == 'sitting') _exerciseHoursPerWeek = 0;
            }),
          ),
        ],
      ),
      2 => QuestionStep(
        key: const ValueKey('food-sleep'),
        title: 'Alimentação & sono',
        subtitle: 'Seus hábitos de consumo e descanso.',
        children: [
          VitalisSlider(
            label: 'Calorias por dia',
            value: _caloriesIntake.toDouble(),
            min: 1200,
            max: 4000,
            step: 100,
            suffix: ' kcal',
            accent: const Color(0xFFF59E0B),
            onChanged: (value) =>
                setState(() => _caloriesIntake = (value / 100).round() * 100),
          ),
          StepperField(
            label: 'Doses de álcool por semana',
            value: _alcoholPerWeek,
            suffix: _alcoholPerWeek == 1 ? 'dose' : 'doses',
            min: 0,
            max: 30,
            onChanged: (value) => setState(() => _alcoholPerWeek = value),
          ),
          VitalisSlider(
            label: 'Sono',
            value: _hoursOfSleep,
            min: 3,
            max: 12,
            suffix: 'h',
            accent: const Color(0xFF7C3AED),
            onChanged: (value) =>
                setState(() => _hoursOfSleep = value.roundToDouble()),
          ),
        ],
      ),
      _ => QuestionStep(
        key: const ValueKey('health'),
        title: 'Histórico de saúde',
        subtitle: 'Opcional, ajuda a personalizar sem diagnosticar.',
        children: [
          const DisclaimerBox(
            text:
                'O Vitalis oferece sugestões de bem-estar e não substitui orientação médica.',
          ),
          ToggleRow(
            label: 'Fumante',
            icon: Icons.bolt,
            value: _smoker == 'Yes',
            onChanged: (value) =>
                setState(() => _smoker = value ? 'Yes' : 'No'),
          ),
          ToggleRow(
            label: 'Diabetes',
            icon: Icons.water_drop_outlined,
            value: _diabetic == 'Yes',
            onChanged: (value) =>
                setState(() => _diabetic = value ? 'Yes' : 'No'),
          ),
          ToggleRow(
            label: 'Doença cardíaca',
            icon: Icons.favorite_border,
            value: _heartDisease == 'Yes',
            onChanged: (value) =>
                setState(() => _heartDisease = value ? 'Yes' : 'No'),
          ),
          StepperField(
            label: 'Frequência cardíaca em repouso',
            value: _heartRate,
            suffix: 'bpm',
            min: 40,
            max: 200,
            onChanged: (value) => setState(() => _heartRate = value),
          ),
          Field(
            controller: _controllers['bloodPressureSystolic']!,
            label: 'Pressão sistólica opcional',
            min: 70,
            max: 200,
            optional: true,
          ),
          Field(
            controller: _controllers['bloodPressureDiastolic']!,
            label: 'Pressão diastólica opcional',
            min: 40,
            max: 130,
            optional: true,
          ),
        ],
      ),
    };
  }
}
