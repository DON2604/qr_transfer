import 'package:flutter/material.dart';

import 'ui/home_screen.dart';
import 'ui/theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const QrTransferApp());
}

class QrTransferApp extends StatelessWidget {
  const QrTransferApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AirTransfer QR',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark,
      darkTheme: AppTheme.dark(),
      home: const HomeScreen(),
    );
  }
}
