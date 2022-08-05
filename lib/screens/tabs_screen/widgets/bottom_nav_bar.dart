import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:iconsax/iconsax.dart';

import '../../../core/utils/utils.dart';

class BottomNavBar extends StatelessWidget {
  const BottomNavBar({
    Key? key,
    required this.currentIndex,
    required this.onTap,
  }) : super(key: key);

  final int currentIndex;

  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      backgroundColor: Theme.of(context).colorScheme.surface,
      elevation: 0,
      iconSize: rf(20),
      showSelectedLabels: true,
      showUnselectedLabels: true,
      currentIndex: currentIndex,
      onTap: onTap,
      type: BottomNavigationBarType.fixed,
      items: [
        const BottomNavigationBarItem(
          icon: Icon(Iconsax.home),
          activeIcon: Icon(Iconsax.home_15),
          label: 'Home',
        ),
        const BottomNavigationBarItem(
          icon: Icon(Icons.directions_run),
          activeIcon: Icon(Icons.directions_run),
          label: 'Workouts',
        ),
        const BottomNavigationBarItem(
          icon: Icon(Icons.add_chart_sharp),
          activeIcon: Icon(Icons.add_chart_sharp),
          label: 'Marketplace',
        ),
        const BottomNavigationBarItem(
          icon: Icon(Iconsax.wallet),
          activeIcon: Icon(Iconsax.wallet),
          label: 'Wallet',
        ),
        BottomNavigationBarItem(
          icon: const Icon(Iconsax.user),
          activeIcon: SvgPicture.asset(
            "assets/images/user-active.svg",
            width: rf(24),
          ),
          label: 'Account',
        ),
      ],
    );
  }
}
