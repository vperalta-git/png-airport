import 'package:flutter/material.dart';
import 'package:png_transfer_flutter_core/png_transfer_flutter_core.dart';
import 'package:qr_flutter/qr_flutter.dart';

class QrBoardingPassModal extends StatelessWidget {
  final Booking booking;
  final Passenger passenger;

  const QrBoardingPassModal({
    super.key,
    required this.booking,
    required this.passenger,
  });

  @override
  Widget build(BuildContext context) {
    final qrData = passenger.qrToken ?? 'PNG-TR-${booking.id}-PASSENGER-${passenger.id}';
    final otp = passenger.otp ?? '482910';

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: AviationColors.cardDark,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(
          top: BorderSide(color: AviationColors.gold500, width: 2),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AviationColors.cardBorder,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 18),

          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'SECURITY CLEARANCE PASS',
                    style: TextStyle(
                      color: AviationColors.gold400,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    booking.name,
                    style: const TextStyle(
                      color: AviationColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AviationColors.statusVerified.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AviationColors.statusVerified),
                ),
                child: const Text(
                  'AUTH VALID',
                  style: TextStyle(
                    color: AviationColors.statusVerified,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const Divider(color: AviationColors.cardBorder, height: 28),

          // QR Code Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.4),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: QrImageView(
              data: qrData,
              version: QrVersions.auto,
              size: 190.0,
              backgroundColor: Colors.white,
            ),
          ),
          const SizedBox(height: 18),

          // 6-Digit OTP Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: AviationColors.inputBackground,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AviationColors.cardBorder),
            ),
            child: Column(
              children: [
                const Text(
                  '6-DIGIT VERIFICATION CODE',
                  style: TextStyle(
                    color: AviationColors.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  otp.split('').join('  '),
                  style: const TextStyle(
                    color: AviationColors.gold500,
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 4.0,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Passenger info & Flight
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('PASSENGER', style: TextStyle(color: AviationColors.textMuted, fontSize: 11)),
                  Text(passenger.fullName, style: const TextStyle(color: AviationColors.textPrimary, fontWeight: FontWeight.w700)),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text('FLIGHT / ROUTE', style: TextStyle(color: AviationColors.textMuted, fontSize: 11)),
                  Text(booking.flightNumber ?? 'Ground Transit', style: const TextStyle(color: AviationColors.gold400, fontWeight: FontWeight.w700)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Close button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AviationColors.primaryNavy,
                foregroundColor: Colors.white,
              ),
              child: const Text('DISMISS PASS'),
            ),
          ),
        ],
      ),
    );
  }
}
