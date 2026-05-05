import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geocoding/geocoding.dart';
import '../repositories/cargo_repository.dart';
import '../models/cargo_model.dart';
import '../core/router/app_router.dart';

class CargoDetailsScreen extends StatefulWidget {
  final String cargoId;
  const CargoDetailsScreen({super.key, required this.cargoId});

  @override
  State<CargoDetailsScreen> createState() => _CargoDetailsScreenState();
}

class _CargoDetailsScreenState extends State<CargoDetailsScreen> {
  final ImagePicker _picker = ImagePicker();

  bool _isUploading = false;
  bool _isMapLoading = true;
  bool _mapError = false;

  LatLng? _fromPoint;
  LatLng? _toPoint;

  static const _bg = Color(0xFF0F172A);

  @override
  void initState() {
    super.initState();
    _initMap();
  }

  Future<void> _initMap() async {
    try {
      final cargo = await CargoRepository.instance.getCargo(widget.cargoId);
      if (cargo == null) return;
      await _resolveCoordinates(cargo.from, cargo.to);
    } catch (_) {
      if (mounted) setState(() => _mapError = true);
    } finally {
      if (mounted) setState(() => _isMapLoading = false);
    }
  }

  Future<void> _resolveCoordinates(String from, String to) async {
    if (from.isEmpty || to.isEmpty) {
      setState(() => _mapError = true);
      return;
    }
    try {
      final fromLocs = await locationFromAddress(from);
      final toLocs = await locationFromAddress(to);
      if (fromLocs.isNotEmpty && toLocs.isNotEmpty) {
        _fromPoint = LatLng(fromLocs.first.latitude, fromLocs.first.longitude);
        _toPoint = LatLng(toLocs.first.latitude, toLocs.first.longitude);
      } else {
        _mapError = true;
      }
    } catch (_) {
      _mapError = true;
    }
  }

  Future<void> _uploadPhoto() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.camera);
    if (image == null) return;
    setState(() => _isUploading = true);
    try {
      final file = File(image.path);
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${image.name}';
      final url = await CargoRepository.instance.uploadPhoto(
        widget.cargoId,
        file,
        fileName,
      );
      await CargoRepository.instance.addPhotoUrl(widget.cargoId, url);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Фото добавлено!')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Ошибка: $e')));
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: StreamBuilder<CargoModel?>(
        stream: CargoRepository.instance.watchCargo(widget.cargoId),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Ошибка загрузки'));
          }
          if (!snapshot.hasData &&
              snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final cargo = snapshot.data;
          if (cargo == null) {
            return const Center(child: Text('Груз не найден'));
          }

          return CustomScrollView(
            slivers: [
              _buildSliverAppBar(cargo),
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // Info card
                    _InfoCard(cargo: cargo),
                    const SizedBox(height: 12),

                    // Chat button
                    _ChatButton(
                      onTap: () => AppRouter.toChat(context, widget.cargoId),
                    ),
                    const SizedBox(height: 20),

                    // Map section
                    _SectionHeader(
                      icon: Icons.map_rounded,
                      title: 'Маршрут на карте',
                    ),
                    const SizedBox(height: 12),
                    _MapWidget(
                      isLoading: _isMapLoading,
                      hasError: _mapError,
                      fromPoint: _fromPoint,
                      toPoint: _toPoint,
                      fromLabel: cargo.from,
                      toLabel: cargo.to,
                    ),
                    const SizedBox(height: 20),

                    // Photos section
                    _SectionHeader(
                      icon: Icons.photo_library_rounded,
                      title: 'Документы и фото',
                    ),
                    const SizedBox(height: 12),
                    _PhotosSection(
                      photos: cargo.photos,
                      isUploading: _isUploading,
                      onUpload: _uploadPhoto,
                    ),
                    const SizedBox(height: 32),
                  ]),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSliverAppBar(CargoModel cargo) {
    final statusColor = switch (cargo.status) {
      'Доставлен' => const Color(0xFF22C55E),
      'В пути' => const Color(0xFFF59E0B),
      _ => const Color(0xFF3B82F6),
    };

    return SliverAppBar(
      backgroundColor: _bg,
      expandedHeight: 140,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        title: Row(
          children: [
            Expanded(
              child: Text(
                cargo.title,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: statusColor.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Text(
                cargo.status,
                style: TextStyle(
                  color: statusColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF1E3A5F), Color(0xFF0F172A)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Sub-widgets
// ---------------------------------------------------------------------------

class _InfoCard extends StatelessWidget {
  final CargoModel cargo;
  const _InfoCard({required this.cargo});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF334155), width: 1),
      ),
      child: Column(
        children: [
          _RouteRow(from: cargo.from, to: cargo.to),
          if (cargo.driverName != null) ...[
            const Divider(height: 20, color: Color(0xFF334155)),
            _infoRow(
              icon: Icons.person_rounded,
              label: 'Водитель:',
              value: cargo.driverName!,
            ),
          ],
          if (cargo.description != null) ...[
            const Divider(height: 20, color: Color(0xFF334155)),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.notes_rounded,
                  size: 16,
                  color: Color(0xFF64748B),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    cargo.description!,
                    style: const TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ],
          if (cargo.createdAt != null) ...[
            const Divider(height: 20, color: Color(0xFF334155)),
            _infoRow(
              icon: Icons.calendar_today,
              label: 'Дата создания:',
              value: _formatDate(cargo.createdAt!),
            ),
          ],
          if (cargo.weightKg != null) ...[
            const Divider(height: 20, color: Color(0xFF334155)),
            _infoRow(
              icon: Icons.scale_rounded,
              label: 'Вес:',
              value: '${cargo.weightKg!.toStringAsFixed(1)} т',
            ),
          ],
          if (cargo.volumeM3 != null) ...[
            const Divider(height: 20, color: Color(0xFF334155)),
            _infoRow(
              icon: Icons.inventory_2,
              label: 'Объем:',
              value: '${cargo.volumeM3!.toStringAsFixed(1)} м³',
            ),
          ],
          if (cargo.distanceKm != null) ...[
            const Divider(height: 20, color: Color(0xFF334155)),
            _infoRow(
              icon: Icons.straighten,
              label: 'Расстояние:',
              value: '${cargo.distanceKm!.toStringAsFixed(0)} км',
            ),
          ],
          if (cargo.bodyType != null) ...[
            const Divider(height: 20, color: Color(0xFF334155)),
            _infoRow(
              icon: Icons.local_shipping,
              label: 'Тип кузова:',
              value: cargo.bodyType!,
            ),
          ],
          if (cargo.loadingDate != null) ...[
            const Divider(height: 20, color: Color(0xFF334155)),
            _infoRow(
              icon: Icons.event,
              label: 'Дата погрузки:',
              value: _formatDate(cargo.loadingDate!),
            ),
          ],
          if (cargo.loadingType != null) ...[
            const Divider(height: 20, color: Color(0xFF334155)),
            _infoRow(
              icon: Icons.upload,
              label: 'Тип загрузки:',
              value: cargo.loadingType!,
            ),
          ],
          if (cargo.paymentType != null) ...[
            const Divider(height: 20, color: Color(0xFF334155)),
            _infoRow(
              icon: Icons.payment,
              label: 'Оплата:',
              value: cargo.paymentType!,
            ),
          ],
          if (cargo.price != null) ...[
            const Divider(height: 20, color: Color(0xFF334155)),
            _infoRow(
              icon: Icons.attach_money,
              label: 'Стоимость:',
              value: '${cargo.price!.toStringAsFixed(0)} ₸',
            ),
          ],
          if (cargo.lengthM != null ||
              cargo.heightM != null ||
              cargo.widthM != null) ...[
            const Divider(height: 20, color: Color(0xFF334155)),
            Row(
              children: [
                const Icon(
                  Icons.straighten,
                  size: 16,
                  color: Color(0xFF64748B),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Габариты:',
                  style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    _formatDimensions(
                      cargo.lengthM,
                      cargo.heightM,
                      cargo.widthM,
                    ),
                    style: const TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}.${date.month}.${date.year}';
  }

  String _formatDimensions(double? length, double? height, double? width) {
    final parts = <String>[];
    if (length != null) parts.add('${length.toStringAsFixed(1)}м');
    if (height != null) parts.add('${height.toStringAsFixed(1)}м');
    if (width != null) parts.add('${width.toStringAsFixed(1)}м');
    return parts.isEmpty ? '—' : parts.join(' × ');
  }

  Widget _infoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16, color: const Color(0xFF64748B)),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
          ),
        ),
      ],
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
        Column(
          children: [
            const Icon(
              Icons.trip_origin_rounded,
              size: 12,
              color: Color(0xFF3B82F6),
            ),
            Container(
              width: 2,
              height: 20,
              color: const Color(0xFF334155),
              margin: const EdgeInsets.symmetric(vertical: 3),
            ),
            const Icon(
              Icons.location_on_rounded,
              size: 12,
              color: Color(0xFFF59E0B),
            ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                from.isEmpty ? '—' : from,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                to.isEmpty ? '—' : to,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ChatButton extends StatelessWidget {
  final VoidCallback onTap;
  const _ChatButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: const Color(0xFF3B82F6).withOpacity(0.4),
          ),
        ),
        child: const Row(
          children: [
            Icon(Icons.chat_bubble_rounded, color: Color(0xFF3B82F6), size: 20),
            SizedBox(width: 12),
            Text(
              'Открыть чат по заявке',
              style: TextStyle(
                color: Color(0xFF3B82F6),
                fontWeight: FontWeight.w600,
              ),
            ),
            Spacer(),
            Icon(
              Icons.chevron_right_rounded,
              color: Color(0xFF3B82F6),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  const _SectionHeader({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: const Color(0xFF64748B)),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: Color(0xFF94A3B8),
          ),
        ),
      ],
    );
  }
}

class _PhotosSection extends StatelessWidget {
  final List<String> photos;
  final bool isUploading;
  final VoidCallback onUpload;
  const _PhotosSection({
    required this.photos,
    required this.isUploading,
    required this.onUpload,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (photos.isNotEmpty)
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: photos.length,
            itemBuilder: (context, index) => ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(photos[index], fit: BoxFit.cover),
            ),
          )
        else
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFF334155),
                style: BorderStyle.solid,
                width: 1,
              ),
            ),
            child: const Column(
              children: [
                Icon(
                  Icons.image_not_supported_rounded,
                  size: 36,
                  color: Color(0xFF334155),
                ),
                SizedBox(height: 8),
                Text(
                  'Фото пока нет',
                  style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
                ),
              ],
            ),
          ),
        const SizedBox(height: 12),
        if (isUploading)
          const Center(child: CircularProgressIndicator())
        else
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onUpload,
              icon: const Icon(Icons.camera_alt_rounded),
              label: const Text('Прикрепить фото с камеры'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF3B82F6),
                side: const BorderSide(color: Color(0xFF3B82F6)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
      ],
    );
  }
}

class _MapWidget extends StatelessWidget {
  final bool isLoading;
  final bool hasError;
  final LatLng? fromPoint;
  final LatLng? toPoint;
  final String fromLabel;
  final String toLabel;

  const _MapWidget({
    required this.isLoading,
    required this.hasError,
    required this.fromPoint,
    required this.toPoint,
    required this.fromLabel,
    required this.toLabel,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Container(
        height: 220,
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    if (hasError || fromPoint == null || toPoint == null) {
      return Container(
        height: 90,
        width: double.infinity,
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF334155)),
        ),
        child: const Center(
          child: Text(
            'Не удалось определить координаты.\nКарта недоступна.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
          ),
        ),
      );
    }

    final center = LatLng(
      (fromPoint!.latitude + toPoint!.latitude) / 2,
      (fromPoint!.longitude + toPoint!.longitude) / 2,
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        height: 220,
        child: FlutterMap(
          options: MapOptions(initialCenter: center, initialZoom: 7),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.example.logist_app',
            ),
            PolylineLayer(
              polylines: [
                Polyline(
                  points: [fromPoint!, toPoint!],
                  color: const Color(0xFF3B82F6),
                  strokeWidth: 3.5,
                ),
              ],
            ),
            MarkerLayer(
              markers: [
                _marker(fromPoint!, const Color(0xFF3B82F6), 'A'),
                _marker(toPoint!, const Color(0xFFF59E0B), 'B'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Marker _marker(LatLng point, Color color, String label) => Marker(
    point: point,
    width: 60,
    height: 60,
    child: Column(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: [
              BoxShadow(color: color.withOpacity(0.5), blurRadius: 8),
            ],
          ),
          child: Center(
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        CustomPaint(size: const Size(8, 6), painter: _TrianglePainter(color)),
      ],
    ),
  );
}

class _TrianglePainter extends CustomPainter {
  final Color color;
  const _TrianglePainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = ui.Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_) => false;
}
