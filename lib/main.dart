import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:image_picker_android/image_picker_android.dart';
import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';

import 'providers/scan_provider.dart';
import 'providers/premium_provider.dart';
import 'router.dart';
import 'utils/app_theme.dart';

void _configureAndroidPhotoPicker() {
  if (kIsWeb) return;
  final impl = ImagePickerPlatform.instance;
  if (impl is ImagePickerAndroid) {
    impl.useAndroidPhotoPicker = true;
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  _configureAndroidPhotoPicker();

  // Initialise AdMob
  await MobileAds.instance.initialize();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => PremiumProvider()..init()),
        ChangeNotifierProvider(create: (_) => ScanProvider()..init()),
      ],
      child: const OcrScannerApp(),
    ),
  );
}

class OcrScannerApp extends StatelessWidget {
  const OcrScannerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'OCR Scanner',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      routerConfig: appRouter,
    );
  }
}
