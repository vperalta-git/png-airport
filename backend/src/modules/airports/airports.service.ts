import { Injectable, Logger, NotFoundException } from '@nestjs/common';
import { FirebaseService } from '../../firebase/firebase.service';

export interface AirportZone {
  id: string;
  name: string;
  zoneType: 'TERMINAL' | 'STAGING' | 'VIP_LOUNGE' | 'PARKING';
  coordinates: { latitude: number; longitude: number };
  instructions: string;
}

export interface AirportEntity {
  id: string;
  code: string; // ICAO e.g. AYNZ, AYPY
  iata: string; // IATA e.g. LAE, POM
  name: string;
  city: string;
  province: string;
  country: string;
  timezone: string;
  location: { latitude: number; longitude: number };
  geofenceRadiusKm: number;
  emergencyHotline: string;
  zones: AirportZone[];
  isActive: boolean;
}

@Injectable()
export class AirportsService {
  private readonly logger = new Logger(AirportsService.name);
  private readonly collectionName = 'airports';

  // In-memory fallback seeds for initial setup & tests
  private static readonly DEFAULT_AIRPORTS: AirportEntity[] = [
    {
      id: 'airport_nadzab_lae',
      code: 'AYNZ',
      iata: 'LAE',
      name: 'Nadzab Tomodachi International Airport',
      city: 'Lae',
      province: 'Morobe Province',
      country: 'Papua New Guinea',
      timezone: 'Pacific/Port_Moresby',
      location: { latitude: -6.5698, longitude: 146.7262 },
      geofenceRadiusKm: 5.0,
      emergencyHotline: '+675 472 0000',
      zones: [
        {
          id: 'zone_nadzab_terminal_arrivals',
          name: 'Main Terminal Arrivals Bay 1-3',
          zoneType: 'TERMINAL',
          coordinates: { latitude: -6.5695, longitude: 146.7260 },
          instructions: 'Designated passenger meet-and-greet curbside staging',
        },
        {
          id: 'zone_nadzab_vip_staging',
          name: 'VIP & Diplomatic Convoy Bay',
          zoneType: 'VIP_LOUNGE',
          coordinates: { latitude: -6.5692, longitude: 146.7265 },
          instructions: 'Dedicated high-security escort vehicle waiting area',
        },
      ],
      isActive: true,
    },
    {
      id: 'airport_jacksons_pom',
      code: 'AYPY',
      iata: 'POM',
      name: "Jackson's International Airport",
      city: 'Port Moresby',
      province: 'National Capital District',
      country: 'Papua New Guinea',
      timezone: 'Pacific/Port_Moresby',
      location: { latitude: -9.4438, longitude: 147.2200 },
      geofenceRadiusKm: 6.0,
      emergencyHotline: '+675 325 0000',
      zones: [
        {
          id: 'zone_pom_intl_arrivals',
          name: 'International Arrivals Staging',
          zoneType: 'TERMINAL',
          coordinates: { latitude: -9.4430, longitude: 147.2195 },
          instructions: 'International terminal commercial transfer pickup lane',
        },
        {
          id: 'zone_pom_domestic_arrivals',
          name: 'Domestic Arrivals Staging',
          zoneType: 'TERMINAL',
          coordinates: { latitude: -9.4445, longitude: 147.2210 },
          instructions: 'Domestic passenger collection zone',
        },
      ],
      isActive: true,
    },
  ];

  constructor(private readonly firebaseService: FirebaseService) {}

  async findAll(): Promise<AirportEntity[]> {
    try {
      const snapshot = await this.firebaseService.firestore
        .collection(this.collectionName)
        .where('isActive', '==', true)
        .get();

      if (snapshot.empty) {
        return AirportsService.DEFAULT_AIRPORTS;
      }

      return snapshot.docs.map((doc) => ({
        id: doc.id,
        ...(doc.data() as Omit<AirportEntity, 'id'>),
      }));
    } catch (e) {
      this.logger.warn(`Firestore read failed, returning default seed airports: ${e.message}`);
      return AirportsService.DEFAULT_AIRPORTS;
    }
  }

  async findById(id: string): Promise<AirportEntity> {
    try {
      const doc = await this.firebaseService.firestore
        .collection(this.collectionName)
        .doc(id)
        .get();

      if (doc.exists) {
        return { id: doc.id, ...(doc.data() as Omit<AirportEntity, 'id'>) };
      }
    } catch (e) {
      this.logger.warn(`Firestore get failed: ${e.message}`);
    }

    const defaultMatch = AirportsService.DEFAULT_AIRPORTS.find(
      (a) => a.id === id || a.code === id || a.iata === id,
    );
    if (!defaultMatch) {
      throw new NotFoundException(`Airport '${id}' not found`);
    }
    return defaultMatch;
  }
}

