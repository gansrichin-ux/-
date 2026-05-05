import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../core/services/delivery_report_service.dart';
import '../models/cargo_model.dart';
import '../widgets/signature_pad.dart';
import '../widgets/photo_gallery_widget.dart';

class DeliveryReportScreen extends ConsumerStatefulWidget {
  final CargoModel cargo;

  const DeliveryReportScreen({super.key, required this.cargo});

  @override
  ConsumerState<DeliveryReportScreen> createState() => _DeliveryReportScreenState();
}

class _DeliveryReportScreenState extends ConsumerState<DeliveryReportScreen> {
  final DeliveryReportService _reportService = DeliveryReportService.instance;
  final ImagePicker _imagePicker = ImagePicker();
  final TextEditingController _notesController = TextEditingController();
  final GlobalKey _signaturePadKey = GlobalKey();
  
  final List<String> _photos = [];
  Uint8List? _signatureBytes;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Отчет о доставке'),
        actions: [
          TextButton(
            onPressed: _isSubmitting ? null : _submitReport,
            child: _isSubmitting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Отправить'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cargo info
            _buildCargoInfo(),
            const SizedBox(height: 24),
            
            // Photos section
            _buildPhotosSection(),
            const SizedBox(height: 24),
            
            // Signature section
            _buildSignatureSection(),
            const SizedBox(height: 24),
            
            // Notes section
            _buildNotesSection(),
            const SizedBox(height: 32),
            
            // Submit button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitReport,
                child: _isSubmitting
                    ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(width: 12),
                          Text('Отправка...'),
                        ],
                      )
                    : const Text('Отправить отчет'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCargoInfo() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.cargo.title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.trip_origin_rounded,
                    size: 16, color: Color(0xFF3B82F6)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Откуда: ${widget.cargo.from}',
                    style: const TextStyle(color: Color(0xFF94A3B8)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.location_on_rounded,
                    size: 16, color: Color(0xFFF59E0B)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Куда: ${widget.cargo.to}',
                    style: const TextStyle(color: Color(0xFF94A3B8)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotosSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Фотографии',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        PhotoGalleryWidget(
          photos: _photos,
          onAddPhoto: _addPhoto,
          onRemovePhoto: _removePhoto,
        ),
        const SizedBox(height: 8),
        Text(
          'Добавьте фотографии доставленного груза',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: const Color(0xFF94A3B8),
          ),
        ),
      ],
    );
  }

  Widget _buildSignatureSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Подпись получателя',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        SignaturePad(
          key: _signaturePadKey,
          onSignatureChanged: (signature) {
            setState(() {
              _signatureBytes = signature.isNotEmpty ? signature : null;
            });
          },
          penColor: Colors.black,
          penStrokeWidth: 3.0,
          backgroundColor: Colors.white,
        ),
        const SizedBox(height: 8),
        Text(
          'Получите подпись клиента при доставке',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: const Color(0xFF94A3B8),
          ),
        ),
      ],
    );
  }

  Widget _buildNotesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Примечания',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _notesController,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: 'Дополнительная информация о доставке...',
            border: OutlineInputBorder(),
          ),
        ),
      ],
    );
  }

  Future<void> _addPhoto() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
        maxWidth: 1024,
        maxHeight: 1024,
      );

      if (image != null) {
        // For now, we'll just add the local path
        // In production, you should upload to Firebase Storage
        setState(() {
          _photos.add(image.path);
        });
      }
    } catch (e) {
      _showErrorSnackBar('Ошибка при добавлении фотографии');
    }
  }

  void _removePhoto(int index) {
    setState(() {
      _photos.removeAt(index);
    });
  }

  Future<void> _submitReport() async {
    if (_photos.isEmpty) {
      _showErrorSnackBar('Добавьте хотя бы одну фотографию');
      return;
    }

    if (_signatureBytes == null || _signatureBytes!.isEmpty) {
      _showErrorSnackBar('Получите подпись клиента');
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      // Get current user (you'll need to implement this)
      final driverId = 'current_driver_id'; // Replace with actual driver ID
      
      // Upload photos and get URLs
      final photoUrls = <String>[];
      for (final _ in _photos) {
        final photoUrl = await _reportService.pickAndUploadPhoto(
          widget.cargo.id,
          driverId,
        );
        if (photoUrl != null) {
          photoUrls.add(photoUrl);
        }
      }

      // Convert signature to base64
      final signatureBase64 = _signatureBytes != null 
          ? 'data:image/png;base64,${_base64Encode(_signatureBytes!)}'
          : null;

      // Create report
      await _reportService.createReport(
        cargoId: widget.cargo.id,
        driverId: driverId,
        photos: photoUrls,
        signatureBase64: signatureBase64,
        notes: _notesController.text.trim().isEmpty 
            ? null 
            : _notesController.text.trim(),
      );

      // Update cargo status
      // You'll need to implement this in your cargo repository
      // await CargoRepository.instance.updateStatus(widget.cargo.id, 'Доставлен');

      if (mounted) {
        _showSuccessSnackBar('Отчет успешно отправлен');
        Navigator.of(context).pop();
      }
    } catch (e) {
      _showErrorSnackBar('Ошибка при отправке отчета');
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFFEF4444),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFF22C55E),
      ),
    );
  }

  String _base64Encode(Uint8List bytes) {
    // Simple base64 encoding (you might want to use a proper library)
    return 'base64_encoded_string'; // Replace with actual encoding
  }
}
