import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/widgets/brutal_bottom_nav.dart';

class MainShellScreen extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const MainShellScreen({
    super.key,
    required this.navigationShell,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: BrutalBottomNav(
        currentIndex: navigationShell.currentIndex,
        onTap: (index) {
          navigationShell.goBranch(
            index,
            initialLocation: index == navigationShell.currentIndex,
          );
        },
        items: const [
          BrutalNavItem(icon: Icons.dashboard_outlined, label: 'VAULT'),
          BrutalNavItem(icon: Icons.account_balance_outlined, label: 'ACCOUNTS'),
          BrutalNavItem(icon: Icons.receipt_long_outlined, label: 'LEDGER'),
          BrutalNavItem(icon: Icons.people_outline, label: 'DEBTS'),
          BrutalNavItem(icon: Icons.bar_chart_outlined, label: 'REPORTS'),
        ],
      ),
    );
  }
}
