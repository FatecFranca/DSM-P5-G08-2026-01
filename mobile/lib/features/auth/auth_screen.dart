part of '../../main.dart';

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
  late final TextEditingController _apiUrl =
      TextEditingController(text: widget.session.apiUrl);
  bool _register = false;
  bool _loading = false;
  bool _obscurePassword = true;
  bool _showAdvanced = false;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _apiUrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await widget.session.saveApiUrl(_apiUrl.text.trim());
      final api = ApiClient(widget.session);
      final payload = {
        if (_register) 'name': _name.text.trim(),
        'email': _email.text.trim(),
        'password': _password.text,
      };
      final data = await api.post(
        _register ? '/auth/register' : '/auth/login',
        payload,
      );
      await widget.session.saveAuth(data);
    } catch (error) {
      if (!mounted) return;
      _showError(
        context,
        friendlyErrorMessage(error, isRegister: _register),
      );
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
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
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
                        color: Theme.of(context)
                            .colorScheme
                            .onPrimaryContainer,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'Vitalis',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Cuidado diário guiado pelo seu perfil de saúde.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant,
                          ),
                    ),
                    const SizedBox(height: 28),
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Material(
                      type: MaterialType.transparency,
                      child: SegmentedButton<bool>(
                        segments: const [
                          ButtonSegment(
                            value: false,
                            label: Text('Entrar'),
                            icon: Icon(Icons.login),
                          ),
                          ButtonSegment(
                            value: true,
                            label: Text('Cadastrar'),
                            icon: Icon(Icons.person_add),
                          ),
                        ],
                        selected: {_register},
                        onSelectionChanged: (value) =>
                            setState(() => _register = value.first),
                      ),
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
                        validator: (value) =>
                            value == null || value.length < 2
                                ? 'Informe seu nome'
                                : null,
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
                      validator: (value) =>
                          value == null || !value.contains('@')
                              ? 'E-mail inválido'
                              : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _password,
                      decoration: InputDecoration(
                        labelText: 'Senha',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          tooltip: _obscurePassword
                              ? 'Mostrar senha'
                              : 'Ocultar senha',
                          onPressed: () => setState(
                            () => _obscurePassword = !_obscurePassword,
                          ),
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                        ),
                      ),
                      obscureText: _obscurePassword,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _loading ? null : _submit(),
                      validator: (value) =>
                          value == null || value.length < 6
                              ? 'Mínimo de 6 caracteres'
                              : null,
                    ),
                    const SizedBox(height: 12),
                    TextButton.icon(
                      onPressed: () =>
                          setState(() => _showAdvanced = !_showAdvanced),
                      icon: Icon(
                        _showAdvanced
                            ? Icons.expand_less
                            : Icons.settings_outlined,
                      ),
                      label: Text(
                        _showAdvanced
                            ? 'Ocultar URL da API'
                            : 'Configurar URL da API',
                      ),
                    ),
                    if (_showAdvanced) ...[
                      TextFormField(
                        controller: _apiUrl,
                        decoration: InputDecoration(
                          labelText: 'URL da API',
                          hintText: defaultApiUrl,
                          prefixIcon: const Icon(Icons.link),
                          helperText:
                              'VM: $defaultApiUrl · Local: $localApiUrl · Emulador: $androidEmulatorApiUrl',
                        ),
                        keyboardType: TextInputType.url,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Informe a URL da API';
                          }
                          final uri = Uri.tryParse(value.trim());
                          if (uri == null ||
                              !uri.hasScheme ||
                              uri.host.isEmpty) {
                            return 'URL inválida';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 8),
                    ],
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 52,
                      child: FilledButton.icon(
                        onPressed: _loading ? null : _submit,
                        icon: _loading
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.arrow_forward),
                        label: Text(_register ? 'Criar conta' : 'Entrar'),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextButton(
                      onPressed: _loading
                          ? null
                          : () => setState(() => _register = !_register),
                      child: Text(
                        _register
                            ? 'Já tenho uma conta'
                            : 'Ainda não tenho conta',
                      ),
                    ),
                    const SizedBox(height: 8),
                    const DisclaimerBox(
                      text:
                          'O Vitalis oferece sugestões de bem-estar e não substitui orientação médica.',
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
