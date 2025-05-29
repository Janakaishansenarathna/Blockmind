import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../utils/constants/app_colors.dart';
import 'features/activities/screens/activites_screen.dart';
import 'features/analysis/screen/analysis_screen.dart';
import 'features/dashboard/screens/dashboard_screen.dart';
import 'features/profile/sreens/profile_screen.dart';
import 'features/schedules/screens/schedule_list_screen.dart';

class AppNavBar extends StatefulWidget {
  final int initialIndex;

  const AppNavBar({
    super.key,
    this.initialIndex = 0,
  });

  @override
  State<AppNavBar> createState() => _AppNavBarState();
}

class _AppNavBarState extends State<AppNavBar> {
  late int _selectedIndex;

  final List<Widget> _screens = [
    const HomeScreen(),
    const ScheduleListScreen(),
    const AnalysisScreen(),
    const ActivityReportScreen(),
    const ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex.clamp(0, _screens.length - 1);

    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));
  }

  void _onItemTapped(int index) {
    if (index >= 0 && index < _screens.length) {
      setState(() {
        _selectedIndex = index;
      });

      // Provide haptic feedback
      HapticFeedback.lightImpact();
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Handle back button to go to home tab if not already there
        if (_selectedIndex != 0) {
          setState(() {
            _selectedIndex = 0;
          });
          return false;
        }
        return true;
      },
      child: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.backgroundGradient,
        ),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          extendBody: true,
          body: IndexedStack(
            index: _selectedIndex,
            children: _screens,
          ),
          bottomNavigationBar: Container(
            margin: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: BottomNavigationBar(
                currentIndex: _selectedIndex,
                onTap: _onItemTapped,
                backgroundColor: Colors.transparent,
                elevation: 0,
                type: BottomNavigationBarType.fixed,
                selectedItemColor: AppColors.buttonPrimary,
                unselectedItemColor: AppColors.textSecondary,
                selectedLabelStyle: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontSize: 11,
                ),
                items: const [
                  BottomNavigationBarItem(
                    icon: Icon(Icons.home_rounded),
                    activeIcon: Icon(Icons.home),
                    label: 'Home',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.schedule_rounded),
                    activeIcon: Icon(Icons.schedule),
                    label: 'Schedules',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.analytics_rounded),
                    activeIcon: Icon(Icons.analytics),
                    label: 'Analysis',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.timeline_rounded),
                    activeIcon: Icon(Icons.timeline),
                    label: 'Activity',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.person_rounded),
                    activeIcon: Icon(Icons.person),
                    label: 'Profile',
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
