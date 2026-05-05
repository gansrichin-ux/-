part of '../../main_site.dart';

class SiteLandingPage extends StatelessWidget {
  final bool isDark;
  final VoidCallback onToggleTheme;

  const SiteLandingPage({
    super.key,
    required this.isDark,
    required this.onToggleTheme,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final size = MediaQuery.sizeOf(context);
    final isWide = size.width >= 900;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const _LogoMark(isDense: true),
            const SizedBox(width: 10),
            Text(
              'Logist App',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
            ),
          ],
        ),
        actions: [
          ThemeIconButton(isDark: isDark, onPressed: onToggleTheme),
          const SizedBox(width: 10),
          FilledButton.icon(
            onPressed: () => context.go('/auth'),
            icon: const Icon(Icons.login_rounded),
            label: const Text('Войти / Регистрация'),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: SingleChildScrollView(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1200),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Hero Section
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(40),
                    decoration: BoxDecoration(
                      color: colors.primaryContainer.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(24),
                      border:
                          Border.all(color: colors.primary.withOpacity(0.1)),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Грузоперевозки и поиск машин',
                          textAlign: TextAlign.center,
                          style: Theme.of(context)
                              .textTheme
                              .displaySmall
                              ?.copyWith(
                                fontWeight: FontWeight.w900,
                                color: colors.primary,
                              ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Удобный инструмент для логистов и водителей. Управляйте грузами, находите исполнителей и общайтесь в реальном времени.',
                          textAlign: TextAlign.center,
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
                                    color: colors.onSurfaceVariant,
                                    fontWeight: FontWeight.w500,
                                  ),
                        ),
                        const SizedBox(height: 32),
                        FilledButton.icon(
                          onPressed: () => context.go('/auth'),
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 32, vertical: 20),
                          ),
                          icon: const Icon(Icons.rocket_launch_rounded),
                          label: const Text(
                            'Начать работу',
                            style: TextStyle(fontSize: 18),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 60),

                  // Info Section (like fa-fa.kz)
                  Text(
                    'Преимущества системы Logist App',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 24),

                  isWide
                      ? _buildWideFeatures(context)
                      : _buildNarrowFeatures(context),

                  const SizedBox(height: 60),

                  _buildHowItWorks(context, isWide),

                  const SizedBox(height: 60),

                  _buildLiveMarketPreview(context, isWide),

                  const SizedBox(height: 60),

                  // Bottom CTA
                  Card(
                    color: colors.secondaryContainer,
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Готовы начать?',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleLarge
                                      ?.copyWith(
                                        fontWeight: FontWeight.w800,
                                        color: colors.onSecondaryContainer,
                                      ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Регистрация занимает меньше минуты.',
                                  style: TextStyle(
                                      color: colors.onSecondaryContainer),
                                ),
                              ],
                            ),
                          ),
                          FilledButton.tonal(
                            onPressed: () => context.go('/auth'),
                            child: const Text('Перейти к регистрации'),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWideFeatures(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
            child: _buildFeatureCard(
                context,
                Icons.speed_rounded,
                'Быстрый поиск',
                'На нашем ресурсе легко подобрать нужный транспорт или груз для транспортировки. Огромная база предложений обновляется в реальном времени.')),
        const SizedBox(width: 24),
        Expanded(
            child: _buildFeatureCard(
                context,
                Icons.savings_rounded,
                'Экономия средств',
                'Ресурс позволяет компаниям, отправляющим грузы, экономить на грузоперевозках до 50% средств за счет прямого контакта с водителями.')),
        const SizedBox(width: 24),
        Expanded(
            child: _buildFeatureCard(
                context,
                Icons.money_off_rounded,
                'Бесплатный доступ',
                'Вся информация предоставляется бесплатно. Интернет ресурс не предусматривает никаких скрытых платежей за регистрацию.')),
      ],
    );
  }

  Widget _buildNarrowFeatures(BuildContext context) {
    return Column(
      children: [
        _buildFeatureCard(context, Icons.speed_rounded, 'Быстрый поиск',
            'На нашем ресурсе легко подобрать нужный транспорт или груз для транспортировки. Огромная база предложений обновляется в реальном времени.'),
        const SizedBox(height: 16),
        _buildFeatureCard(context, Icons.savings_rounded, 'Экономия средств',
            'Ресурс позволяет компаниям, отправляющим грузы, экономить на грузоперевозках до 50% средств за счет прямого контакта с водителями.'),
        const SizedBox(height: 16),
        _buildFeatureCard(context, Icons.money_off_rounded, 'Бесплатный доступ',
            'Вся информация предоставляется бесплатно. Интернет ресурс не предусматривает никаких скрытых платежей за регистрацию.'),
      ],
    );
  }

  Widget _buildFeatureCard(
      BuildContext context, IconData icon, String title, String description) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colors.outlineVariant.withOpacity(0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: colors.primary, size: 28),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: TextStyle(
                color: colors.onSurfaceVariant,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHowItWorks(BuildContext context, bool isWide) {
    final steps = [
      _buildStepCard(
        context,
        Icons.add_box_outlined,
        '1. Создайте груз',
        'Логист указывает маршрут, тоннаж, тип кузова, дату, цену и прикрепляет документы.',
      ),
      _buildStepCard(
        context,
        Icons.how_to_reg_outlined,
        '2. Получите отклики',
        'Водители и водители откликаются на заявку, а логист выбирает подходящего исполнителя.',
      ),
      _buildStepCard(
        context,
        Icons.forum_outlined,
        '3. Закройте работу',
        'Участники общаются в чате, меняют статусы рейса и оценивают друг друга после завершения.',
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Как работает площадка',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
        ),
        const SizedBox(height: 24),
        isWide
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final step in steps) ...[
                    Expanded(child: step),
                    if (step != steps.last) const SizedBox(width: 24),
                  ],
                ],
              )
            : Column(
                children: [
                  for (final step in steps) ...[
                    step,
                    if (step != steps.last) const SizedBox(height: 16),
                  ],
                ],
              ),
      ],
    );
  }

  Widget _buildLiveMarketPreview(BuildContext context, bool isWide) {
    return StreamBuilder<List<CargoModel>>(
      stream: CargoRepository.instance.watchAllCargos(),
      builder: (context, snapshot) {
        final cargos = snapshot.data ?? const <CargoModel>[];
        final stats = CargoStatsView(cargos);
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: isWide
                ? Row(
                    children: [
                      Expanded(child: _buildMarketText(context, stats)),
                      const SizedBox(width: 28),
                      Expanded(child: _buildMarketMetrics(context, stats)),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildMarketText(context, stats),
                      const SizedBox(height: 20),
                      _buildMarketMetrics(context, stats),
                    ],
                  ),
          ),
        );
      },
    );
  }

  Widget _buildMarketText(BuildContext context, CargoStatsView stats) {
    final colors = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Живая биржа грузов',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w900,
              ),
        ),
        const SizedBox(height: 10),
        Text(
          'На главном экране можно понять, что это не просто кабинет: здесь есть отклики, статусы сделок, документы, уведомления, история действий и пользовательская репутация.',
          style: TextStyle(
            color: colors.onSurfaceVariant,
            height: 1.5,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildMarketMetrics(BuildContext context, CargoStatsView stats) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        _buildMetricPill(context, Icons.inventory_2_outlined, 'Грузов',
            stats.total.toString()),
        _buildMetricPill(context, Icons.local_shipping_outlined, 'В работе',
            stats.active.toString()),
        _buildMetricPill(context, Icons.task_alt_outlined, 'Закрыто',
            stats.closed.toString()),
        _buildMetricPill(context, Icons.payments_outlined, 'Оборот',
            _formatMoney(stats.revenue)),
      ],
    );
  }

  Widget _buildMetricPill(
    BuildContext context,
    IconData icon,
    String label,
    String value,
  ) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      width: 150,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.primary.withOpacity(0.16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: colors.primary),
          const SizedBox(height: 10),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
          Text(
            value,
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }

  Widget _buildStepCard(
    BuildContext context,
    IconData icon,
    String title,
    String description,
  ) {
    return _buildFeatureCard(context, icon, title, description);
  }
}
