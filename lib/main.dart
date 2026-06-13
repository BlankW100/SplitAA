import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/database/db_helper.dart';
import 'core/services/notification_service.dart';
import 'core/currency/currency_provider.dart';
import 'core/theme/theme_provider.dart';
import 'features/checklist/providers/checklist_provider.dart';
import 'features/scanner/screens/scanner_screen.dart';
import 'features/quicksplit/screens/quick_split_screen.dart';
import 'features/checklist/screens/checklist_screen.dart';
import 'features/history/screens/history_screen.dart';
import 'features/settings/screens/settings_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DatabaseHelper.instance.database;
  await NotificationService.init();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()..load()),
        ChangeNotifierProvider(create: (_) => ChecklistProvider()..fetchEntries()),
        ChangeNotifierProvider(create: (_) => CurrencyProvider()..load()),
      ],
      child: const SplitaaApp(),
    ),
  );
}

class SplitaaApp extends StatelessWidget {
  const SplitaaApp({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    return MaterialApp(
      title: 'Splitaa',
      themeMode: theme.themeMode,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: theme.seedColor),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: theme.seedColor,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const MainLayout(),
    );
  }
}

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _currentIndex = 0;

  final _screens = const [
    ScannerScreen(),
    QuickSplitScreen(),
    ChecklistScreen(),
    HistoryScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.document_scanner), label: 'Scan'),
          NavigationDestination(icon: Icon(Icons.calculate), label: 'Split'),
          NavigationDestination(icon: Icon(Icons.checklist), label: 'Ledger'),
          NavigationDestination(icon: Icon(Icons.insights), label: 'Spending'),
          NavigationDestination(icon: Icon(Icons.settings), label: 'Settings'),
        ],
      ),
    );
  }
}
