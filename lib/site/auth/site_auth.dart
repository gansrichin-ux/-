part of '../../main_site.dart';

class SiteAuthGate extends StatefulWidget {
  final bool isDark;
  final VoidCallback onToggleTheme;

  const SiteAuthGate({
    super.key,
    required this.isDark,
    required this.onToggleTheme,
  });

  @override
  State<SiteAuthGate> createState() => _SiteAuthGateState();
}

class _SiteAuthGateState extends State<SiteAuthGate> {
  bool _suppressingError = false;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<UserModel?>(
      stream: AuthRepository.instance.watchCurrentUser(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return SiteLoadingScreen(
            isDark: widget.isDark,
            onToggleTheme: widget.onToggleTheme,
          );
        }

        if (snapshot.hasError) {
          final errStr = snapshot.error.toString();
          final isPermissionError = errStr.contains('permission-denied') ||
              errStr.contains('PERMISSION_DENIED');

          if (isPermissionError && !_suppressingError) {
            _suppressingError = true;
            Future.delayed(const Duration(seconds: 4), () {
              if (mounted) setState(() => _suppressingError = false);
            });
          }

          if (_suppressingError) {
            return SiteLoadingScreen(
              isDark: widget.isDark,
              onToggleTheme: widget.onToggleTheme,
            );
          }

          return SiteErrorScreen(
            title: 'Ошибка входа',
            message: errStr,
            isDark: widget.isDark,
            onToggleTheme: widget.onToggleTheme,
          );
        }

        _suppressingError = false;

        final user = snapshot.data;
        if (user == null) {
          return SiteLoginScreen(isDark: widget.isDark, onToggleTheme: widget.onToggleTheme);
        }

        return SiteRouteRedirect(
          location: user.isAdmin ? '/admin' : '/dashboard',
          isDark: widget.isDark,
          onToggleTheme: widget.onToggleTheme,
        );
      },
    );
  }
}

class SiteDashboardGate extends StatefulWidget {
  final bool isDark;
  final VoidCallback onToggleTheme;

  const SiteDashboardGate({
    super.key,
    required this.isDark,
    required this.onToggleTheme,
  });

  @override
  State<SiteDashboardGate> createState() => _SiteDashboardGateState();
}

class _SiteDashboardGateState extends State<SiteDashboardGate> {
  // If we see a transient permission-denied, suppress it for up to 4 seconds
  // before surfacing the real error screen. No stream restarts = no Auth spam.
  bool _suppressingError = false;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<UserModel?>(
      stream: AuthRepository.instance.watchCurrentUser(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return SiteLoadingScreen(
            isDark: widget.isDark,
            onToggleTheme: widget.onToggleTheme,
          );
        }

        if (snapshot.hasError) {
          final errStr = snapshot.error.toString();
          final isPermissionError = errStr.contains('permission-denied') ||
              errStr.contains('PERMISSION_DENIED');

          if (isPermissionError && !_suppressingError) {
            _suppressingError = true;
            // After 4 s, force a rebuild so if error persists it becomes visible.
            Future.delayed(const Duration(seconds: 4), () {
              if (mounted) setState(() => _suppressingError = false);
            });
          }

          if (_suppressingError) {
            return SiteLoadingScreen(
              isDark: widget.isDark,
              onToggleTheme: widget.onToggleTheme,
            );
          }

          return SiteErrorScreen(
            title: 'Ошибка входа',
            message: errStr,
            isDark: widget.isDark,
            onToggleTheme: widget.onToggleTheme,
          );
        }

        _suppressingError = false;

        final user = snapshot.data;
        if (user == null) {
          return SiteRouteRedirect(
            location: '/auth',
            isDark: widget.isDark,
            onToggleTheme: widget.onToggleTheme,
          );
        }

        if (user.isAdmin) {
          return SiteRouteRedirect(
            location: '/admin',
            isDark: widget.isDark,
            onToggleTheme: widget.onToggleTheme,
          );
        }

        // Show OTP verification if user hasn't verified email yet
        if (!user.emailCodeVerified) {
          return SiteOtpVerifyScreen(
            uid: user.uid,
            email: user.email,
            isDark: widget.isDark,
            onToggleTheme: widget.onToggleTheme,
          );
        }

        return SiteDashboard(
          user: user,
          isDark: widget.isDark,
          onToggleTheme: widget.onToggleTheme,
        );
      },
    );
  }
}

// ─── OTP Verification Screen ──────────────────────────────────────────────────

class SiteOtpVerifyScreen extends StatefulWidget {
  final String uid;
  final String email;
  final bool isDark;
  final VoidCallback onToggleTheme;

  const SiteOtpVerifyScreen({
    super.key,
    required this.uid,
    required this.email,
    required this.isDark,
    required this.onToggleTheme,
  });

  @override
  State<SiteOtpVerifyScreen> createState() => _SiteOtpVerifyScreenState();
}

class _SiteOtpVerifyScreenState extends State<SiteOtpVerifyScreen> {
  final _controllers = List.generate(6, (_) => TextEditingController());
  final _focusNodes = List.generate(6, (_) => FocusNode());
  bool _loading = false;
  bool _sending = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _sendCode();
  }

  @override
  void dispose() {
    for (final c in _controllers) c.dispose();
    for (final f in _focusNodes) f.dispose();
    super.dispose();
  }

  Future<void> _sendCode() async {
    setState(() { _sending = true; _error = null; });
    final err = await AuthRepository.instance.sendOtpCode(widget.uid, widget.email);
    if (mounted) {
      setState(() {
        _sending = false;
        _error = err;
      });
    }
  }

  String get _enteredCode => _controllers.map((c) => c.text).join();

  Future<void> _verify() async {
    if (_enteredCode.length < 6) return;
    setState(() { _loading = true; _error = null; });
    final err = await AuthRepository.instance.verifyOtpCode(widget.uid, _enteredCode);
    if (!mounted) return;
    if (err != null) {
      setState(() { _loading = false; _error = err; });
      for (final c in _controllers) c.clear();
      if (_focusNodes.isNotEmpty) FocusScope.of(context).requestFocus(_focusNodes[0]);
      return;
    }
    // emailCodeVerified is now true in Firestore — watchCurrentUser will emit updated model
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const _LogoMark(),
                  const SizedBox(height: 32),
                  Container(
                    width: 64, height: 64,
                    decoration: BoxDecoration(color: colors.primaryContainer, borderRadius: BorderRadius.circular(18)),
                    child: Icon(Icons.mark_email_read_rounded, size: 32, color: colors.primary),
                  ),
                  const SizedBox(height: 20),
                  Text('Подтвердите email', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900)),
                  const SizedBox(height: 10),
                  Text(
                    _sending
                        ? 'Отправляем код на ${widget.email}...'
                        : 'Мы отправили 6-значный код на\n${widget.email}\nВведите его ниже.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: colors.onSurfaceVariant, height: 1.5),
                  ),
                  const SizedBox(height: 28),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(6, (i) {
                      return Container(
                        width: 48, height: 56,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        child: TextFormField(
                          controller: _controllers[i],
                          focusNode: _focusNodes[i],
                          textAlign: TextAlign.center,
                          keyboardType: TextInputType.number,
                          maxLength: 1,
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
                          decoration: InputDecoration(
                            counterText: '',
                            contentPadding: EdgeInsets.zero,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: colors.primary, width: 2),
                            ),
                          ),
                          onChanged: (val) {
                            if (val.isNotEmpty && i < 5) FocusScope.of(context).requestFocus(_focusNodes[i + 1]);
                            if (val.isEmpty && i > 0) FocusScope.of(context).requestFocus(_focusNodes[i - 1]);
                            if (_enteredCode.length == 6) _verify();
                          },
                        ),
                      );
                    }),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(color: colors.errorContainer, borderRadius: BorderRadius.circular(10)),
                      child: Row(children: [
                        Icon(Icons.error_outline_rounded, size: 18, color: colors.onErrorContainer),
                        const SizedBox(width: 8),
                        Expanded(child: Text(_error!, style: TextStyle(color: colors.onErrorContainer, fontSize: 13))),
                      ]),
                    ),
                  ],
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: (_loading || _enteredCode.length < 6) ? null : _verify,
                      icon: _loading
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.check_rounded),
                      label: Text(_loading ? 'Проверяем...' : 'Подтвердить'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton.icon(
                    onPressed: _sending ? null : _sendCode,
                    icon: _sending
                        ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.refresh_rounded, size: 16),
                    label: Text(_sending ? 'Отправка...' : 'Отправить новый код'),
                  ),
                  const SizedBox(height: 4),
                  TextButton(
                    onPressed: () => AuthRepository.instance.signOut(),
                    child: Text('Выйти из аккаунта', style: TextStyle(color: colors.onSurfaceVariant)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class SiteRouteRedirect extends StatelessWidget {
  final String location;
  final bool isDark;
  final VoidCallback onToggleTheme;

  const SiteRouteRedirect({
    super.key,
    required this.location,
    required this.isDark,
    required this.onToggleTheme,
  });

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.mounted &&
          GoRouterState.of(context).uri.toString() != location) {
        context.go(location);
      }
    });

    return SiteLoadingScreen(isDark: isDark, onToggleTheme: onToggleTheme);
  }
}

class SiteLoadingScreen extends StatelessWidget {
  final bool isDark;
  final VoidCallback onToggleTheme;

  const SiteLoadingScreen({
    super.key,
    required this.isDark,
    required this.onToggleTheme,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _LogoMark(isDense: true),
            const SizedBox(height: 20),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}

class FirebaseSetupScreen extends StatelessWidget {
  final bool isDark;
  final VoidCallback onToggleTheme;
  final Object? error;

  const FirebaseSetupScreen({
    super.key,
    required this.isDark,
    required this.onToggleTheme,
    this.error,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Logist App Site'),
        actions: [
          ThemeIconButton(isDark: isDark, onPressed: onToggleTheme),
          const SizedBox(width: 8),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 620),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.cloud_off_rounded, size: 42, color: colors.error),
                  const SizedBox(height: 18),
                  Text(
                    'Firebase не подключен',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    error?.toString() ?? 'Не удалось инициализировать проект.',
                    style: TextStyle(color: colors.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class SiteErrorScreen extends StatelessWidget {
  final String title;
  final String message;
  final bool isDark;
  final VoidCallback onToggleTheme;

  const SiteErrorScreen({
    super.key,
    required this.title,
    required this.message,
    required this.isDark,
    required this.onToggleTheme,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Logist App Site'),
        actions: [
          ThemeIconButton(isDark: isDark, onPressed: onToggleTheme),
          const SizedBox(width: 8),
        ],
      ),
      body: Center(
        child: _StatePanel(
          icon: Icons.error_outline_rounded,
          title: title,
          message: message,
          actionLabel: 'Повторить',
          onAction: () {},
        ),
      ),
    );
  }
}

class SiteLoginScreen extends StatefulWidget {
  final bool isDark;
  final VoidCallback onToggleTheme;

  const SiteLoginScreen({
    super.key,
    required this.isDark,
    required this.onToggleTheme,
  });

  @override
  State<SiteLoginScreen> createState() => _SiteLoginScreenState();
}

class _SiteLoginScreenState extends State<SiteLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _carController = TextEditingController();
  var _isLoading = false;
  var _obscurePassword = true;
  var _isRegistering = false;
  var _selectedRole = 'carrier';

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _carController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _isLoading) return;

    setState(() => _isLoading = true);
    try {
      final user = _isRegistering
          ? await AuthRepository.instance.register(
              email: _emailController.text,
              password: _passwordController.text,
              role: _selectedRole,
              username: _usernameController.text,
              name: _nameController.text,
              car: (_selectedRole == 'carrier' || _selectedRole.contains('carrier')) ? _carController.text : null,
            )
          : await AuthRepository.instance.signIn(
              _emailController.text,
              _passwordController.text,
            );
      if (mounted) context.go(user.isAdmin ? '/admin' : '/dashboard');
    } catch (error) {
      if (!mounted) return;
      showSiteError(
        context,
        _isRegistering
            ? 'Ошибка регистрации:\n${translateAuthError(error)}'
            : 'Ошибка входа:\n${translateAuthError(error)}',
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isWide = MediaQuery.sizeOf(context).width >= 900;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1120),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: isWide
                  ? Row(
                      children: [
                        Expanded(child: _LoginPreview(isDark: widget.isDark)),
                        const SizedBox(width: 28),
                        SizedBox(width: 430, child: _buildLoginCard(colors)),
                      ],
                    )
                  : SingleChildScrollView(child: _buildLoginCard(colors)),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoginCard(ColorScheme colors) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(26),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const _LogoMark(),
                  const Spacer(),
                  ThemeIconButton(
                    isDark: widget.isDark,
                    onPressed: widget.onToggleTheme,
                  ),
                ],
              ),
              const SizedBox(height: 28),
              Text(
                _isRegistering ? 'Регистрация' : 'Вход в веб-кабинет',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Logist App',
                style: TextStyle(
                  color: colors.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 26),
              if (_isRegistering) ...[
                _RoleSelector(
                  value: _selectedRole,
                  onChanged: (value) => setState(() => _selectedRole = value),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _nameController,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Имя',
                    prefixIcon: Icon(Icons.person_outline_rounded),
                  ),
                  validator: (value) {
                    if (!_isRegistering) return null;
                    if ((value ?? '').trim().isEmpty) return 'Введите имя';
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _usernameController,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: '@username',
                    prefixIcon: Icon(Icons.alternate_email_rounded),
                    helperText: 'Латиница, цифры, точка или _',
                  ),
                  validator: (value) {
                    if (!_isRegistering) return null;
                    final text = (value ?? '').trim().replaceFirst('@', '');
                    if (text.isEmpty) return 'Введите @username';
                    if (text.length < 3) return 'Минимум 3 символа';
                    if (!RegExp(r'^[a-zA-Z0-9_.]+$').hasMatch(text)) {
                      return 'Только латиница, цифры, точка или _';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),
              ],
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.alternate_email_rounded),
                ),
                validator: (value) {
                  final text = value?.trim() ?? '';
                  if (text.isEmpty) return 'Введите email';
                  if (!text.contains('@')) return 'Проверьте email';
                  return null;
                },
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: 'Пароль',
                  prefixIcon: const Icon(Icons.lock_outline_rounded),
                  suffixIcon: IconButton(
                    tooltip:
                        _obscurePassword ? 'Показать пароль' : 'Скрыть пароль',
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_rounded
                          : Icons.visibility_off_rounded,
                    ),
                    onPressed: () {
                      setState(() => _obscurePassword = !_obscurePassword);
                    },
                  ),
                ),
                validator: (value) {
                  final text = (value ?? '').trim();
                  if (text.isEmpty) return 'Введите пароль';
                  if (_isRegistering && text.length < 6) {
                    return 'Минимум 6 символов';
                  }
                  return null;
                },
                onFieldSubmitted: (_) => _submit(),
              ),
              if (_isRegistering && (_selectedRole == 'carrier' || _selectedRole.contains('carrier'))) ...[
                const SizedBox(height: 14),
                TextFormField(
                  controller: _carController,
                  textInputAction: TextInputAction.done,
                  decoration: const InputDecoration(
                    labelText: 'Бригада / транспорт',
                    prefixIcon: Icon(Icons.local_shipping_outlined),
                  ),
                  onFieldSubmitted: (_) => _submit(),
                ),
              ],
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _isLoading ? null : _submit,
                  icon: _isLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(
                          _isRegistering
                              ? Icons.person_add_alt_1_rounded
                              : Icons.login_rounded,
                        ),
                  label: Text(
                    _isLoading
                        ? (_isRegistering ? 'Создаем...' : 'Входим...')
                        : (_isRegistering ? 'Зарегистрироваться' : 'Войти'),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Center(
                child: TextButton(
                  onPressed: _isLoading
                      ? null
                      : () {
                          setState(() {
                            _isRegistering = !_isRegistering;
                            _formKey.currentState?.reset();
                          });
                        },
                  child: Text(
                    _isRegistering
                        ? 'Уже есть аккаунт? Войти'
                        : 'Нет аккаунта? Зарегистрироваться',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoleSelector extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;

  const _RoleSelector({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: const InputDecoration(
        labelText: 'Выберите роль',
        prefixIcon: Icon(Icons.manage_accounts_rounded),
      ),
      items: const [
        DropdownMenuItem(
          value: 'carrier',
          child: Text('Перевозчик'),
        ),
        DropdownMenuItem(
          value: 'logistician',
          child: Text('Логист'),
        ),
        DropdownMenuItem(
          value: 'cargo_owner',
          child: Text('Грузовладелец'),
        ),
        DropdownMenuItem(
          value: 'forwarder',
          child: Text('Экспедитор'),
        ),
        DropdownMenuItem(
          value: 'carrier_forwarder',
          child: Text('Перевозчик-Экспедитор'),
        ),
        DropdownMenuItem(
          value: 'cargo_owner_carrier',
          child: Text('Грузовладелец-Перевозчик'),
        ),
        DropdownMenuItem(
          value: 'logistician_carrier',
          child: Text('Логист-Перевозчик'),
        ),
      ],
      onChanged: (val) {
        if (val != null) onChanged(val);
      },
    );
  }
}
