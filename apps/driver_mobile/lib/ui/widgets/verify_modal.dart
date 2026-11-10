import 'package:flutter/material.dart';
import 'package:png_transfer_flutter_core/png_transfer_flutter_core.dart';
import '../../models/driver_mission.dart';

class VerifyModal extends StatefulWidget {
  final DriverMission mission;
  final VoidCallback onVerified;

  const VerifyModal({super.key, required this.mission, required this.onVerified});

  @override
  State<VerifyModal> createState() => _VerifyModalState();
}

class _VerifyModalState extends State<VerifyModal> {
  final _otpController = TextEditingController(text: '741258');
  bool _isVerifying = false;
  bool _verifiedSuccess = false;

  void _verifyNow() async {
    setState(() => _isVerifying = true);
    await Future.delayed(const Duration(milliseconds: 600));
    setState(() {
      _isVerifying = false;
      _verifiedSuccess = true;
    });
    await Future.delayed(const Duration(milliseconds: 800));
    if (mounted) {
      widget.onVerified();
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: AviationColors.cardDark,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(top: BorderSide(color: AviationColors.gold500, width: 2)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AviationColors.cardBorder,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'PASSENGER IDENTITY CLEARANCE',
            style: TextStyle(
              color: AviationColors.gold400,
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            widget.mission.passengerName,
            style: const TextStyle(color: AviationColors.textPrimary, fontSize: 17, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 20),

          if (_verifiedSuccess)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AviationColors.statusVerified.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AviationColors.statusVerified),
              ),
              child: const Column(
                children: [
                  Icon(Icons.verified, size: 48, color: AviationColors.statusVerified),
                  SizedBox(height: 10),
                  Text(
                    'IDENTITY VERIFIED & CLEARED',
                    style: TextStyle(color: AviationColors.textPrimary, fontWeight: FontWeight.w800, fontSize: 16),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Passenger authorization matched with booking manifest.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AviationColors.textSecondary, fontSize: 12),
                  ),
                ],
              ),
            )
          else ...[
            // Quick Simulation Scan Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.qr_code_scanner, size: 20),
                label: const Text('SCAN PASSENGER QR CODE'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AviationColors.primaryNavy,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: _isVerifying ? null : _verifyNow,
              ),
            ),
            const SizedBox(height: 16),
            const Row(
              children: [
                Expanded(child: Divider(color: AviationColors.cardBorder)),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10),
                  child: Text('OR ENTER 6-DIGIT OTP', style: TextStyle(color: AviationColors.textMuted, fontSize: 10)),
                ),
                Expanded(child: Divider(color: AviationColors.cardBorder)),
              ],
            ),
            const SizedBox(height: 16),

            // OTP Input
            TextField(
              controller: _otpController,
              textAlign: TextAlign.center,
              keyboardType: TextInputType.number,
              style: const TextStyle(
                color: AviationColors.gold400,
                fontSize: 24,
                fontWeight: FontWeight.w900,
                letterSpacing: 6.0,
              ),
              decoration: const InputDecoration(
                hintText: '6-DIGIT PIN',
                isDense: true,
              ),
            ),
            const SizedBox(height: 16),

            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AviationColors.cardBorder),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onPressed: _isVerifying ? null : _verifyNow,
                child: _isVerifying
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('MANUAL OTP VERIFICATION', style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
