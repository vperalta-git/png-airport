import '../models/airport.dart';
import '../models/vehicle_category.dart';
import '../services/png_api_client.dart';

class AirportRepository {
  final PngApiClient apiClient;

  AirportRepository({required this.apiClient});

  // Cached data
  List<Airport>? _cachedAirports;
  List<VehicleCategory>? _cachedVehicleCategories;

  Future<List<Airport>> getAirports({bool forceRefresh = false}) async {
    if (!forceRefresh && _cachedAirports != null && _cachedAirports!.isNotEmpty) {
      return _cachedAirports!;
    }

    try {
      final res = await apiClient.get('/api/v1/airports');
      final list = (res as List<dynamic>).map((e) => Airport.fromJson(e as Map<String, dynamic>)).toList();
      _cachedAirports = list;
      return list;
    } catch (_) {
      // Return high-fidelity seed PNG airports if offline/server disconnected
      _cachedAirports = _getSeedAirports();
      return _cachedAirports!;
    }
  }

  Future<Airport> getAirportDetails(int id) async {
    try {
      final res = await apiClient.get('/api/v1/airports/$id');
      return Airport.fromJson(res as Map<String, dynamic>);
    } catch (_) {
      final all = await getAirports();
      return all.firstWhere((a) => a.id == id, orElse: () => all.first);
    }
  }

  Future<List<VehicleCategory>> getVehicleCategories() async {
    if (_cachedVehicleCategories != null) {
      return _cachedVehicleCategories!;
    }

    try {
      final res = await apiClient.get('/api/v1/vehicle-categories');
      final list = (res as List<dynamic>)
          .map((e) => VehicleCategory.fromJson(e as Map<String, dynamic>))
          .toList();
      _cachedVehicleCategories = list;
      return list;
    } catch (_) {
      _cachedVehicleCategories = _getSeedVehicleCategories();
      return _cachedVehicleCategories!;
    }
  }

  List<Airport> _getSeedAirports() {
    return const [
      Airport(
        id: 1,
        name: "Nadzab Tomodachi International Airport",
        iataCode: "LAE",
        icaoCode: "AYNZ",
        city: "Lae",
        province: "Morobe Province",
        latitude: -6.5698,
        longitude: 146.7262,
        serviceRadiusKm: 60.0,
        arrivalInstructions: "Proceed to Gate 2 Ground Transport Desk or VIP lounge exit.",
        zones: [
          ServiceZone(
            id: 1,
            name: "Lae City & International Hotel",
            code: "LAE-CENTRAL",
            zoneType: "hotel_district",
            riskLevel: "medium",
            pricingZone: "zone_a",
          ),
          ServiceZone(
            id: 2,
            name: "Markham Valley Corridor & Erap Base",
            code: "LAE-MARKHAM",
            zoneType: "high_risk",
            riskLevel: "high",
            pricingZone: "zone_c",
          ),
          ServiceZone(
            id: 3,
            name: "Main Wharf & Industrial Sector",
            code: "LAE-WHARF",
            zoneType: "industrial",
            riskLevel: "medium",
            pricingZone: "zone_b",
          ),
        ],
      ),
      Airport(
        id: 2,
        name: "Jackson's International Airport",
        iataCode: "POM",
        icaoCode: "AYPY",
        city: "Port Moresby",
        province: "National Capital District",
        latitude: -9.4438,
        longitude: 147.2200,
        serviceRadiusKm: 40.0,
        arrivalInstructions: "Meet driver at Terminal 1 curbside designated bays.",
        zones: [
          ServiceZone(
            id: 4,
            name: "Waigani Diplomatic & Government Quarter",
            code: "POM-WAIGANI",
            zoneType: "city",
            riskLevel: "low",
            pricingZone: "zone_a",
          ),
          ServiceZone(
            id: 5,
            name: "Downtown Port Moresby & Stanley Hotel",
            code: "POM-DOWNTOWN",
            zoneType: "hotel_district",
            riskLevel: "low",
            pricingZone: "zone_a",
          ),
        ],
      ),
      Airport(
        id: 3,
        name: "Kagamuga Airport",
        iataCode: "HGU",
        icaoCode: "AYMH",
        city: "Mount Hagen",
        province: "Western Highlands",
        latitude: -5.8268,
        longitude: 144.2960,
        serviceRadiusKm: 50.0,
        arrivalInstructions: "Armed escort meets at arrival security cordon.",
        zones: [
          ServiceZone(
            id: 6,
            name: "Highlands Highway Transit Sector",
            code: "HGU-HIGHWAY",
            zoneType: "high_risk",
            riskLevel: "extreme",
            pricingZone: "zone_c",
          ),
        ],
      ),
    ];
  }

  List<VehicleCategory> _getSeedVehicleCategories() {
    return const [
      VehicleCategory(
        id: 1,
        name: "Executive Sedan",
        code: "SEDAN",
        passengerCapacity: 3,
        baggageCapacity: 2,
        securityRated: false,
        basePriceMultiplier: 1.0,
      ),
      VehicleCategory(
        id: 2,
        name: "Armored Toyota Land Cruiser 4WD",
        code: "ARMORED_LC",
        passengerCapacity: 4,
        baggageCapacity: 4,
        securityRated: true,
        basePriceMultiplier: 1.75,
      ),
      VehicleCategory(
        id: 3,
        name: "Hilux Security Escort Patrol",
        code: "ESCORT_PATROL",
        passengerCapacity: 3,
        baggageCapacity: 3,
        securityRated: true,
        basePriceMultiplier: 1.5,
      ),
      VehicleCategory(
        id: 4,
        name: "Coaster Airport Shuttle Van",
        code: "SHUTTLE_VAN",
        passengerCapacity: 12,
        baggageCapacity: 10,
        securityRated: false,
        basePriceMultiplier: 2.2,
      ),
    ];
  }
}
