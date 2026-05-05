import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../repositories/auth_repository.dart';
import 'register_screen.dart';
import 'auth_widgets.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    // debug: print('=== НАЧАЛО ВХОДА ===');
    // debug: print('Email: ${_emailController.text}');
    // debug: print('Password: ${_passwordController.text.isNotEmpty ? '***' : 'empty'}');
    
    if (!_formKey.currentState!.validate()) {
      // debug: print('ВАЛИДАЦИЯ НЕ ПРОШЛА');
      return;
    }

    // debug: print('ВАЛИДАЦИЯ ПРОШЛА, НАЧИНАЕМ ВХОД');
    final nav = Navigator.of(context);
    setState(() => _isLoading = true);
    try {
      await AuthRepository.instance.signIn(
        _emailController.text,
        _passwordController.text,
      );
      // debug: print('ВХОД УСПЕШЕН');
      // После входа AuthWrapper сам переключит экран.
      // Но на всякий случай можно закрыть этот экран, если он был открыт не как root.
      if (nav.canPop()) nav.pop();
    } on FirebaseAuthException catch (e) {
      // debug: print('ОШИБКА FIREBASE: ${e.code} - ${e.message}');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_friendlyError(e.code)),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } catch (e) {
      // debug: print('ДРУГАЯ ОШИБКА: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка входа: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      // debug: print('ЗАВЕРШЕНИЕ ВХОДА');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _friendlyError(String code) {
    return switch (code) {
      'user-not-found' => 'Пользователь с таким email не найден',
      'wrong-password' => 'Неверный пароль',
      'invalid-email' => 'Некорректный email',
      'user-disabled' => 'Аккаунт заблокирован',
      'too-many-requests' => 'Слишком много попыток. Попробуйте позже',
      _ => 'Ошибка авторизации. Проверьте данные',
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 24),

                // Логотип / иконка
                Center(
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF3B82F6), Color(0xFF6366F1)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF3B82F6).withOpacity(0.4),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.local_shipping_rounded,
                      color: Colors.white,
                      size: 42,
                    ),
                  ),
                ),

                const SizedBox(height: 40),

                // Заголовок
                const Text(
                  'Добро пожаловать',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Войдите в свой аккаунт',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 15,
                  ),
                ),

                const SizedBox(height: 40),

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

                const SizedBox(height: 36),

                // Кнопка входа
                AuthGradientButton(
                  label: 'Войти',
                  onPressed: _login,
                  isLoading: _isLoading,
                ),

                const SizedBox(height: 28),

                // Ссылка на регистрацию
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Нет аккаунта? ',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                        fontSize: 14,
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const RegisterScreen(),
                          ),
                        );
                      },
                      child: const Text(
                        'Зарегистрироваться',
                        style: TextStyle(
                          color: Color(0xFF3B82F6),
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
