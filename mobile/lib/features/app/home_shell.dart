part of '../../main.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key, required this.session});

  final SessionStore session;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _tab = 0;
  int _refreshSignal = 0;

  @override
  void initState() {
    super.initState();
    _syncNotifications();
  }

  Future<void> _syncNotifications() async {
    try {
      final data = await ApiClient(widget.session).get('/reminders/today');
      await NotificationService.instance.syncReminders(
        (data['reminders'] as List?) ?? [],
      );
    } catch (_) {}
  }

  void _refreshTabs() {
    setState(() => _refreshSignal++);
    _syncNotifications();
  }

  void _openAssessment() {
    final api = ApiClient(widget.session);
    Navigator.of(context).push(
      vitalisRoute<void>(
        AssessmentPage(
          api: api,
          onDone: () {
            Navigator.of(context).pop();
            setState(() => _tab = 0);
            _refreshTabs();
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final api = ApiClient(widget.session);
    final pages = [
      DashboardPage(
        api: api,
        refreshSignal: _refreshSignal,
        onStartAssessment: _openAssessment,
      ),
      RecommendationsPage(api: api, refreshSignal: _refreshSignal),
      RemindersPage(api: api, refreshSignal: _refreshSignal),
      ProfilePage(
        session: widget.session,
        api: api,
        refreshSignal: _refreshSignal,
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Vitalis'),
        actions: [
          IconButton(
            tooltip: 'Nova avaliação',
            onPressed: _openAssessment,
            icon: const Icon(Icons.assignment_outlined),
          ),
          IconButton(
            tooltip: 'Sair',
            onPressed: widget.session.clear,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: IndexedStack(
        index: _tab,
        children: pages,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (value) {
          setState(() => _tab = value);
          if (value == 0 || value == 3) _refreshTabs();
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Início',
          ),
          NavigationDestination(
            icon: Icon(Icons.menu_book_outlined),
            selectedIcon: Icon(Icons.menu_book),
            label: 'Plano',
          ),
          NavigationDestination(
            icon: Icon(Icons.notifications_outlined),
            selectedIcon: Icon(Icons.notifications),
            label: 'Lembretes',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }
}
