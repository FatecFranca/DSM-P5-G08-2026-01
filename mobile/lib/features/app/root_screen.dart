part of '../../main.dart';

class RootScreen extends StatefulWidget {
  const RootScreen({super.key, required this.session});

  final SessionStore session;

  @override
  State<RootScreen> createState() => _RootScreenState();
}

class _RootScreenState extends State<RootScreen> {
  bool _showWelcome = true;

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

  void _refresh() {
    if (widget.session.accessToken == null) {
      setState(() => _showWelcome = true);
    } else {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.session.accessToken == null) {
      if (_showWelcome) {
        return WelcomeScreen(onFinished: () => setState(() => _showWelcome = false));
      }
      return AuthScreen(session: widget.session);
    }
    return HomeShell(session: widget.session);
  }
}
