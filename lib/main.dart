import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/database/db_helper.dart';
import 'features/checklist/providers/checklist_provider.dart';
import 'features/calculator/providers/calculator_provider.dart';
import 'features/scanner/screens/scanner_screen.dart';
import 'features/calculator/screens/split_calculator_screen.dart';
import 'features/checklist/screens/checklist_screen.dart';
import 'features/settings/screens/settings_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DatabaseHelper.instance.database; // Ensure DB is initialized early
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ChecklistProvider()..fetchEntries()),
        ChangeNotifierProvider(create: (_) => CalculatorProvider()),
      ],
      child: const SplitaaApp(),
    ),
  );
}

class SplitaaApp extends StatelessWidget {
  const SplitaaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Splitaa',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
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
    SplitCalculatorScreen(),
    ChecklistScreen(),
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
          NavigationDestination(icon: Icon(Icons.settings), label: 'Settings'),
        ],
      ),
    );
  }
}
