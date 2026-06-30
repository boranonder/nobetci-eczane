import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants/app_colors.dart';
import '../providers/auth_provider.dart' show AppAuthProvider;
import '../providers/query_provider.dart';
import 'map/map_screen.dart';
import 'search/drug_search_screen.dart';
import 'queries/queries_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    MapScreen(),
    DrugSearchScreen(),
    QueriesScreen(),
  ];

  final List<String> _titles = ['Harita', 'İlaç Ara', 'Sorgularım'];

  @override
  void initState() {
    super.initState();
    context.read<QueryProvider>().loadFromStorage();
  }

  void _showProfileSheet() {
    final auth = context.read<AppAuthProvider>();
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(color: AppColors.textHint, borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 20),
            CircleAvatar(
              radius: 32,
              backgroundColor: AppColors.primaryLight,
              child: const Icon(Icons.person, color: AppColors.primary, size: 32),
            ),
            const SizedBox(height: 12),
            Text(
              auth.profile?.name ?? 'Kullanıcı',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            Text(
              auth.profile?.email ?? '',
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
            if (auth.profile?.isPharmacy == true) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(color: AppColors.dutyLight, borderRadius: BorderRadius.circular(12)),
                child: const Text('Eczane Hesabı', style: TextStyle(color: AppColors.duty, fontSize: 12, fontWeight: FontWeight.w600)),
              ),
              if (auth.profile?.phone != null)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(auth.profile!.phone!, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                ),
            ],
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () async {
                  Navigator.pop(context);
                  await context.read<AppAuthProvider>().signOut();
                },
                icon: const Icon(Icons.logout),
                label: const Text('Çıkış Yap'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.error,
                  side: const BorderSide(color: AppColors.error),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(8)),
              child: const Icon(Icons.local_pharmacy, color: AppColors.primary, size: 20),
            ),
            const SizedBox(width: 8),
            Text(_titles[_currentIndex]),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.account_circle_outlined),
            onPressed: _showProfileSheet,
          ),
        ],
      ),
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.map_outlined), activeIcon: Icon(Icons.map), label: 'Harita'),
          BottomNavigationBarItem(icon: Icon(Icons.search_outlined), activeIcon: Icon(Icons.search), label: 'İlaç Ara'),
          BottomNavigationBarItem(icon: Icon(Icons.list_alt_outlined), activeIcon: Icon(Icons.list_alt), label: 'Sorgularım'),
        ],
      ),
    );
  }
}
