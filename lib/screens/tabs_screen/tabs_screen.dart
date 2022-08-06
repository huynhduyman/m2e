import 'package:flutter/material.dart';

import 'tabs/wallet_tab.dart';
import 'tabs/home_tab.dart';
import 'tabs/workouts_tab.dart';
import 'tabs/user_tab.dart';
import 'tabs/marketplace_tab.dart';
import 'widgets/bottom_nav_bar.dart';

class TabsScreen extends StatefulWidget {
  const TabsScreen({Key? key}) : super(key: key);

  @override
  State<TabsScreen> createState() => _TabsScreenState();
}

class _TabsScreenState extends State<TabsScreen> {
  int _currentIndex = 0;

  final List<Widget> _tabs = [
    const HomeTab(),
    const WorkoutsTab(),
    const MarketPlaceTab(),
    const WalletTab(),
    const UserTab()
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 150),
        child: _tabs[_currentIndex],
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: _currentIndex,
        onTap: (int index) => setState(() {
          _currentIndex = index;
        }),
      ),
    );
  }
}
