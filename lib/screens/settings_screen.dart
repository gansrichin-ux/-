import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/providers/app_settings_providers.dart';
import '../core/providers/auth_providers.dart';
import '../core/providers/notification_providers.dart';

const _bg = Color(0xFF0B1220);
const _surface = Color(0xFF111827);
const _outline = Color(0xFF263247);
const _mutedText = Color(0xFF94A3B8);

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _emailVerified = false;
  bool _isSendingVerification = false;
  bool _isCheckingVerification = false;

  @override
  void initState() {
    super.initState();
    _emailVerified = ref.read(authRepositoryProvider).isEmailVerified;
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider).value;
    final settings = ref.watch(appSettingsProvider);

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        title: const Text('Настройки'),
        backgroundColor: _bg,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          _AccountCard(
            name: user?.displayName ?? 'Аккаунт',
            email: user?.email ?? 'Нет email',
            role: user?.displayRole ?? 'Неизвестно',
            car: user?.car,
          ),
          const SizedBox(height: 14),
          _VerificationSection(
            email: user?.email ?? 'Нет email',
            isVerified: _emailVerified,
            isSending: _isSendingVerification,
            isChecking: _isCheckingVerification,
            onSend: _sendVerificationEmail,
            onCheck: _checkVerificationStatus,
          ),
          const SizedBox(height: 14),
          _AppSettingsSection(
            settings: settings,
            onNotificationsChanged: (value) async {
              await ref
                  .read(appSettingsProvider.notifier)
                  .setNotificationsEnabled(value);

              final uid = ref.read(currentUserProvider).value?.uid;
              if (uid == null) return;

              final notifications = ref.read(notificationServiceProvider);
              if (value) {
                await notifications.saveToken(uid);
              } else {
                await notifications.clearToken(uid);
              }
            },
            onExchangeRefreshChanged: (value) {
              ref
                  .read(appSettingsProvider.notifier)
                  .setExchangeAutoRefreshEnabled(value);
            },
          ),
          const SizedBox(height: 14),
          _SettingsTile(
            icon: Icons.logout_rounded,
            title: 'Выйти из аккаунта',
            subtitle: 'Завершить текущую сессию',
            color: const Color(0xFFEF4444),
            onTap: () async {
              await ref.read(authRepositoryProvider).signOut();
              if (context.mounted) Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  Future<void> _sendVerificationEmail() async {
    if (_isSendingVerification) return;

    setState(() => _isSendingVerification = true);
    try {
      await ref.read(authRepositoryProvider).sendEmailVerification();
      if (!mounted) return;

      _showMessage('Письмо для подтверждения отправлено на email');
    } catch (error) {
      if (!mounted) return;
      _showMessage('Не удалось отправить письмо: $error');
    } finally {
      if (mounted) {
        setState(() => _isSendingVerification = false);
      }
    }
  }

  Future<void> _checkVerificationStatus() async {
    if (_isCheckingVerification) return;

    setState(() => _isCheckingVerification = true);
    try {
      final verified = await ref
          .read(authRepositoryProvider)
          .reloadCurrentUser();
      if (!mounted) return;

      setState(() => _emailVerified = verified);
      _showMessage(
        verified ? 'Email подтвержден' : 'Email пока не подтвержден',
      );
    } catch (error) {
      if (!mounted) return;
      _showMessage('Не удалось проверить статус: $error');
    } finally {
      if (mounted) {
        setState(() => _isCheckingVerification = false);
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }
}

class _AccountCard extends StatelessWidget {
  final String name;
  final String email;
  final String role;
  final String? car;

  const _AccountCard({
    required this.name,
    required this.email,
    required this.role,
    this.car,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1D4ED8), Color(0xFF0F766E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.12)),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.14),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.18)),
            ),
            child: const Icon(
              Icons.person_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.74),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _AccountBadge(icon: Icons.badge_rounded, text: role),
                    if (car?.isNotEmpty == true)
                      _AccountBadge(
                        icon: Icons.local_shipping_rounded,
                        text: car!,
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AccountBadge extends StatelessWidget {
  final IconData icon;
  final String text;

  const _AccountBadge({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withOpacity(0.16)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _VerificationSection extends StatelessWidget {
  final String email;
  final bool isVerified;
  final bool isSending;
  final bool isChecking;
  final VoidCallback onSend;
  final VoidCallback onCheck;

  const _VerificationSection({
    required this.email,
    required this.isVerified,
    required this.isSending,
    required this.isChecking,
    required this.onSend,
    required this.onCheck,
  });

  @override
  Widget build(BuildContext context) {
    final color = isVerified
        ? const Color(0xFF22C55E)
        : const Color(0xFFF59E0B);

    return _SettingsSection(
      icon: Icons.verified_user_rounded,
      title: 'Верификация аккаунта',
      color: color,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isVerified ? 'Email подтвержден' : 'Email не подтвержден',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      email,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: _mutedText, fontSize: 13),
                    ),
                  ],
                ),
              ),
              _StatusBadge(text: isVerified ? 'Готово' : 'Нужно', color: color),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              if (!isVerified)
                FilledButton.icon(
                  onPressed: isSending ? null : onSend,
                  icon: isSending
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.mark_email_read_rounded, size: 18),
                  label: Text(isSending ? 'Отправка' : 'Отправить письмо'),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: const Color(0xFF1E293B),
                    disabledForegroundColor: _mutedText,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                  ),
                ),
              OutlinedButton.icon(
                onPressed: isChecking ? null : onCheck,
                icon: isChecking
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.refresh_rounded, size: 18),
                label: Text(isChecking ? 'Проверка' : 'Проверить статус'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: _outline),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AppSettingsSection extends StatelessWidget {
  final AppSettings settings;
  final ValueChanged<bool> onNotificationsChanged;
  final ValueChanged<bool> onExchangeRefreshChanged;

  const _AppSettingsSection({
    required this.settings,
    required this.onNotificationsChanged,
    required this.onExchangeRefreshChanged,
  });

  @override
  Widget build(BuildContext context) {
    return _SettingsSection(
      icon: Icons.tune_rounded,
      title: 'Настройки приложения',
      color: const Color(0xFF38BDF8),
      child: Column(
        children: [
          _SwitchRow(
            icon: Icons.notifications_active_rounded,
            title: 'Уведомления',
            subtitle: 'Разрешить важные уведомления приложения',
            color: const Color(0xFF38BDF8),
            value: settings.notificationsEnabled,
            onChanged: onNotificationsChanged,
          ),
          const Divider(height: 24, color: _outline),
          _SwitchRow(
            icon: Icons.currency_exchange_rounded,
            title: 'Автообновление курсов',
            subtitle: 'Обновлять валюты каждые 30 минут',
            color: const Color(0xFF22C55E),
            value: settings.exchangeAutoRefreshEnabled,
            onChanged: onExchangeRefreshChanged,
          ),
        ],
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  final Widget child;

  const _SettingsSection({
    required this.icon,
    required this.title,
    required this.color,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _SwitchRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SwitchRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(11),
          ),
          child: Icon(icon, color: color, size: 21),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: _mutedText,
                  fontSize: 12,
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Switch.adaptive(
          value: value,
          activeColor: const Color(0xFF22C55E),
          activeTrackColor: const Color(0xFF22C55E).withOpacity(0.28),
          inactiveThumbColor: _mutedText,
          inactiveTrackColor: const Color(0xFF1E293B),
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String text;
  final Color color;

  const _StatusBadge({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.28)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _outline),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: _mutedText, fontSize: 13),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: _mutedText),
            ],
          ),
        ),
      ),
    );
  }
}
