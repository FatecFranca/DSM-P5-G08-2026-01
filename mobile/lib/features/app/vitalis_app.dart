part of '../../main.dart';

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
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: appThemeMode,
      builder: (context, mode, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Vitalis',
          theme: vitalisTheme(Brightness.light),
          darkTheme: vitalisTheme(Brightness.dark),
          themeMode: mode,
          home: _ready
              ? RootScreen(session: _session)
              : const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                ),
        );
      },
    );
  }
}
