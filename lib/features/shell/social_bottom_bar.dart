import 'package:flutter/material.dart';

class SocialBottomBar extends StatelessWidget {
  const SocialBottomBar({super.key, this.selectedIndex = 0});

  final int selectedIndex;

  void _open(BuildContext context, int index) {
    final routes = const ['/home', '/explore', '/groups-tab', '/profile-tab'];
    if (Navigator.canPop(context)) {
      Navigator.popUntil(context, (route) => route.isFirst);
      if (index != 0) {
        Navigator.pushNamed(context, routes[index]);
      }
    } else {
      if (index == selectedIndex) return;
      Navigator.pushReplacementNamed(context, routes[index]);
    }
  }

  @override
  Widget build(BuildContext context) => NavigationBar(
    selectedIndex: (selectedIndex >= 0 && selectedIndex < 4) ? selectedIndex : 0,
    onDestinationSelected: (index) => _open(context, index),
    destinations: const [
      NavigationDestination(
        icon: Icon(Icons.home_outlined),
        selectedIcon: Icon(Icons.home_rounded),
        label: 'Home',
      ),
      NavigationDestination(
        icon: Icon(Icons.explore_outlined),
        selectedIcon: Icon(Icons.explore_rounded),
        label: 'Explore',
      ),
      NavigationDestination(
        icon: Icon(Icons.groups_outlined),
        selectedIcon: Icon(Icons.groups_rounded),
        label: 'Squads',
      ),
      NavigationDestination(
        icon: Icon(Icons.person_outline),
        selectedIcon: Icon(Icons.person_rounded),
        label: 'Profile',
      ),
    ],
  );
}
