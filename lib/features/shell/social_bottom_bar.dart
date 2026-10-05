import 'package:flutter/material.dart';

class SocialBottomBar extends StatelessWidget {
  const SocialBottomBar({super.key, this.selectedIndex = 0});

  final int selectedIndex;

  void _open(BuildContext context, int index) {
    if (index == selectedIndex) return;
    final routes = const ['/home', '/explore', '/groups-tab', '/profile-tab'];
    Navigator.pushReplacementNamed(context, routes[index]);
  }

  @override
  Widget build(BuildContext context) => NavigationBar(
    selectedIndex: selectedIndex,
    onDestinationSelected: (index) => _open(context, index),
    destinations: const [
      NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Home'),
      NavigationDestination(icon: Icon(Icons.explore_outlined), label: 'Explore'),
      NavigationDestination(icon: Icon(Icons.groups_outlined), label: 'Groups'),
      NavigationDestination(icon: Icon(Icons.person_outline), label: 'Profile'),
    ],
  );
}
