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
    'bloodPressureSystolic': TextEditingController(),
    'bloodPressureDiastolic': TextEditingController(),
  };
  int _step = 0;
  bool _showStepErrors = false;
  bool _loading = false;

  int? _age;
  double? _heightCm;
  double? _weightKg;
  String? _gender;
  int? _dailySteps;
  double? _exerciseHoursPerWeek;
  String? _workActivityLevel;
  int? _caloriesIntake;
  int? _alcoholPerWeek;
  double? _hoursOfSleep;
  String? _smoker;
  String? _diabetic;
  String? _heartDisease;
  int? _heartRate;

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
        'age': _age!,
        'gender': _gender!,
        'heightCm': _heightCm!,
        'weightKg': _weightKg!,
        'dailySteps': _dailySteps!,
        'caloriesIntake': _caloriesIntake!,
        'hoursOfSleep': _hoursOfSleep!,
        'heartRate': _heartRate!,
        'bloodPressureSystolic': _int('bloodPressureSystolic'),
        'bloodPressureDiastolic': _int('bloodPressureDiastolic'),
        'exerciseHoursPerWeek': _exerciseHoursPerWeek!,
        'smoker': _smoker!,
        'alcoholPerWeek': _alcoholPerWeek!,
        'diabetic': _diabetic!,
        'heartDisease': _heartDisease!,
      };
      final result = await widget.api.post('/assessments', body);
      if (!mounted) return;
      await _showResult(context, result);
      if (!mounted) return;
      widget.onDone();
    } catch (error) {
      _showError(context, error);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  int _int(String key) =>
      int.parse(_controllers[key]!.text.replaceAll(',', '.'));

  bool _isStepValid(int step) => _stepValidationMessage(step) == null;

  String? _stepValidationMessage(int step) {
    switch (step) {
      case 0:
        if (_age == null) return 'Informe sua idade.';
        if (_gender == null) return 'Selecione o sexo biológico.';
        if (_heightCm == null) return 'Informe sua altura.';
        if (_weightKg == null) return 'Informe seu peso.';
        return null;
      case 1:
        if (_dailySteps == null) return 'Informe seus passos diários.';
        if (_exerciseHoursPerWeek == null) {
          return 'Informe as horas de exercício por semana.';
        }
        if (_workActivityLevel == null) {
          return 'Selecione o nível de atividade no trabalho.';
        }
        return null;
      case 2:
        if (_caloriesIntake == null) return 'Informe as calorias por dia.';
        if (_alcoholPerWeek == null) {
          return 'Informe as doses de álcool por semana.';
        }
        if (_hoursOfSleep == null) return 'Informe as horas de sono.';
        return null;
      case 3:
        if (_smoker == null) return 'Informe se você fuma.';
        if (_diabetic == null) return 'Informe se você tem diabetes.';
        if (_heartDisease == null) {
          return 'Informe se você tem doença cardíaca.';
        }
        if (_heartRate == null) {
          return 'Informe a frequência cardíaca em repouso.';
        }
        return null;
      default:
        return null;
    }
  }

  String? _fieldError(bool isMissing) {
    if (!_showStepErrors || !isMissing) return null;
    return 'Campo obrigatório';
  }

  void _nextStep() {
    if (_step < 3) {
      if (!_isStepValid(_step)) {
        setState(() => _showStepErrors = true);
        final message = _stepValidationMessage(_step);
        if (message != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              behavior: SnackBarBehavior.floating,
              content: Text(message),
            ),
          );
        }
        return;
      }
      setState(() {
        _step += 1;
        _showStepErrors = false;
      });
      return;
    }

    setState(() => _showStepErrors = true);
    if (!_isStepValid(_step)) {
      final message = _stepValidationMessage(_step);
      if (message != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            content: Text(message),
          ),
        );
      }
      return;
    }
    if (!_form.currentState!.validate()) return;
    _submit();
  }

  void _previousStep() {
    if (_step > 0) {
      setState(() {
        _step -= 1;
        _showStepErrors = false;
      });
    } else {
      Navigator.of(context).maybePop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Form(
          key: _form,
          autovalidateMode: _showStepErrors && _step == 3
              ? AutovalidateMode.onUserInteraction
              : AutovalidateMode.disabled,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 16, 4),
                child: Row(
                  children: [
                    IconButton(
                      tooltip: 'Voltar',
                      onPressed: _loading ? null : _previousStep,
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
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  children: [
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 260),
                      child: _stepContent(context),
                    ),
                  ],
                ),
              ),
              Material(
                elevation: 4,
                color: Theme.of(context).scaffoldBackgroundColor,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    20,
                    12,
                    20,
                    12 + MediaQuery.viewPaddingOf(context).bottom,
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _loading ? null : _nextStep,
                      icon: _loading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Icon(
                              _step == 3
                                  ? Icons.psychology_alt
                                  : Icons.arrow_forward,
                            ),
                      label: Text(
                        _step == 3 ? 'Analisar meu perfil' : 'Continuar',
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _stepContent(BuildContext context) {
    return switch (_step) {
      0 => QuestionStep(
        key: const ValueKey('personal'),
        title: 'Sobre você',
        subtitle: 'Preencha todos os campos para continuar.',
        children: [
          VitalisSlider(
            label: 'Idade',
            value: _age?.toDouble(),
            min: 18,
            max: 90,
            suffix: ' anos',
            errorText: _fieldError(_age == null),
            onChanged: (value) => setState(() {
              _age = value.round();
              _showStepErrors = false;
            }),
          ),
          ChoiceField(
            label: 'Sexo biológico',
            value: _gender,
            options: const {'Female': 'Feminino', 'Male': 'Masculino'},
            errorText: _fieldError(_gender == null),
            onChanged: (value) => setState(() {
              _gender = value;
              _showStepErrors = false;
            }),
          ),
          VitalisSlider(
            label: 'Altura',
            value: _heightCm,
            min: 140,
            max: 210,
            suffix: ' cm',
            errorText: _fieldError(_heightCm == null),
            onChanged: (value) => setState(() {
              _heightCm = value.roundToDouble();
              _showStepErrors = false;
            }),
          ),
          VitalisSlider(
            label: 'Peso',
            value: _weightKg,
            min: 40,
            max: 160,
            suffix: ' kg',
            errorText: _fieldError(_weightKg == null),
            onChanged: (value) => setState(() {
              _weightKg = value.roundToDouble();
              _showStepErrors = false;
            }),
          ),
        ],
      ),
      1 => QuestionStep(
        key: const ValueKey('activity'),
        title: 'Atividade física',
        subtitle: 'Preencha todos os campos para continuar.',
        children: [
          VitalisSlider(
            label: 'Passos diários',
            value: _dailySteps?.toDouble(),
            min: 1000,
            max: 20000,
            step: 500,
            display: _dailySteps == null ? null : compactSteps(_dailySteps!),
            errorText: _fieldError(_dailySteps == null),
            onChanged: (value) => setState(() {
              _dailySteps = (value / 500).round() * 500;
              _showStepErrors = false;
            }),
          ),
          VitalisSlider(
            label: 'Exercício estruturado por semana',
            value: _exerciseHoursPerWeek,
            min: 0,
            max: 14,
            suffix: 'h',
            errorText: _fieldError(_exerciseHoursPerWeek == null),
            onChanged: (value) => setState(() {
              _exerciseHoursPerWeek = value.roundToDouble();
              _showStepErrors = false;
            }),
          ),
          ChoiceField(
            label: 'Nível de atividade no trabalho',
            value: _workActivityLevel,
            options: const {
              'sitting': 'Sentado',
              'mixed': 'Misto',
              'active': 'Ativo',
            },
            errorText: _fieldError(_workActivityLevel == null),
            onChanged: (value) => setState(() {
              _workActivityLevel = value;
              _showStepErrors = false;
            }),
          ),
        ],
      ),
      2 => QuestionStep(
        key: const ValueKey('food-sleep'),
        title: 'Alimentação & sono',
        subtitle: 'Preencha todos os campos para continuar.',
        children: [
          VitalisSlider(
            label: 'Calorias por dia',
            value: _caloriesIntake?.toDouble(),
            min: 1200,
            max: 4000,
            step: 100,
            suffix: ' kcal',
            accent: const Color(0xFFF59E0B),
            errorText: _fieldError(_caloriesIntake == null),
            onChanged: (value) => setState(() {
              _caloriesIntake = (value / 100).round() * 100;
              _showStepErrors = false;
            }),
          ),
          StepperField(
            label: 'Doses de álcool por semana',
            value: _alcoholPerWeek,
            suffix: _alcoholPerWeek == 1 ? 'dose' : 'doses',
            min: 0,
            max: 30,
            errorText: _fieldError(_alcoholPerWeek == null),
            onChanged: (value) => setState(() {
              _alcoholPerWeek = value;
              _showStepErrors = false;
            }),
          ),
          VitalisSlider(
            label: 'Sono',
            value: _hoursOfSleep,
            min: 3,
            max: 12,
            suffix: 'h',
            accent: const Color(0xFF7C3AED),
            errorText: _fieldError(_hoursOfSleep == null),
            onChanged: (value) => setState(() {
              _hoursOfSleep = value.roundToDouble();
              _showStepErrors = false;
            }),
          ),
        ],
      ),
      _ => QuestionStep(
        key: const ValueKey('health'),
        title: 'Histórico de saúde',
        subtitle: 'Preencha todos os campos para concluir a avaliação.',
        children: [
          const DisclaimerBox(
            text:
                'O Vitalis oferece sugestões de bem-estar e não substitui orientação médica.',
          ),
          ChoiceField(
            label: 'Fumante',
            value: _smoker,
            options: const {'No': 'Não', 'Yes': 'Sim'},
            errorText: _fieldError(_smoker == null),
            onChanged: (value) => setState(() {
              _smoker = value;
              _showStepErrors = false;
            }),
          ),
          ChoiceField(
            label: 'Diabetes',
            value: _diabetic,
            options: const {'No': 'Não', 'Yes': 'Sim'},
            errorText: _fieldError(_diabetic == null),
            onChanged: (value) => setState(() {
              _diabetic = value;
              _showStepErrors = false;
            }),
          ),
          ChoiceField(
            label: 'Doença cardíaca',
            value: _heartDisease,
            options: const {'No': 'Não', 'Yes': 'Sim'},
            errorText: _fieldError(_heartDisease == null),
            onChanged: (value) => setState(() {
              _heartDisease = value;
              _showStepErrors = false;
            }),
          ),
          StepperField(
            label: 'Frequência cardíaca em repouso',
            value: _heartRate,
            suffix: 'bpm',
            min: 40,
            max: 200,
            errorText: _fieldError(_heartRate == null),
            onChanged: (value) => setState(() {
              _heartRate = value;
              _showStepErrors = false;
            }),
          ),
          Field(
            controller: _controllers['bloodPressureSystolic']!,
            label: 'Pressão sistólica',
            min: 70,
            max: 200,
          ),
          Field(
            controller: _controllers['bloodPressureDiastolic']!,
            label: 'Pressão diastólica',
            min: 40,
            max: 130,
          ),
        ],
      ),
    };
  }
}
