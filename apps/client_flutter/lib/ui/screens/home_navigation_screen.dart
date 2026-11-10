import 'package:flutter/material.dart';
import 'package:png_transfer_flutter_core/png_transfer_flutter_core.dart';
import 'radar/flight_radar_screen.dart';
import 'booking/booking_wizard_screen.dart';
import 'trips/my_trips_screen.dart';
import 'profile/profile_screen.dart';

class HomeNavigationScreen extends StatefulWidget {
  const HomeNavigationScreen({super.key});

  @override
  State<HomeNavigationScreen> createState() => _HomeNavigationScreenState();
}

class _HomeNavigationScreenState extends State<HomeNavigationScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final screens = [
      FlightRadarScreen(
        onNavigateToBook: () => setState(() => _currentIndex = 1),
      ),
      BookingWizardScreen(
        onBookingSuccess: () => setState(() => _currentIndex = 2),
      ),
      MyTripsScreen(
        onNewBooking: () => setState(() => _currentIndex = 1),
      ),
      const ProfileScreen(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(
            top: BorderSide(color: AviationColors.cardBorder, width: 1),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.radar),
              activeIcon: Icon(Icons.radar, color: AviationColors.gold500),
              label: 'Flight Radar',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.add_road),
              activeIcon: Icon(Icons.add_road, color: AviationColors.gold500),
              label: 'Book Transfer',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.confirmation_number_outlined),
              activeIcon: Icon(Icons.confirmation_number, color: AviationColors.gold500),
              label: 'My Trips',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person, color: AviationColors.gold500),
              label: 'Profile / VIP',
            ),
          ],
        ),
      ),
    );
  }
}
