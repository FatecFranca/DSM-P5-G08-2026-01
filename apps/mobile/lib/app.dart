import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'features/catalog/pages/catalog_page.dart';

class NexusFlowApp extends StatelessWidget {
  const NexusFlowApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'NexusFlow Catalog',
      themeMode: ThemeMode.system,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      home: const CatalogPage(),
    );
  }
}
