import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.instance.initialize();
  runApp(const VitalisApp());
}

const defaultApiUrl = String.fromEnvironment(
  'API_URL',
  defaultValue: 'http://localhost:3333',
);

class VitalisApp extends StatefulWidget {
  const VitalisApp({super.key});

  @override
  State<VitalisApp> createState() => _VitalisAppState();
}

class _VitalisAppState extends State<VitalisApp> {
  late final SessionStore _session;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _boot();
  }

  Future<void> _boot() async {
    _session = SessionStore(await SharedPreferences.getInstance());
    await _session.load();
    setState(() => _ready = true);
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF147D64),
        primary: const Color(0xFF147D64),
        secondary: const Color(0xFFE0962D),
        tertiary: const Color(0xFF4267AC),
        surface: const Color(0xFFF7FAF8),
      ),
      scaffoldBackgroundColor: const Color(0xFFF7FAF8),
      inputDecorationTheme: const InputDecorationTheme(
        border: OutlineInputBorder(),
      ),
    );

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Vitalis',
      theme: theme,
      home: _ready
          ? RootScreen(session: _session)
          : const Scaffold(body: Center(child: CircularProgressIndicator())),
    );
  }
}

class SessionStore extends ChangeNotifier {
  SessionStore(this._prefs);

  final SharedPreferences _prefs;
  String apiUrl = defaultApiUrl;
  String? accessToken;
  String? refreshToken;
  Map<String, dynamic>? user;

  Future<void> load() async {
    apiUrl = _prefs.getString('apiUrl') ?? defaultApiUrl;
    accessToken = _prefs.getString('accessToken');
    refreshToken = _prefs.getString('refreshToken');
    final rawUser = _prefs.getString('user');
    user = rawUser == null ? null : jsonDecode(rawUser) as Map<String, dynamic>;
  }

  Future<void> saveAuth(Map<String, dynamic> data) async {
    accessToken = (data['accessToken'] ?? data['token']) as String?;
    refreshToken = data['refreshToken'] as String?;
    user = data['user'] as Map<String, dynamic>?;
    if (accessToken != null) await _prefs.setString('accessToken', accessToken!);
    if (refreshToken != null) await _prefs.setString('refreshToken', refreshToken!);
    if (user != null) await _prefs.setString('user', jsonEncode(user));
    notifyListeners();
  }

  Future<void> saveApiUrl(String value) async {
    apiUrl = value.trim().replaceAll(RegExp(r'/+$'), '');
    await _prefs.setString('apiUrl', apiUrl);
    notifyListeners();
  }

  Future<void> clear() async {
    accessToken = null;
    refreshToken = null;
    user = null;
    await _prefs.remove('accessToken');
    await _prefs.remove('refreshToken');
    await _prefs.remove('user');
    notifyListeners();
  }
}

class ApiClient {
  ApiClient(this.session);

  final SessionStore session;

  Uri _uri(String path) => Uri.parse('${session.apiUrl}$path');

  Future<Map<String, dynamic>> get(String path) async {
    final response = await http.get(_uri(path), headers: _headers());
    return _decode(response);
  }

  Future<Map<String, dynamic>> post(String path, Map<String, dynamic> body) async {
    final response = await http.post(
      _uri(path),
      headers: _headers(),
      body: jsonEncode(body),
    );
    return _decode(response);
  }

  Future<Map<String, dynamic>> patch(String path, Map<String, dynamic> body) async {
    final response = await http.patch(
      _uri(path),
      headers: _headers(),
      body: jsonEncode(body),
    );
    return _decode(response);
  }

  Map<String, String> _headers() {
    return {
      'Content-Type': 'application/json',
      if (session.accessToken != null) 'Authorization': 'Bearer ${session.accessToken}',
    };
  }

  Map<String, dynamic> _decode(http.Response response) {
    final text = utf8.decode(response.bodyBytes);
    final data = text.isEmpty ? <String, dynamic>{} : jsonDecode(text) as Map<String, dynamic>;
    if (response.statusCode >= 400) {
      throw ApiException.fromResponse(response.statusCode, data);
    }
    return data;
  }
}

class ApiException implements Exception {
  ApiException(this.message, {this.statusCode, this.details});

  final String message;
  final int? statusCode;
  final Object? details;

  factory ApiException.fromResponse(int statusCode, Map<String, dynamic> data) {
    final details = data['details'];
    final baseMessage = data['error']?.toString() ??
        data['message']?.toString() ??
        _fallbackMessage(statusCode);
    final detailMessage = _detailsMessage(details);
    return ApiException(
      detailMessage == null ? baseMessage : '$baseMessage: $detailMessage',
      statusCode: statusCode,
      details: details,
    );
  }

  @override
  String toString() => message;
}

class NotificationService {
  NotificationService._();

  static final instance = NotificationService._();
  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized || kIsWeb) return;

    tzdata.initializeTimeZones();
    try {
      final timezone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timezone.identifier));
    } catch (_) {
      tz.setLocalLocation(tz.local);
    }

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const settings = InitializationSettings(android: android, iOS: ios);
    await _plugin.initialize(settings: settings);
    await _requestPermissions();
    _initialized = true;
  }

  Future<bool> _requestPermissions() async {
    if (kIsWeb) return false;
    final android = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    final ios = _plugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();

    final androidGranted = await android?.requestNotificationsPermission();
    final iosGranted = await ios?.requestPermissions(alert: true, badge: true, sound: true);
    return androidGranted ?? iosGranted ?? true;
  }

  Future<void> syncReminders(List reminders) async {
    if (kIsWeb) return;
    await initialize();
    await _plugin.cancelAll();

    for (final item in reminders) {
      if (item is! Map) continue;
      final reminder = Map<String, dynamic>.from(item);
      if (reminder['isActive'] == false) continue;
      if (reminder['completedToday'] == true) continue;
      final timeOfDay = reminder['timeOfDay']?.toString();
      if (timeOfDay == null || !RegExp(r'^\d{2}:\d{2}$').hasMatch(timeOfDay)) continue;

      await _scheduleDaily(reminder, timeOfDay);
    }
  }

  Future<void> _scheduleDaily(Map<String, dynamic> reminder, String timeOfDay) async {
    final parts = timeOfDay.split(':').map(int.parse).toList();
    final scheduledAt = _nextInstanceOf(parts[0], parts[1]);
    final id = reminder['id']?.toString().hashCode.abs() ?? timeOfDay.hashCode.abs();

    await _plugin.zonedSchedule(
      id: id,
      title: reminder['title']?.toString() ?? 'Lembrete Vitalis',
      body: reminder['message']?.toString().isNotEmpty == true
          ? reminder['message'].toString()
          : 'Hora de cuidar da sua rotina.',
      scheduledDate: scheduledAt,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'vitalis_reminders',
          'Lembretes Vitalis',
          channelDescription: 'Lembretes de habitos e rotina do Vitalis',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  tz.TZDateTime _nextInstanceOf(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }
}

class RootScreen extends StatefulWidget {
  const RootScreen({super.key, required this.session});

  final SessionStore session;

  @override
  State<RootScreen> createState() => _RootScreenState();
}

class _RootScreenState extends State<RootScreen> {
  @override
  void initState() {
    super.initState();
    widget.session.addListener(_refresh);
  }

  @override
  void dispose() {
    widget.session.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() => setState(() {});

  @override
  Widget build(BuildContext context) {
    if (widget.session.accessToken == null) {
      return AuthScreen(session: widget.session);
    }
    return HomeShell(session: widget.session);
  }
}

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key, required this.session});

  final SessionStore session;

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _register = false;
  bool _loading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final api = ApiClient(widget.session);
      final payload = {
        if (_register) 'name': _name.text.trim(),
        'email': _email.text.trim(),
        'password': _password.text,
      };
      final data = await api.post(_register ? '/auth/register' : '/auth/login', payload);
      await widget.session.saveAuth(data);
    } catch (error) {
      if (!mounted) return;
      _showError(context, _authErrorMessage(error, isRegister: _register));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = _register ? 'Crie sua conta' : 'Bem-vindo de volta';
    final subtitle = _register
        ? 'Comece preenchendo seus dados de acesso.'
        : 'Entre para acompanhar seu perfil e sua rotina.';

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 56, 24, 24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: Form(
                    key: _form,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primaryContainer,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.favorite_rounded,
                            size: 34,
                            color: Theme.of(context).colorScheme.onPrimaryContainer,
                          ),
                        ),
                        const SizedBox(height: 18),
                        Text(
                          'Vitalis',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headlineLarge?.copyWith(fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Cuidado diario guiado pelo seu perfil de saude.',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                        ),
                        const SizedBox(height: 28),
                        Text(
                          title,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                        ),
                        const SizedBox(height: 16),
                        SegmentedButton<bool>(
                          segments: const [
                            ButtonSegment(value: false, label: Text('Entrar'), icon: Icon(Icons.login)),
                            ButtonSegment(value: true, label: Text('Cadastrar'), icon: Icon(Icons.person_add)),
                          ],
                          selected: {_register},
                          onSelectionChanged: (value) => setState(() => _register = value.first),
                        ),
                        const SizedBox(height: 18),
                        if (_register)
                          TextFormField(
                            controller: _name,
                            decoration: const InputDecoration(
                              labelText: 'Nome',
                              prefixIcon: Icon(Icons.person_outline),
                            ),
                            textInputAction: TextInputAction.next,
                            validator: (value) => value == null || value.length < 2 ? 'Informe seu nome' : null,
                          ),
                        if (_register) const SizedBox(height: 12),
                        TextFormField(
                          controller: _email,
                          decoration: const InputDecoration(
                            labelText: 'E-mail',
                            prefixIcon: Icon(Icons.mail_outline),
                          ),
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          validator: (value) => value == null || !value.contains('@') ? 'E-mail invalido' : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _password,
                          decoration: InputDecoration(
                            labelText: 'Senha',
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              tooltip: _obscurePassword ? 'Mostrar senha' : 'Ocultar senha',
                              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                              icon: Icon(_obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                            ),
                          ),
                          obscureText: _obscurePassword,
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) => _loading ? null : _submit(),
                          validator: (value) => value == null || value.length < 6 ? 'Minimo de 6 caracteres' : null,
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          height: 52,
                          child: FilledButton.icon(
                            onPressed: _loading ? null : _submit,
                            icon: _loading
                                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                                : const Icon(Icons.arrow_forward),
                            label: Text(_register ? 'Criar conta' : 'Entrar'),
                          ),
                        ),
                        const SizedBox(height: 14),
                        TextButton(
                          onPressed: _loading ? null : () => setState(() => _register = !_register),
                          child: Text(_register ? 'Ja tenho uma conta' : 'Ainda nao tenho conta'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class HomeShell extends StatefulWidget {
  const HomeShell({super.key, required this.session});

  final SessionStore session;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _tab = 0;

  @override
  void initState() {
    super.initState();
    _syncNotifications();
  }

  Future<void> _syncNotifications() async {
    try {
      final data = await ApiClient(widget.session).get('/reminders/today');
      await NotificationService.instance.syncReminders((data['reminders'] as List?) ?? []);
    } catch (_) {
      // Notificacoes sao conveniencia local; a API continua sendo a fonte principal.
    }
  }

  @override
  Widget build(BuildContext context) {
    final api = ApiClient(widget.session);
    final pages = [
      DashboardPage(api: api),
      AssessmentPage(api: api, onDone: () => setState(() => _tab = 0)),
      RecommendationsPage(api: api),
      RemindersPage(api: api),
      ProfilePage(session: widget.session, api: api),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Vitalis'),
        actions: [
          IconButton(
            tooltip: 'Sair',
            onPressed: widget.session.clear,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: pages[_tab],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (value) => setState(() => _tab = value),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.assignment_outlined), selectedIcon: Icon(Icons.assignment), label: 'Avaliacao'),
          NavigationDestination(icon: Icon(Icons.tips_and_updates_outlined), selectedIcon: Icon(Icons.tips_and_updates), label: 'Planos'),
          NavigationDestination(icon: Icon(Icons.notifications_outlined), selectedIcon: Icon(Icons.notifications), label: 'Lembretes'),
          NavigationDestination(icon: Icon(Icons.emoji_events_outlined), selectedIcon: Icon(Icons.emoji_events), label: 'Perfil'),
        ],
      ),
    );
  }
}

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key, required this.api});

  final ApiClient api;

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  late Future<Map<String, dynamic>> _future = _load();

  Future<Map<String, dynamic>> _load() async {
    final dashboard = await widget.api.get('/dashboard');
    final health = await widget.api.get('/health/ready').catchError((_) => <String, dynamic>{});
    final latest = await widget.api.get('/assessments/latest').catchError((_) => <String, dynamic>{});
    final clusterStats = await widget.api.get('/clusters/me/stats').catchError((_) => <String, dynamic>{});
    final assessment = latest['assessment'] as Map<String, dynamic>?;
    final assessmentId = assessment?['id']?.toString();
    final explanation = assessmentId == null
        ? <String, dynamic>{}
        : await widget.api.get('/assessments/$assessmentId/explanation').catchError((_) => <String, dynamic>{});

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
        final explanationDetails = data['explanationDetails'] as Map<String, dynamic>;
        final clusterStats = data['clusterStats'] as Map<String, dynamic>?;

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            MlStatusPanel(health: health),
            const SizedBox(height: 12),
            if (summary == null)
              InfoPanel(
                icon: Icons.assignment_add,
                title: 'Faca sua primeira avaliacao',
                body: 'Preencha o questionario para gerar perfil, recomendacoes e lembretes.',
              )
            else
              ProfileSummary(summary: summary, latest: latest, explanation: explanationDetails),
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
            ...reminders.take(4).map((item) => ReminderCard(item: item as Map<String, dynamic>)),
            if (reminders.isEmpty) const EmptyState(text: 'Nenhum lembrete ativo para hoje.'),
            const SizedBox(height: 16),
            SectionTitle('Recomendacoes ativas', trailing: '${recommendations.length}'),
            ...recommendations.take(4).map((item) => RecommendationCard(item: item as Map<String, dynamic>)),
            if (recommendations.isEmpty) const EmptyState(text: 'As recomendacoes aparecem depois da avaliacao.'),
          ],
        );
      },
    );
  }
}

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
    'age': TextEditingController(text: '30'),
    'heightCm': TextEditingController(text: '170'),
    'weightKg': TextEditingController(text: '75'),
    'dailySteps': TextEditingController(text: '6000'),
    'exerciseHoursPerWeek': TextEditingController(text: '3'),
    'caloriesIntake': TextEditingController(text: '2200'),
    'alcoholPerWeek': TextEditingController(text: '1'),
    'hoursOfSleep': TextEditingController(text: '7'),
    'heartRate': TextEditingController(text: '80'),
    'bloodPressureSystolic': TextEditingController(),
    'bloodPressureDiastolic': TextEditingController(),
  };
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
        'age': _int('age'),
        'gender': _gender,
        'heightCm': _double('heightCm'),
        'weightKg': _double('weightKg'),
        'dailySteps': _int('dailySteps'),
        'caloriesIntake': _int('caloriesIntake'),
        'hoursOfSleep': _double('hoursOfSleep'),
        if (_controllers['heartRate']!.text.trim().isNotEmpty) 'heartRate': _int('heartRate'),
        if (_controllers['bloodPressureSystolic']!.text.trim().isNotEmpty)
          'bloodPressureSystolic': _int('bloodPressureSystolic'),
        if (_controllers['bloodPressureDiastolic']!.text.trim().isNotEmpty)
          'bloodPressureDiastolic': _int('bloodPressureDiastolic'),
        'exerciseHoursPerWeek': _double('exerciseHoursPerWeek'),
        'smoker': _smoker,
        'alcoholPerWeek': _int('alcoholPerWeek'),
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

  int _int(String key) => int.parse(_controllers[key]!.text.replaceAll(',', '.'));
  double _double(String key) => double.parse(_controllers[key]!.text.replaceAll(',', '.'));

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _form,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const SectionTitle('Dados pessoais'),
          Field(controller: _controllers['age']!, label: 'Idade', min: 18, max: 120),
          ChoiceField(
            label: 'Sexo',
            value: _gender,
            options: const {'Male': 'Masculino', 'Female': 'Feminino'},
            onChanged: (value) => setState(() => _gender = value),
          ),
          Field(controller: _controllers['heightCm']!, label: 'Altura (cm)', min: 100, max: 250),
          Field(controller: _controllers['weightKg']!, label: 'Peso (kg)', min: 30, max: 300),
          const SectionTitle('Rotina'),
          Field(controller: _controllers['dailySteps']!, label: 'Passos diarios', min: 0, max: 50000),
          Field(controller: _controllers['exerciseHoursPerWeek']!, label: 'Horas de exercicio por semana', min: 0, max: 30),
          Field(controller: _controllers['caloriesIntake']!, label: 'Calorias por dia', min: 800, max: 6000),
          Field(controller: _controllers['hoursOfSleep']!, label: 'Horas de sono', min: 3, max: 14),
          Field(controller: _controllers['alcoholPerWeek']!, label: 'Doses de alcool por semana', min: 0, max: 30),
          const SectionTitle('Historico de saude'),
          ChoiceField(
            label: 'Fumante',
            value: _smoker,
            options: const {'No': 'Nao', 'Yes': 'Sim'},
            onChanged: (value) => setState(() => _smoker = value),
          ),
          ChoiceField(
            label: 'Diabetes',
            value: _diabetic,
            options: const {'No': 'Nao', 'Yes': 'Sim'},
            onChanged: (value) => setState(() => _diabetic = value),
          ),
          ChoiceField(
            label: 'Doenca cardiaca',
            value: _heartDisease,
            options: const {'No': 'Nao', 'Yes': 'Sim'},
            onChanged: (value) => setState(() => _heartDisease = value),
          ),
          Field(controller: _controllers['heartRate']!, label: 'Frequencia cardiaca', min: 40, max: 200, optional: true),
          Field(controller: _controllers['bloodPressureSystolic']!, label: 'Pressao sistolica', min: 70, max: 200, optional: true),
          Field(controller: _controllers['bloodPressureDiastolic']!, label: 'Pressao diastolica', min: 40, max: 130, optional: true),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: _loading ? null : _submit,
            icon: _loading
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.psychology_alt),
            label: const Text('Gerar perfil'),
          ),
        ],
      ),
    );
  }
}

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
      widget.api.get('/recommendations/meal-plan').catchError((_) => <String, dynamic>{}),
      widget.api.get('/recommendations/weekly-routine').catchError((_) => <String, dynamic>{}),
    ]);
    return {'recommendations': results[0]['recommendations'] ?? [], 'meal': results[1], 'routine': results[2]};
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
            if (recommendations.isEmpty) const EmptyState(text: 'Preencha uma avaliacao para receber recomendacoes.'),
            ...recommendations.map((item) => RecommendationCard(item: item as Map<String, dynamic>)),
            const SizedBox(height: 16),
            MealPlanPanel(data: meal['meals']),
            WeeklyRoutinePanel(data: routine['week']),
          ],
        );
      },
    );
  }
}

class RemindersPage extends StatefulWidget {
  const RemindersPage({super.key, required this.api});

  final ApiClient api;

  @override
  State<RemindersPage> createState() => _RemindersPageState();
}

class _RemindersPageState extends State<RemindersPage> {
  late Future<Map<String, dynamic>> _future = _load();

  Future<Map<String, dynamic>> _load() async {
    final data = await widget.api.get('/reminders/today');
    await NotificationService.instance.syncReminders((data['reminders'] as List?) ?? []);
    return data;
  }

  Future<void> _syncNow(List reminders) async {
    await NotificationService.instance.syncReminders(reminders);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Text('Notificacoes dos lembretes sincronizadas.'),
      ),
    );
  }

  Future<void> _complete(String id) async {
    try {
      await widget.api.post('/reminders/$id/complete', {});
      if (!mounted) return;
      setState(() => _future = _load());
    } catch (error) {
      if (!mounted) return;
      _showError(context, error);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DataScaffold(
      future: _future,
      onRefresh: () => setState(() => _future = _load()),
      builder: (data) {
        final reminders = (data['reminders'] as List?) ?? [];
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            SectionTitle(
              'Hoje',
              trailing: '${reminders.length}',
              action: IconButton.filledTonal(
                tooltip: 'Sincronizar notificacoes',
                onPressed: reminders.isEmpty ? null : () => _syncNow(reminders),
                icon: const Icon(Icons.notifications_active),
              ),
            ),
            if (reminders.isNotEmpty)
              InfoPanel(
                icon: Icons.notifications_active,
                title: 'Notificacoes ativas',
                body: 'O celular avisara no horario de cada lembrete ativo.',
              ),
            if (reminders.isNotEmpty) const SizedBox(height: 10),
            if (reminders.isEmpty) const EmptyState(text: 'Os lembretes aparecem depois da avaliacao.'),
            ...reminders.map((item) {
              final reminder = item as Map<String, dynamic>;
              final done = reminder['completedToday'] == true;
              return ReminderCard(
                item: reminder,
                action: IconButton.filledTonal(
                  tooltip: done ? 'Concluido' : 'Concluir',
                  onPressed: done ? null : () => _complete(reminder['id'].toString()),
                  icon: Icon(done ? Icons.check_circle : Icons.check),
                ),
              );
            }),
          ],
        );
      },
    );
  }
}

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key, required this.session, required this.api});

  final SessionStore session;
  final ApiClient api;

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late Future<Map<String, dynamic>> _future = _load();

  Future<Map<String, dynamic>> _load() async {
    final results = await Future.wait([
      widget.api.get('/gamification').catchError((_) => <String, dynamic>{}),
      widget.api.get('/gamification/achievements').catchError((_) => <String, dynamic>{}),
    ]);
    return {'game': results[0], 'achievements': results[1]};
  }

  @override
  Widget build(BuildContext context) {
    return DataScaffold(
      future: _future,
      onRefresh: () => setState(() => _future = _load()),
      builder: (data) {
        final game = data['game'] as Map<String, dynamic>;
        final gamification = (game['gamification'] as Map<String, dynamic>?) ?? {};
        final achievements = ((data['achievements'] as Map<String, dynamic>)['achievements'] as List?) ?? [];

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            InfoPanel(
              icon: Icons.person,
              title: widget.session.user?['name']?.toString() ?? 'Usuario Vitalis',
              body: widget.session.user?['email']?.toString() ?? '',
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: MetricTile(label: 'Pontos', value: '${gamification['points'] ?? 0}', icon: Icons.stars)),
                const SizedBox(width: 12),
                Expanded(child: MetricTile(label: 'Sequencia', value: '${gamification['currentStreak'] ?? 0}', icon: Icons.local_fire_department)),
              ],
            ),
            const SizedBox(height: 16),
            const SectionTitle('Conquistas'),
            if (achievements.isEmpty) const EmptyState(text: 'Conclua avaliacoes e lembretes para desbloquear conquistas.'),
            ...achievements.map((item) {
              final achievement = item as Map<String, dynamic>;
              return ListTile(
                leading: const Icon(Icons.workspace_premium),
                title: Text(achievement['title']?.toString() ?? achievement['key']?.toString() ?? 'Conquista'),
                subtitle: Text(achievement['description']?.toString() ?? ''),
              );
            }),
          ],
        );
      },
    );
  }
}

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
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.cloud_off, size: 44),
                  const SizedBox(height: 12),
                  Text(snapshot.error.toString(), textAlign: TextAlign.center),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(onPressed: onRefresh, icon: const Icon(Icons.refresh), label: const Text('Tentar novamente')),
                ],
              ),
            ),
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
    final confidence = (explanation?['confidence'] as num?) ?? classification?['confidence'] as num?;
    final modelVersion = explanation?['modelVersion']?.toString() ?? classification?['modelVersion']?.toString();
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
                  const Icon(Icons.health_and_safety),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      profileLabel(summary['profile']?.toString()),
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                    ),
                  ),
                  Text('${summary['profileScore'] ?? 0}/100'),
                ],
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(value: ((summary['profileScore'] as num?)?.toDouble() ?? 0) / 100),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  Chip(
                    avatar: const Icon(Icons.groups, size: 18),
                    label: Text(summary['clusterLabel']?.toString() ?? 'Cluster em analise'),
                  ),
                  if (modelVersion != null && !fromMl)
                    Chip(
                      avatar: const Icon(Icons.rule, size: 18),
                      label: Text(modelLabel(modelVersion)),
                    ),
                  if (confidence != null)
                    Chip(
                      avatar: const Icon(Icons.verified_outlined, size: 18),
                      label: Text('${(confidence.toDouble() * 100).round()}% confianca'),
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
    final color = available ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.secondary;

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
                      available ? 'IA conectada' : 'Classificacao por regras',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    Text(
                      available
                          ? 'As avaliacoes usam o modelo de Machine Learning.'
                          : 'A API esta online, mas a IA nao respondeu agora.',
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
    final messages = ((explanation['messages'] as List?) ?? []).map((item) => item.toString()).toList();
    final factors = ((explanation['factors'] as List?) ?? []).whereType<Map>().map((item) => Map<String, dynamic>.from(item)).toList();
    final geminiSummary = explanation['geminiSummary']?.toString();
    final fromMl = isMlModel(data['modelVersion']?.toString() ?? explanation['modelVersion']?.toString());

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
                  Icon(Icons.auto_awesome, color: Theme.of(context).colorScheme.tertiary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Explicacao da IA',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
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
          Expanded(child: Text(factor['detail']?.toString() ?? factor['factor']?.toString() ?? 'Fator analisado')),
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
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          ComparisonRow(label: 'Passos', item: comparison['dailySteps'], suffix: ''),
          ComparisonRow(label: 'Sono', item: comparison['hoursOfSleep'], suffix: 'h'),
          ComparisonRow(label: 'Exercicio', item: comparison['exerciseHoursPerWeek'], suffix: 'h/sem'),
          ComparisonRow(label: 'IMC', item: comparison['bmi'], suffix: ''),
        ],
      ),
    );
  }
}

class ComparisonRow extends StatelessWidget {
  const ComparisonRow({super.key, required this.label, required this.item, required this.suffix});

  final String label;
  final Object? item;
  final String suffix;

  @override
  Widget build(BuildContext context) {
    final data = item is Map ? Map<String, dynamic>.from(item as Map) : <String, dynamic>{};
    final yours = data['yours'];
    final avg = data['clusterAvg'];
    if (yours == null || avg == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          Text('Voce: ${formatMetric(yours)}$suffix'),
          const SizedBox(width: 10),
          Text('Grupo: ${formatMetric(avg)}$suffix'),
        ],
      ),
    );
  }
}

class InfoPanel extends StatelessWidget {
  const InfoPanel({super.key, required this.icon, required this.title, required this.body});

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: panelDecoration(context),
      child: Row(
        children: [
          Icon(icon, size: 34, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                if (body.isNotEmpty) Text(body),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class MetricTile extends StatelessWidget {
  const MetricTile({super.key, required this.label, required this.value, required this.icon});

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
          Text(value, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
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
        title: Text(template['title']?.toString() ?? 'Recomendacao'),
        subtitle: Text(template['description']?.toString() ?? template['category']?.toString() ?? ''),
      ),
    );
  }
}

class ReminderCard extends StatelessWidget {
  const ReminderCard({super.key, required this.item, this.action});

  final Map<String, dynamic> item;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(_reminderIcon(item['type']?.toString())),
        title: Text(item['title']?.toString() ?? 'Lembrete'),
        subtitle: Text('${item['timeOfDay'] ?? ''} ${item['message'] ?? ''}'.trim()),
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
          Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
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

class MealCard extends StatelessWidget {
  const MealCard({super.key, required this.meal});

  final Map<String, dynamic> meal;

  @override
  Widget build(BuildContext context) {
    final type = meal['mealType']?.toString() ?? 'meal';
    final color = _mealColor(context, type);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: panelDecoration(context),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(height: 5, color: color),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(8),
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
                              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                                  ),
                            ),
                            Text(
                              meal['title']?.toString() ?? 'Refeicao',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(meal['description']?.toString() ?? ''),
                  if (meal['tip'] != null) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.lightbulb_outline, size: 18, color: Theme.of(context).colorScheme.secondary),
                          const SizedBox(width: 8),
                          Expanded(child: Text(meal['tip'].toString())),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class WeeklyRoutinePanel extends StatelessWidget {
  const WeeklyRoutinePanel({super.key, required this.data});

  final Object? data;

  @override
  Widget build(BuildContext context) {
    final days = mapList(data);
    if (days.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 4),
        const SectionTitle('Rotina semanal'),
        ...days.map((day) => DayRoutineCard(day: day)),
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
    final activities = ((day['activities'] as List?) ?? []).map((item) => item.toString()).toList();
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
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        Text(
                          focus,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
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
            child: Text(text, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
          ),
          if (trailing != null) Badge(label: Text(trailing!)),
          if (action != null) ...[
            const SizedBox(width: 8),
            action!,
          ],
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
      child: Text(text, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyMedium),
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
          if (optional && (value == null || value.trim().isEmpty)) return null;
          final number = num.tryParse((value ?? '').replaceAll(',', '.'));
          if (number == null) return 'Informe um numero';
          if (number < min || number > max) return 'Use um valor entre $min e $max';
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
  });

  final String label;
  final String value;
  final Map<String, String> options;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 6),
          SegmentedButton<String>(
            segments: options.entries
                .map((entry) => ButtonSegment(value: entry.key, label: Text(entry.value)))
                .toList(),
            selected: {value},
            onSelectionChanged: (selection) => onChanged(selection.first),
          ),
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

String profileLabel(String? profile) {
  return switch (profile) {
    'Saudavel_Ativo' => 'Saudavel ativo',
    'Moderado' => 'Moderado',
    'Sedentario' => 'Sedentario',
    'Em_Risco' => 'Em risco',
    _ => 'Perfil em analise',
  };
}

String modelLabel(String modelVersion) {
  if (modelVersion.toLowerCase().startsWith('ml')) return 'Modelo IA $modelVersion';
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

List<Map<String, dynamic>> mapList(Object? value) {
  if (value is List) {
    return value.whereType<Map>().map((item) => Map<String, dynamic>.from(item)).toList();
  }
  if (value is Map) {
    return value.values.whereType<Map>().map((item) => Map<String, dynamic>.from(item)).toList();
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
  if (value.contains('forca') || value.contains('treino')) return Icons.fitness_center;
  if (value.contains('cardio') || value.contains('caminhada') || value.contains('movimento')) {
    return Icons.directions_walk;
  }
  if (value.contains('alimentacao') || value.contains('nutricional')) return Icons.restaurant;
  if (value.contains('sono') || value.contains('descanso') || value.contains('recuperacao')) return Icons.bedtime;
  if (value.contains('planejamento') || value.contains('rotina')) return Icons.event_note;
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
    return value.entries.map((entry) => '${entry.key}: ${_pretty(entry.value)}').join('\n');
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
    final values = details.map((item) => item.toString()).where((item) => item.trim().isNotEmpty).toList();
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
    return ApiException('E-mail ou senha incorretos. Confira os dados e tente novamente.');
  }
  if (isRegister && error.statusCode == 409) {
    return ApiException('Este e-mail ja esta cadastrado. Entre com sua conta ou use outro e-mail.');
  }
  if (error.statusCode == 400) {
    return ApiException(error.message.replaceFirst('Dados invalidos: ', 'Verifique os campos:\n'));
  }
  return error;
}

void _showResult(BuildContext context, Map<String, dynamic> result) {
  final plan = result['plan'] as Map<String, dynamic>?;
  final classification = result['classification'] as Map<String, dynamic>?;
  final explanation = result['explanation'] as Map<String, dynamic>?;
  final messages = ((explanation?['messages'] as List?) ?? []).map((item) => item.toString()).toList();
  final confidence = classification?['confidence'] as num?;
  final modelVersion = classification?['modelVersion']?.toString() ?? explanation?['modelVersion']?.toString();

  showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Perfil gerado'),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              profileLabel(plan?['profile']?.toString()),
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text('Score: ${plan?['profileScore'] ?? '-'}/100'),
            Text(plan?['clusterLabel']?.toString() ?? 'Cluster em analise'),
            if (modelVersion != null) Text(modelLabel(modelVersion)),
            if (confidence != null) Text('Confianca: ${(confidence.toDouble() * 100).round()}%'),
            if (messages.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(messages.first),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('OK')),
      ],
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
