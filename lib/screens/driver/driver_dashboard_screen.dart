import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/services/delivery_report_service.dart';
import '../../core/services/document_service.dart';
import '../../models/delivery_report_model.dart';
import '../../models/document_model.dart';
import '../../models/user_model.dart';
import '../../repositories/auth_repository.dart';
import '../../repositories/cargo_repository.dart';
import '../../repositories/user_repository.dart';
import '../../models/cargo_model.dart';
import '../../core/router/app_router.dart';
import '../settings_screen.dart';

class DriverDashboardScreen extends StatelessWidget {
  const DriverDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final driverId = AuthRepository.instance.currentUser!.uid;

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Логистика'),
          actions: [
            IconButton(
              icon: const Icon(Icons.settings_rounded),
              tooltip: 'Настройки',
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              ),
            ),
          ],
          bottom: const TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: [
              Tab(icon: Icon(Icons.local_shipping_rounded), text: 'Мои грузы'),
              Tab(icon: Icon(Icons.search_rounded), text: 'Доступные'),
              Tab(icon: Icon(Icons.support_agent_rounded), text: 'Логисты'),
              Tab(icon: Icon(Icons.folder_rounded), text: 'Мои документы'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _MyCargoTab(driverId: driverId),
            _AvailableCargoTab(driverId: driverId),
            const _LogisticiansTab(),
            _MyDocumentsTab(driverId: driverId),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Tab 1 — Мои назначенные грузы
// ---------------------------------------------------------------------------

class _MyCargoTab extends StatelessWidget {
  final String driverId;
  const _MyCargoTab({required this.driverId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<CargoModel>>(
      stream: CargoRepository.instance.watchDriverCargos(driverId),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(child: Text('Ошибка загрузки'));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final cargos = snapshot.data ?? [];
        if (cargos.isEmpty) {
          return _EmptyState(
            icon: Icons.inbox_rounded,
            message: 'Нет назначенных грузов',
            subtitle: 'Перейдите в «Доступные» чтобы взять заявку',
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 12),
          itemCount: cargos.length,
          itemBuilder: (context, index) =>
              _CargoCard(cargo: cargos[index], showStatusMenu: true),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Tab 2 — Доступные (свободные) грузы
// ---------------------------------------------------------------------------

class _AvailableCargoTab extends StatelessWidget {
  final String driverId;
  const _AvailableCargoTab({required this.driverId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<CargoModel>>(
      stream: CargoRepository.instance.watchAvailableCargos(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(child: Text('Ошибка загрузки'));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final cargos = snapshot.data ?? [];
        if (cargos.isEmpty) {
          return _EmptyState(
            icon: Icons.check_circle_rounded,
            message: 'Свободных грузов нет',
            subtitle: 'Все заявки уже разобраны',
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 12),
          itemCount: cargos.length,
          itemBuilder: (context, index) => _CargoCard(
            cargo: cargos[index],
            showStatusMenu: false,
            onTakePressed: () => _takeOrder(context, cargos[index], driverId),
          ),
        );
      },
    );
  }

  Future<void> _takeOrder(
    BuildContext context,
    CargoModel cargo,
    String driverId,
  ) async {
    final user = await AuthRepository.instance.getCurrentUserModel();
    if (user == null) return;

    await CargoRepository.instance.assignDriver(
      cargoId: cargo.id,
      driverId: driverId,
      driverName: user.displayName,
    );

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Груз «${cargo.title}» принят!'),
          backgroundColor: const Color(0xFF22C55E),
        ),
      );
    }
  }
}

// ---------------------------------------------------------------------------
// Tab 3 — Логисты
// ---------------------------------------------------------------------------

class _LogisticiansTab extends StatelessWidget {
  const _LogisticiansTab();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<UserModel>>(
      stream: UserRepository.instance.watchLogisticians(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(child: Text('Ошибка загрузки логистов'));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final logisticians = [...snapshot.data ?? <UserModel>[]]
          ..sort((a, b) => a.displayName.compareTo(b.displayName));

        if (logisticians.isEmpty) {
          return _EmptyState(
            icon: Icons.support_agent_rounded,
            message: 'Логистов пока нет',
            subtitle: 'Когда логисты появятся в системе, они будут здесь',
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 12),
          itemCount: logisticians.length,
          itemBuilder: (context, index) =>
              _LogisticianCard(user: logisticians[index]),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Tab 4 — Мои документы
// ---------------------------------------------------------------------------

class _MyDocumentsTab extends StatelessWidget {
  final String driverId;

  const _MyDocumentsTab({required this.driverId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<DocumentModel>>(
      stream: DocumentService.instance.watchDocumentsByUploader(driverId),
      builder: (context, documentsSnapshot) {
        if (documentsSnapshot.hasError) {
          return const Center(child: Text('Ошибка загрузки документов'));
        }

        return StreamBuilder<List<DeliveryReportModel>>(
          stream: DeliveryReportService.instance.watchReportsByDriver(driverId),
          builder: (context, reportsSnapshot) {
            if (reportsSnapshot.hasError) {
              return const Center(child: Text('Ошибка загрузки отчётов'));
            }

            final loading =
                documentsSnapshot.connectionState == ConnectionState.waiting ||
                reportsSnapshot.connectionState == ConnectionState.waiting;

            if (loading) {
              return const Center(child: CircularProgressIndicator());
            }

            final documents = documentsSnapshot.data ?? [];
            final reports = reportsSnapshot.data ?? [];

            if (documents.isEmpty && reports.isEmpty) {
              return _EmptyState(
                icon: Icons.folder_open_rounded,
                message: 'Документов пока нет',
                subtitle: 'Загруженные файлы и отчёты доставки появятся здесь',
              );
            }

            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
              children: [
                if (documents.isNotEmpty) ...[
                  _SectionTitle(title: 'Файлы', count: documents.length),
                  const SizedBox(height: 8),
                  ...documents.map(
                    (document) => _DocumentCard(document: document),
                  ),
                  const SizedBox(height: 10),
                ],
                if (reports.isNotEmpty) ...[
                  _SectionTitle(
                    title: 'Отчёты доставки',
                    count: reports.length,
                  ),
                  const SizedBox(height: 8),
                  ...reports.map(
                    (report) => _DeliveryReportCard(report: report),
                  ),
                ],
              ],
            );
          },
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Shared widgets
// ---------------------------------------------------------------------------

class _LogisticianCard extends StatelessWidget {
  final UserModel user;

  const _LogisticianCard({required this.user});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: const Color(0xFF3B82F6).withOpacity(0.14),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.support_agent_rounded,
                color: Color(0xFF3B82F6),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user.email,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF22C55E).withOpacity(0.12),
                borderRadius: BorderRadius.circular(999),
              ),
              child: const Text(
                'Логист',
                style: TextStyle(
                  color: Color(0xFF22C55E),
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DocumentCard extends StatelessWidget {
  final DocumentModel document;

  const _DocumentCard({required this.document});

  @override
  Widget build(BuildContext context) {
    final type = document.documentType;
    final color = type.color;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: color.withOpacity(0.14),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(_documentIcon(type), color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    document.title.isNotEmpty
                        ? document.title
                        : document.fileName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      _MetaChip(text: type.displayName, color: color),
                      _MetaChip(
                        text: document.fileSizeFormatted,
                        color: const Color(0xFF64748B),
                      ),
                      _MetaChip(
                        text: _formatDate(document.createdAt),
                        color: const Color(0xFF64748B),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (document.fileUrl.isNotEmpty)
              IconButton(
                tooltip: 'Скопировать ссылку',
                onPressed: () async {
                  await Clipboard.setData(
                    ClipboardData(text: document.fileUrl),
                  );
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Ссылка скопирована')),
                    );
                  }
                },
                icon: const Icon(Icons.link_rounded),
              ),
          ],
        ),
      ),
    );
  }
}

class _DeliveryReportCard extends StatelessWidget {
  final DeliveryReportModel report;

  const _DeliveryReportCard({required this.report});

  @override
  Widget build(BuildContext context) {
    final color = _deliveryStatusColor(report.status);

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => AppRouter.toCargoDetails(context, report.cargoId),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.14),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: Icon(
                      Icons.assignment_turned_in_rounded,
                      color: color,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Отчёт по грузу ${_shortId(report.cargoId)}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formatDate(report.createdAt),
                          style: const TextStyle(
                            color: Color(0xFF94A3B8),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _MetaChip(text: report.status.displayName, color: color),
                ],
              ),
              if (report.notes?.isNotEmpty == true) ...[
                const SizedBox(height: 12),
                Text(
                  report.notes!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFFCBD5E1),
                    fontSize: 13,
                    height: 1.35,
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  _MetaChip(
                    text: '${report.photos.length} фото',
                    color: const Color(0xFF8B5CF6),
                  ),
                  if (report.signatureBase64?.isNotEmpty == true)
                    _MetaChip(
                      text: 'Подпись есть',
                      color: const Color(0xFF22C55E),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final int count;

  const _SectionTitle({required this.title, required this.count});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(width: 8),
        _MetaChip(text: '$count', color: const Color(0xFF3B82F6)),
      ],
    );
  }
}

class _MetaChip extends StatelessWidget {
  final String text;
  final Color color;

  const _MetaChip({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _CargoCard extends StatelessWidget {
  final CargoModel cargo;
  final bool showStatusMenu;
  final VoidCallback? onTakePressed;

  const _CargoCard({
    required this.cargo,
    required this.showStatusMenu,
    this.onTakePressed,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = switch (cargo.status) {
      'Доставлен' => const Color(0xFF22C55E),
      'В пути' => const Color(0xFFF59E0B),
      _ => const Color(0xFF3B82F6),
    };

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => AppRouter.toCargoDetails(context, cargo.id),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      cargo.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      cargo.status,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              _RouteRow(from: cargo.from, to: cargo.to),
              if (showStatusMenu) ...[
                const SizedBox(height: 12),
                _StatusMenuRow(cargo: cargo),
              ],
              if (onTakePressed != null) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: onTakePressed,
                    child: const Text('Взять груз'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _RouteRow extends StatelessWidget {
  final String from;
  final String to;
  const _RouteRow({required this.from, required this.to});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.circle, size: 8, color: Color(0xFF3B82F6)),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            from,
            style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 8),
        const Icon(
          Icons.arrow_forward_rounded,
          size: 14,
          color: Color(0xFF64748B),
        ),
        const SizedBox(width: 8),
        const Icon(Icons.circle, size: 8, color: Color(0xFFF59E0B)),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            to,
            style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _StatusMenuRow extends StatelessWidget {
  final CargoModel cargo;
  const _StatusMenuRow({required this.cargo});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Text(
          'Обновить статус:',
          style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
        ),
        const Spacer(),
        PopupMenuButton<String>(
          color: const Color(0xFF1E293B),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          onSelected: (status) =>
              CargoRepository.instance.updateStatus(cargo.id, status),
          itemBuilder: (_) => const [
            PopupMenuItem(value: 'В пути', child: Text('🚛  В пути')),
            PopupMenuItem(value: 'Доставлен', child: Text('✅  Доставлен')),
          ],
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF334155),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              children: [
                Text(
                  'Изменить',
                  style: TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                ),
                SizedBox(width: 4),
                Icon(
                  Icons.expand_more_rounded,
                  size: 16,
                  color: Color(0xFF64748B),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

IconData _documentIcon(DocumentType type) {
  return switch (type) {
    DocumentType.pdf => Icons.picture_as_pdf_rounded,
    DocumentType.word => Icons.description_rounded,
    DocumentType.excel => Icons.table_chart_rounded,
    DocumentType.powerpoint => Icons.slideshow_rounded,
    DocumentType.image => Icons.image_rounded,
    DocumentType.text => Icons.text_snippet_rounded,
    DocumentType.other => Icons.insert_drive_file_rounded,
  };
}

Color _deliveryStatusColor(DeliveryStatus status) {
  return switch (status) {
    DeliveryStatus.pending => const Color(0xFFF59E0B),
    DeliveryStatus.confirmed => const Color(0xFF22C55E),
    DeliveryStatus.rejected => const Color(0xFFEF4444),
  };
}

String _formatDate(DateTime date) {
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  final year = date.year.toString();
  return '$day.$month.$year';
}

String _shortId(String id) {
  if (id.length <= 6) return '#$id';
  return '#${id.substring(0, 6)}';
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  final String subtitle;
  const _EmptyState({
    required this.icon,
    required this.message,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 64, color: const Color(0xFF334155)),
            const SizedBox(height: 16),
            Text(
              message,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF94A3B8),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
