import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../repositories/auth_repository.dart';
import 'auth_widgets.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  final _nameController = TextEditingController();
  final _carController = TextEditingController();

  String _role = 'logistician';
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _emailController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    _nameController.dispose();
    _carController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    final nav = Navigator.of(
      context,
    ); // Захватываем навигатор ДО начала загрузки
    // print('UI: Register button pressed');
    setState(() => _isLoading = true);
    try {
      await AuthRepository.instance.register(
        email: _emailController.text,
        password: _passwordController.text,
        role: _role,
        username: _usernameController.text,
        name: (_role == 'carrier' || _role.contains('carrier')) ? _nameController.text : null,
        car: (_role == 'carrier' || _role.contains('carrier')) ? _carController.text : null,
      );

      // debug: print('UI: Registration finished, closing all auth screens');
      // Очищаем стек до первого экрана (AuthWrapper), который сам решит что показать
      nav.popUntil((route) => route.isFirst);
    } on FirebaseAuthException catch (e) {
      // debug: print('ОШИБКА FIREBASE: ${e.code}');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_friendlyError(e.code)),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } catch (e) {
      // debug: print('=== НАЧАЛО РЕГИСТРАЦИИ ===');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Произошла ошибка: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) {
        // print('UI: Setting isLoading to false');
        setState(() => _isLoading = false);
      }
    }
  }

  String _friendlyError(String code) {
    return switch (code) {
      'email-already-in-use' => 'Этот email уже зарегистрирован',
      'username-already-in-use' => 'Этот @username уже занят',
      'invalid-email' => 'Некорректный email',
      'weak-password' => 'Пароль слишком простой (минимум 6 символов)',
      'operation-not-allowed' => 'Регистрация временно недоступна',
      _ => 'Ошибка регистрации. Попробуйте ещё раз',
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white70,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 8),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Заголовок
                const Text(
                  'Создать аккаунт',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Заполните данные для регистрации',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 15,
                  ),
                ),

                const SizedBox(height: 32),

                // Выбор роли
                const AuthLabel('Кто вы?'),
                const SizedBox(height: 10),
                _RoleSelector(
                  selected: _role,
                  onChanged: (r) => setState(() => _role = r),
                ),

                const SizedBox(height: 24),

                const AuthLabel('@username'),
                const SizedBox(height: 8),
                AuthInputField(
                  controller: _usernameController,
                  hintText: '@logist_ivan',
                  keyboardType: TextInputType.text,
                  prefixIcon: Icons.alternate_email_rounded,
                  validator: (v) {
                    final text = (v ?? '').trim().replaceFirst('@', '');
                    if (text.isEmpty) return 'Введите @username';
                    if (text.length < 3) return 'Минимум 3 символа';
                    if (!RegExp(r'^[a-zA-Z0-9_.]+$').hasMatch(text)) {
                      return 'Только латиница, цифры, точка или _';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 20),

                // Email
                const AuthLabel('Email'),
                const SizedBox(height: 8),
                AuthInputField(
                  controller: _emailController,
                  hintText: 'example@mail.com',
                  keyboardType: TextInputType.emailAddress,
                  prefixIcon: Icons.email_outlined,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Введите email';
                    if (!v.contains('@')) return 'Некорректный email';
                    return null;
                  },
                ),

                const SizedBox(height: 20),

                // Пароль
                const AuthLabel('Пароль'),
                const SizedBox(height: 8),
                AuthInputField(
                  controller: _passwordController,
                  hintText: '••••••••',
                  obscureText: _obscurePassword,
                  prefixIcon: Icons.lock_outline_rounded,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      color: Colors.white38,
                      size: 20,
                    ),
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Введите пароль';
                    if (v.length < 6) return 'Минимум 6 символов';
                    return null;
                  },
                ),

                const SizedBox(height: 20),

                // Подтверждение пароля
                const AuthLabel('Подтвердите пароль'),
                const SizedBox(height: 8),
                AuthInputField(
                  controller: _confirmController,
                  hintText: '••••••••',
                  obscureText: _obscureConfirm,
                  prefixIcon: Icons.lock_outline_rounded,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirm
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      color: Colors.white38,
                      size: 20,
                    ),
                    onPressed: () =>
                        setState(() => _obscureConfirm = !_obscureConfirm),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Повторите пароль';
                    if (v != _passwordController.text) {
                      return 'Пароли не совпадают';
                    }
                    return null;
                  },
                ),

                // Поля только для перевозчика
                if (_role == 'carrier' || _role.contains('carrier')) ...[
                  const SizedBox(height: 20),
                  const AuthLabel('ФИО перевозчика'),
                  const SizedBox(height: 8),
                  AuthInputField(
                    controller: _nameController,
                    hintText: 'Иванов Иван Иванович',
                    prefixIcon: Icons.person_outline_rounded,
                    validator: (v) {
                      if ((_role == 'carrier' || _role.contains('carrier')) &&
                          (v == null || v.trim().isEmpty)) {
                        return 'Введите ФИО';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  const AuthLabel('Бригада / транспорт'),
                  const SizedBox(height: 8),
                  AuthInputField(
                    controller: _carController,
                    hintText: 'Volvo FH16 • А123БВ 77',
                    prefixIcon: Icons.local_shipping_outlined,
                    validator: (v) {
                      if ((_role == 'carrier' || _role.contains('carrier')) &&
                          (v == null || v.trim().isEmpty)) {
                        return 'Введите данные транспорта';
                      }
                      return null;
                    },
                  ),
                ],

                const SizedBox(height: 36),

                // Кнопка регистрации
                AuthGradientButton(
                  label: 'Создать аккаунт',
                  onPressed: _register,
                  isLoading: _isLoading,
                ),

                const SizedBox(height: 24),

                // Ссылка на вход
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Уже есть аккаунт? ',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                        fontSize: 14,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Text(
                        'Войти',
                        style: TextStyle(
                          color: Color(0xFF3B82F6),
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Role selector widget ───────────────────────────────────────────────────

class _RoleSelector extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onChanged;

  const _RoleSelector({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            _RoleTile(
              label: 'Логист',
              icon: Icons.admin_panel_settings_outlined,
              value: 'logistician',
              selected: selected,
              onTap: onChanged,
            ),
            const SizedBox(width: 12),
            _RoleTile(
              label: 'Перевозчик',
              icon: Icons.local_shipping_outlined,
              value: 'carrier',
              selected: selected,
              onTap: onChanged,
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _RoleTile(
              label: 'Грузовладелец',
              icon: Icons.business_center_outlined,
              value: 'cargo_owner',
              selected: selected,
              onTap: onChanged,
            ),
            const SizedBox(width: 12),
            _RoleTile(
              label: 'Экспедитор',
              icon: Icons.assignment_ind_outlined,
              value: 'forwarder',
              selected: selected,
              onTap: onChanged,
            ),
          ],
        ),
        const SizedBox(height: 12),
        _RoleTile(
          label: 'Перевозчик-Экспедитор',
          icon: Icons.handshake_outlined,
          value: 'carrier_forwarder',
          selected: selected,
          onTap: onChanged,
        ),
      ],
    );
  }
}

class _RoleTile extends StatelessWidget {
  final String label;
  final IconData icon;
  final String value;
  final String selected;
  final ValueChanged<String> onTap;

  const _RoleTile({
    required this.label,
    required this.icon,
    required this.value,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = value == selected;
    return Expanded(
      child: GestureDetector(
        onTap: () => onTap(value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFF3B82F6).withOpacity(0.15)
                : const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFF3B82F6)
                  : const Color(0xFF334155),
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: isSelected ? const Color(0xFF3B82F6) : Colors.white38,
                size: 28,
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? const Color(0xFF3B82F6) : Colors.white54,
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
