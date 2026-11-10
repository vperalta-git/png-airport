import 'package:flutter_test/flutter_test.dart';
import 'package:png_transfer_flutter_core/png_transfer_flutter_core.dart';

void main() {
  test('Airport and ServiceZone parsing test', () {
    const zone = ServiceZone(
      id: 1,
      name: 'Lae Port',
      code: 'LAE-P',
      zoneType: 'port',
      riskLevel: 'medium',
      pricingZone: 'zone_a',
    );
    expect(zone.isHighRisk, false);

    const airport = Airport(
      id: 1,
      name: 'Nadzab Tomodachi International Airport',
      iataCode: 'LAE',
      icaoCode: 'AYNZ',
      city: 'Lae',
      latitude: -6.5698,
      longitude: 146.7262,
      serviceRadiusKm: 60,
    );
    expect(airport.iataCode, 'LAE');
  });
}
