import 'package:flutter/material.dart';
import 'package:png_transfer_flutter_core/png_transfer_flutter_core.dart';

Future<void> main() => runLocalFoundation('Security');

// Preserved implementation for Batch B. Not a launch entrypoint.
void legacyMain() {
  runApp(const SecurityMobileApp());
}

class SecurityMobileApp extends StatelessWidget {
  const SecurityMobileApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PNG Secure Escort — Tactical Officer Terminal',
      debugShowCheckedModeBanner: false,
      theme: AviationTheme.darkTheme,
      home: const SecurityOfficerHomeScreen(),
    );
  }
}

class SecurityOfficerHomeScreen extends StatefulWidget {
  const SecurityOfficerHomeScreen({super.key});

  @override
  State<SecurityOfficerHomeScreen> createState() => _SecurityOfficerHomeScreenState();
}

class _SecurityOfficerHomeScreenState extends State<SecurityOfficerHomeScreen> {
  bool _isWeaponCleared = true;
  bool _isRadioChecked = true;
  bool _isBodyArmorSecured = true;
  final String _currentStatus = 'ON_DUTY_STANDBY';

  void _triggerPanicAlarm() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E0808),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 28),
            SizedBox(width: 8),
            Text('CONFIRM EMERGENCY SOS', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Text(
          'This will trigger an immediate P1 CRITICAL armed ambush / security alarm to the Control Room, transmitting your GPS coordinates and callsign.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('CANCEL', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('🚨 EMERGENCY SOS BROADCASTED TO CONTROL ROOM!'),
                  backgroundColor: Colors.red,
                ),
              );
            },
            child: const Text('BROADCAST SOS NOW'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D141C),
      appBar: AppBar(
        backgroundColor: const Color(0xFF16222F),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('TACTICAL ESCORT TERMINAL', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.1)),
            Text('OFFICER: Michael Toru • CALLSIGN: VIPER-1', style: TextStyle(fontSize: 12, color: Colors.amberAccent)),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.teal.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.tealAccent),
            ),
            child: Text(
              _currentStatus,
              style: const TextStyle(color: Colors.tealAccent, fontSize: 10, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Threat Status Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF16222F),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.amber.withValues(alpha: 0.4)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.security, color: Colors.amberAccent, size: 36),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('PILOT SECTOR: NADZAB - LAE HIGHWAY', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text('CURRENT THREAT LEVEL: ELEVATED (ARMED ESCORT MANDATED)', style: TextStyle(color: Colors.amberAccent.shade100, fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Emergency SOS Panic Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD32F2F),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 6,
                ),
                icon: const Icon(Icons.emergency_share, size: 28),
                label: const Text('ONE-TOUCH EMERGENCY SOS', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                onPressed: _triggerPanicAlarm,
              ),
            ),
            const SizedBox(height: 24),

            // Pre-Deployment Protocol Checklist
            const Text('TACTICAL PRE-DEPLOYMENT PROTOCOL', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1.1)),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF131D27),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  CheckboxListTile(
                    title: const Text('Firearm Inspected & Magazine Loaded', style: TextStyle(color: Colors.white)),
                    subtitle: const Text('RPNGC Permit # FA-LAE-2024-099 (Valid)', style: TextStyle(color: Colors.white54, fontSize: 12)),
                    value: _isWeaponCleared,
                    activeColor: Colors.tealAccent,
                    checkColor: Colors.black,
                    onChanged: (v) => setState(() => _isWeaponCleared = v ?? false),
                  ),
                  const Divider(color: Colors.white12, height: 1),
                  CheckboxListTile(
                    title: const Text('Tactical VHF Radio Comms Tested', style: TextStyle(color: Colors.white)),
                    subtitle: const Text('Channel 3 (Base Command 156.800 MHz)', style: TextStyle(color: Colors.white54, fontSize: 12)),
                    value: _isRadioChecked,
                    activeColor: Colors.tealAccent,
                    checkColor: Colors.black,
                    onChanged: (v) => setState(() => _isRadioChecked = v ?? false),
                  ),
                  const Divider(color: Colors.white12, height: 1),
                  CheckboxListTile(
                    title: const Text('Level IIIA Body Armor & Trauma Kit Secured', style: TextStyle(color: Colors.white)),
                    subtitle: const Text('Chest Rig + IFAK Trauma Dressing', style: TextStyle(color: Colors.white54, fontSize: 12)),
                    value: _isBodyArmorSecured,
                    activeColor: Colors.tealAccent,
                    checkColor: Colors.black,
                    onChanged: (v) => setState(() => _isBodyArmorSecured = v ?? false),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Active Mission Assignment
            const Text('CURRENT ESCORT MISSION', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1.1)),
            const SizedBox(height: 12),
            Card(
              color: const Color(0xFF16222F),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('PNG-TR-20261115-88219', style: TextStyle(color: Colors.tealAccent, fontWeight: FontWeight.bold, fontSize: 15)),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(color: Colors.teal.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(6)),
                          child: const Text('INBOUND ESCORT', style: TextStyle(color: Colors.tealAccent, fontSize: 11, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text('FLIGHT: Air Niugini PX 102 (From POM)', style: TextStyle(color: Colors.white70)),
                    const Text('LANDING: Nadzab Tomodachi (AYNZ) • Bay 2', style: TextStyle(color: Colors.white70)),
                    const Text('DESTINATION: Lae International Hotel (Convoy)', style: TextStyle(color: Colors.white70)),
                    const Text('CONVOY VEHICLES: LAE-8821 (Lead LandCruiser 79) + LAE-9901 (Chase Prado)', style: TextStyle(color: Colors.white70)),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0077C2), foregroundColor: Colors.white),
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Mission acknowledged by VIPER-1. Tactical channel open.')),
                          );
                        },
                        child: const Text('ACKNOWLEDGE ESCORT ASSIGNMENT'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
