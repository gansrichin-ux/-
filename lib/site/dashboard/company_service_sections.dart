part of '../../main_site.dart';

class CompanySection extends StatefulWidget {
  final UserModel user;
  final List<UserModel> users;
  final List<CargoModel> cargos;
  final VoidCallback onOpenProfile;
  final VoidCallback onOpenChats;

  const CompanySection({
    super.key,
    required this.user,
    required this.users,
    required this.cargos,
    required this.onOpenProfile,
    required this.onOpenChats,
  });

  @override
  State<CompanySection> createState() => _CompanySectionState();
}

class _CompanySectionState extends State<CompanySection> {
  final _nameController = TextEditingController();
  final _typeController = TextEditingController();
  final _binController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _descriptionController = TextEditingController();

  bool _loadedInitial = false;
  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _typeController.dispose();
    _binController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _hydrate(Map<String, dynamic>? data) {
    if (_loadedInitial) return;
    _loadedInitial = true;
    _nameController.text =
        data?['organizationName'] as String? ?? widget.user.displayName;
    _typeController.text = data?['businessType'] as String? ??
        (widget.user.isCarrier ? 'Перевозчик' : 'Логистика');
    _binController.text = data?['bin'] as String? ?? '';
    _phoneController.text = data?['phone'] as String? ?? '';
    _addressController.text = data?['address'] as String? ?? '';
    _descriptionController.text = data?['description'] as String? ?? '';
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    try {
      await SiteWorkflowRepository.instance.saveCompanyProfile(
        user: widget.user,
        organizationName: _nameController.text,
        businessType: _typeController.text,
        bin: _binController.text,
        phone: _phoneController.text,
        address: _addressController.text,
        description: _descriptionController.text,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Данные компании сохранены')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Не удалось сохранить компанию: $error')),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ownCargos = widget.cargos;
    final employees = widget.users
        .where((user) => user.uid == widget.user.uid)
        .toList(growable: false);

    return StreamBuilder<Map<String, dynamic>?>(
      stream:
          SiteWorkflowRepository.instance.watchCompanyProfile(widget.user.uid),
      builder: (context, snapshot) {
        if (!_loadedInitial &&
            (snapshot.hasData ||
                snapshot.connectionState != ConnectionState.waiting)) {
          _hydrate(snapshot.data);
        }

        return ListView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 96),
          children: [
            const _WorkflowHeader(
              icon: Icons.business_outlined,
              title: 'Моя компания',
              subtitle:
                  'Профиль организации, контакты, рабочие показатели и быстрые действия по аккаунту.',
            ),
            const SizedBox(height: 16),
            LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxWidth < 900;
                final form = _CompanyProfileForm(
                  nameController: _nameController,
                  typeController: _typeController,
                  binController: _binController,
                  phoneController: _phoneController,
                  addressController: _addressController,
                  descriptionController: _descriptionController,
                  isSaving: _isSaving,
                  onSave: _save,
                );
                final side = _CompanySidePanel(
                  user: widget.user,
                  employees: employees,
                  cargos: ownCargos,
                  onOpenProfile: widget.onOpenProfile,
                  onOpenChats: widget.onOpenChats,
                );

                if (compact) {
                  return Column(
                    children: [
                      form,
                      const SizedBox(height: 16),
                      side,
                    ],
                  );
                }

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 7, child: form),
                    const SizedBox(width: 16),
                    Expanded(flex: 5, child: side),
                  ],
                );
              },
            ),
          ],
        );
      },
    );
  }
}

class _CompanyProfileForm extends StatelessWidget {
  final TextEditingController nameController;
  final TextEditingController typeController;
  final TextEditingController binController;
  final TextEditingController phoneController;
  final TextEditingController addressController;
  final TextEditingController descriptionController;
  final bool isSaving;
  final VoidCallback onSave;

  const _CompanyProfileForm({
    required this.nameController,
    required this.typeController,
    required this.binController,
    required this.phoneController,
    required this.addressController,
    required this.descriptionController,
    required this.isSaving,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _PanelHeader(
            icon: Icons.edit_note_rounded,
            title: 'Карточка организации',
          ),
          const SizedBox(height: 18),
          _ResponsivePair(
            first: AppTextField(
              label: 'Название',
              controller: nameController,
            ),
            second: AppTextField(
              label: 'Основная деятельность',
              controller: typeController,
            ),
          ),
          const SizedBox(height: 14),
          _ResponsivePair(
            first: AppTextField(
              label: 'БИН / ИИН',
              controller: binController,
              keyboardType: TextInputType.number,
            ),
            second: AppTextField(
              label: 'Телефон',
              controller: phoneController,
              keyboardType: TextInputType.phone,
            ),
          ),
          const SizedBox(height: 14),
          AppTextField(
            label: 'Адрес',
            controller: addressController,
          ),
          const SizedBox(height: 14),
          AppTextField(
            label: 'Описание',
            controller: descriptionController,
            minLines: 3,
            maxLines: 5,
          ),
          const SizedBox(height: 18),
          Align(
            alignment: Alignment.centerRight,
            child: AppButton(
              label: isSaving ? 'Сохранение...' : 'Сохранить',
              icon: Icons.save_outlined,
              isLoading: isSaving,
              onPressed: isSaving ? null : onSave,
            ),
          ),
        ],
      ),
    );
  }
}

class _CompanySidePanel extends StatelessWidget {
  final UserModel user;
  final List<UserModel> employees;
  final List<CargoModel> cargos;
  final VoidCallback onOpenProfile;
  final VoidCallback onOpenChats;

  const _CompanySidePanel({
    required this.user,
    required this.employees,
    required this.cargos,
    required this.onOpenProfile,
    required this.onOpenChats,
  });

  @override
  Widget build(BuildContext context) {
    final active = cargos.where((cargo) => cargo.isActive).length;
    return Column(
      children: [
        AppCard(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _PanelHeader(
                icon: Icons.analytics_outlined,
                title: 'Показатели',
              ),
              const SizedBox(height: 16),
              _CompanyMetric(label: 'Сотрудники', value: employees.length),
              _CompanyMetric(label: 'Мои грузы', value: cargos.length),
              _CompanyMetric(label: 'Активные рейсы', value: active),
              const SizedBox(height: 16),
              _UserBadge(
                user: user,
                color: Theme.of(context).colorScheme.primary,
                onTap: onOpenProfile,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        AppCard(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const _PanelHeader(
                icon: Icons.task_alt_outlined,
                title: 'Быстрые действия',
              ),
              const SizedBox(height: 14),
              AppButton(
                label: 'Открыть профиль',
                icon: Icons.account_circle_outlined,
                onPressed: onOpenProfile,
                variant: AppButtonVariant.secondary,
              ),
              const SizedBox(height: 10),
              AppButton(
                label: 'Открыть чаты',
                icon: Icons.forum_outlined,
                onPressed: onOpenChats,
                variant: AppButtonVariant.secondary,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CompanyMetric extends StatelessWidget {
  final String label;
  final int value;

  const _CompanyMetric({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Text(
            value.toString(),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
          ),
        ],
      ),
    );
  }
}

class ServiceRequestSection extends StatefulWidget {
  final UserModel user;
  final String type;
  final String title;
  final String subtitle;
  final IconData icon;
  final String subjectLabel;
  final String messageLabel;
  final bool showRouteFields;
  final bool showAmountField;

  const ServiceRequestSection({
    super.key,
    required this.user,
    required this.type,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.subjectLabel,
    required this.messageLabel,
    this.showRouteFields = false,
    this.showAmountField = false,
  });

  @override
  State<ServiceRequestSection> createState() => _ServiceRequestSectionState();
}

class _ServiceRequestSectionState extends State<ServiceRequestSection> {
  final _subjectController = TextEditingController();
  final _messageController = TextEditingController();
  final _fromController = TextEditingController();
  final _toController = TextEditingController();
  final _amountController = TextEditingController();
  bool _isSending = false;

  @override
  void dispose() {
    _subjectController.dispose();
    _messageController.dispose();
    _fromController.dispose();
    _toController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final subject = _subjectController.text.trim();
    final message = _messageController.text.trim();
    if (subject.isEmpty || message.isEmpty || _isSending) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Заполните тему и описание')),
      );
      return;
    }

    setState(() => _isSending = true);
    try {
      await SiteWorkflowRepository.instance.createServiceRequest(
        user: widget.user,
        type: widget.type,
        title: subject,
        message: message,
        metadata: {
          if (_fromController.text.trim().isNotEmpty)
            'from': _fromController.text.trim(),
          if (_toController.text.trim().isNotEmpty)
            'to': _toController.text.trim(),
          if (_amountController.text.trim().isNotEmpty)
            'amount': _amountController.text.trim(),
        },
      );
      if (!mounted) return;
      _subjectController.clear();
      _messageController.clear();
      _fromController.clear();
      _toController.clear();
      _amountController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Заявка отправлена')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Не удалось отправить заявку: $error')),
      );
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 96),
      children: [
        _WorkflowHeader(
          icon: widget.icon,
          title: widget.title,
          subtitle: widget.subtitle,
        ),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 900;
            final form = _ServiceRequestForm(
              subjectController: _subjectController,
              messageController: _messageController,
              fromController: _fromController,
              toController: _toController,
              amountController: _amountController,
              subjectLabel: widget.subjectLabel,
              messageLabel: widget.messageLabel,
              showRouteFields: widget.showRouteFields,
              showAmountField: widget.showAmountField,
              isSending: _isSending,
              onSubmit: _submit,
            );
            final history = _ServiceRequestHistory(
              user: widget.user,
              type: widget.type,
            );

            if (compact) {
              return Column(
                children: [
                  form,
                  const SizedBox(height: 16),
                  history,
                ],
              );
            }

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 7, child: form),
                const SizedBox(width: 16),
                Expanded(flex: 5, child: history),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _ServiceRequestForm extends StatelessWidget {
  final TextEditingController subjectController;
  final TextEditingController messageController;
  final TextEditingController fromController;
  final TextEditingController toController;
  final TextEditingController amountController;
  final String subjectLabel;
  final String messageLabel;
  final bool showRouteFields;
  final bool showAmountField;
  final bool isSending;
  final VoidCallback onSubmit;

  const _ServiceRequestForm({
    required this.subjectController,
    required this.messageController,
    required this.fromController,
    required this.toController,
    required this.amountController,
    required this.subjectLabel,
    required this.messageLabel,
    required this.showRouteFields,
    required this.showAmountField,
    required this.isSending,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _PanelHeader(
            icon: Icons.playlist_add_check_rounded,
            title: 'Новая заявка',
          ),
          const SizedBox(height: 18),
          AppTextField(
            label: subjectLabel,
            controller: subjectController,
          ),
          if (showRouteFields) ...[
            const SizedBox(height: 14),
            _ResponsivePair(
              first: AppTextField(
                label: 'Откуда',
                controller: fromController,
              ),
              second: AppTextField(
                label: 'Куда',
                controller: toController,
              ),
            ),
          ],
          if (showAmountField) ...[
            const SizedBox(height: 14),
            AppTextField(
              label: 'Стоимость груза',
              controller: amountController,
              keyboardType: TextInputType.number,
            ),
          ],
          const SizedBox(height: 14),
          AppTextField(
            label: messageLabel,
            controller: messageController,
            minLines: 4,
            maxLines: 7,
          ),
          const SizedBox(height: 18),
          Align(
            alignment: Alignment.centerRight,
            child: AppButton(
              label: isSending ? 'Отправка...' : 'Отправить',
              icon: Icons.send_outlined,
              isLoading: isSending,
              onPressed: isSending ? null : onSubmit,
            ),
          ),
        ],
      ),
    );
  }
}

class _ResponsivePair extends StatelessWidget {
  final Widget first;
  final Widget second;

  const _ResponsivePair({required this.first, required this.second});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 560) {
          return Column(
            children: [
              first,
              const SizedBox(height: 14),
              second,
            ],
          );
        }

        return Row(
          children: [
            Expanded(child: first),
            const SizedBox(width: 14),
            Expanded(child: second),
          ],
        );
      },
    );
  }
}

class _ServiceRequestHistory extends StatelessWidget {
  final UserModel user;
  final String type;

  const _ServiceRequestHistory({required this.user, required this.type});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(20),
      child: StreamBuilder<List<ServiceRequestModel>>(
        stream: SiteWorkflowRepository.instance.watchServiceRequests(
          user.uid,
          type: type,
        ),
        builder: (context, snapshot) {
          final items = snapshot.data ?? const <ServiceRequestModel>[];
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _PanelHeader(
                icon: Icons.history_rounded,
                title: 'История обращений',
              ),
              const SizedBox(height: 16),
              if (snapshot.connectionState == ConnectionState.waiting &&
                  !snapshot.hasData)
                const Center(child: CircularProgressIndicator())
              else if (items.isEmpty)
                const _StatePanel(
                  icon: Icons.inbox_outlined,
                  title: 'Заявок пока нет',
                  message: 'После отправки обращения оно появится здесь.',
                )
              else
                ...items.map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _ServiceRequestTile(item: item),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _ServiceRequestTile extends StatelessWidget {
  final ServiceRequestModel item;

  const _ServiceRequestTile({required this.item});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final resolved = item.status == 'closed' || item.status == 'resolved';
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            resolved ? Icons.task_alt_rounded : Icons.pending_actions_outlined,
            color: resolved ? const Color(0xFF16A34A) : colors.primary,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 4),
                Text(
                  item.message,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colors.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  DateFormat('dd.MM.yyyy HH:mm').format(item.createdAt),
                  style: TextStyle(
                    color: colors.onSurfaceVariant,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
