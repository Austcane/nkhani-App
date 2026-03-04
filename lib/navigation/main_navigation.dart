import 'package:flutter/material.dart';
import 'package:nkhani/features/home/home_screen.dart';
import 'package:nkhani/features/live/live_tv_screen.dart';
import 'package:nkhani/features/profile/profile_screen.dart';
import 'package:nkhani/features/radio/radio_screen.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    HomeScreen(),
    RadioScreen(),
    LiveTvScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: _screens[_currentIndex],
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.only(
          left: 20,
          right: 20,
          bottom: 25,
        ),
        child: Container(
          height: 70,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(40),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 25,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              AnimatedAlign(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                alignment: _getAlignment(),
                child: Container(
                  width: MediaQuery.of(context).size.width / 3 - 40,
                  height: 50,
                  decoration: BoxDecoration(
                    color: const Color(0xFF8A1E78),
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildItem(Icons.home_filled, 'Home', 0),
                  _buildItem(Icons.radio, 'Radio', 1),
                  _buildItem(Icons.live_tv, 'Live TV', 2),
                  _buildItem(Icons.person, 'Profile', 3),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Alignment _getAlignment() {
    switch (_currentIndex) {
      case 0:
        return Alignment.centerLeft;
      case 1:
        return Alignment.centerLeft + const Alignment(0.66, 0);
      case 2:
        return Alignment.centerRight + const Alignment(-0.66, 0);
      case 3:
        return Alignment.centerRight;
      default:
        return Alignment.centerLeft;
    }
  }

  Widget _buildItem(IconData icon, String label, int index) {
    final isSelected = _currentIndex == index;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() => _currentIndex = index);
        },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : Colors.black54,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.black54,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
