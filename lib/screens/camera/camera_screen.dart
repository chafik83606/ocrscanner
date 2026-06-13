import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

import '../../providers/scan_provider.dart';
import '../../providers/premium_provider.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ajouter un scan')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _SourceButton(
              icon: Icons.camera_alt,
              label: 'Prendre une photo',
              onTap: _isLoading ? null : () => _pick(ImageSource.camera),
            ),
            const SizedBox(height: 16),
            _SourceButton(
              icon: Icons.photo_library,
              label: 'Choisir une photo',
              onTap: _isLoading ? null : () => _pick(ImageSource.gallery),
            ),
            if (_isLoading) ...[
              const SizedBox(height: 32),
              const Center(child: CircularProgressIndicator()),
              const SizedBox(height: 8),
              const Center(child: Text('Extraction OCR en cours…')),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _pick(ImageSource source) async {
    try {
      // Android : demander la permission avant la caméra.
      // iOS : image_picker affiche la boîte de dialogue système (évite un refus silencieux).
      if (source == ImageSource.camera &&
          !kIsWeb &&
          defaultTargetPlatform == TargetPlatform.android) {
        final status = await Permission.camera.request();
        if (!status.isGranted) {
          if (status.isPermanentlyDenied) {
            _showSnack(
              'Autorisez la caméra dans les réglages de l\'appareil',
            );
            await openAppSettings();
          } else {
            _showSnack('Permission caméra refusée');
          }
          return;
        }
      }

      final xFile = await _picker.pickImage(source: source, imageQuality: 90);
      if (xFile == null) return;

      // Capture le contexte avant les awaits
      if (!mounted) return;
      final primaryColor = Theme.of(context).colorScheme.primary;
      final premiumProvider = context.read<PremiumProvider>();
      final scanProvider = context.read<ScanProvider>();
      final language = premiumProvider.language;

      // Recadrage (avec fallback auto vers la photo brute si le plugin échoue)
      String finalPath = xFile.path;
      try {
        final cropped = await ImageCropper().cropImage(
          sourcePath: xFile.path,
          uiSettings: [
            AndroidUiSettings(
              toolbarTitle: 'Recadrer',
              toolbarColor: primaryColor,
              statusBarColor: primaryColor,
              toolbarWidgetColor: Colors.white,
              initAspectRatio: CropAspectRatioPreset.original,
              lockAspectRatio: false,
            ),
            IOSUiSettings(title: 'Recadrer'),
          ],
        );

        finalPath = cropped?.path ?? xFile.path;
      } on PlatformException {
        _showSnack('Recadrage indisponible: OCR lancé sur la photo originale');
      }

      // OCR
      if (!mounted) return;
      setState(() => _isLoading = true);

      final scan = await scanProvider.performOcr(finalPath, language: language);

      if (!mounted) return;
      setState(() => _isLoading = false);

      if (scan == null) {
        _showSnack('Erreur OCR : ${scanProvider.errorMsg}');
        return;
      }

      // Incrémente le compteur gratuit
      await premiumProvider.recordScan();

      if (!mounted) return;
      context.pushReplacement('/result', extra: scan);
    } on PlatformException catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showSnack('Erreur caméra : ${e.message ?? e.code}');
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showSnack('Une erreur est survenue pendant la capture');
    }
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }
}

class _SourceButton extends StatelessWidget {
  const _SourceButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 48,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 12),
              Text(label, style: Theme.of(context).textTheme.titleMedium),
            ],
          ),
        ),
      ),
    );
  }
}
