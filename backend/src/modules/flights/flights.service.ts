import { Injectable, Logger, NotFoundException } from '@nestjs/common';
import { FirebaseService } from '../../firebase/firebase.service';
import { BookingsService } from '../bookings/bookings.service';

export interface FlightTrackingRecord {
  flightNumber: string; // e.g. PX 102, CG 8520
  airlineCode: 'PX' | 'CG' | 'OTHER';
  airlineName: string;
  originAirport: string; // IATA e.g. POM
  destinationAirport: string; // IATA e.g. LAE
  scheduledDeparture: string;
  scheduledArrival: string;
  estimatedArrival: string;
  actualArrival?: string;
  status: 'SCHEDULED' | 'AIRBORNE' | 'DELAYED' | 'LANDED' | 'CANCELLED';
  delayMinutes: number;
  aircraftType?: string;
  altitudeFt?: number;
  groundSpeedKts?: number;
  lastUpdated: string;
}

@Injectable()
export class FlightsService {
  private readonly logger = new Logger(FlightsService.name);
  private readonly flightsCollection = 'flights';
  private readonly flightEventsCollection = 'flight_status_events';

  // Seed / Simulated radar records for Air Niugini & PNG Air
  private static readonly MOCK_FLIGHTS: Record<string, FlightTrackingRecord> = {
    'PX 102': {
      flightNumber: 'PX 102',
      airlineCode: 'PX',
      airlineName: 'Air Niugini',
      originAirport: 'POM',
      destinationAirport: 'LAE',
      scheduledDeparture: new Date(Date.now() - 40 * 60 * 1000).toISOString(),
      scheduledArrival: new Date(Date.now() + 20 * 60 * 1000).toISOString(),
      estimatedArrival: new Date(Date.now() + 20 * 60 * 1000).toISOString(),
      status: 'AIRBORNE',
      delayMinutes: 0,
      aircraftType: 'Boeing 737-800',
      altitudeFt: 22000,
      groundSpeedKts: 410,
      lastUpdated: new Date().toISOString(),
    },
    'PX 104': {
      flightNumber: 'PX 104',
      airlineCode: 'PX',
      airlineName: 'Air Niugini',
      originAirport: 'POM',
      destinationAirport: 'LAE',
      scheduledDeparture: new Date(Date.now() + 120 * 60 * 1000).toISOString(),
      scheduledArrival: new Date(Date.now() + 170 * 60 * 1000).toISOString(),
      estimatedArrival: new Date(Date.now() + 170 * 60 * 1000).toISOString(),
      status: 'SCHEDULED',
      delayMinutes: 0,
      aircraftType: 'Fokker 100',
      lastUpdated: new Date().toISOString(),
    },
    'CG 8520': {
      flightNumber: 'CG 8520',
      airlineCode: 'CG',
      airlineName: 'PNG Air',
      originAirport: 'POM',
      destinationAirport: 'LAE',
      scheduledDeparture: new Date(Date.now() - 30 * 60 * 1000).toISOString(),
      scheduledArrival: new Date(Date.now() + 35 * 60 * 1000).toISOString(),
      estimatedArrival: new Date(Date.now() + 65 * 60 * 1000).toISOString(),
      status: 'DELAYED',
      delayMinutes: 30,
      aircraftType: 'ATR 72-600',
      altitudeFt: 18000,
      groundSpeedKts: 280,
      lastUpdated: new Date().toISOString(),
    },
  };

  constructor(
    private readonly firebaseService: FirebaseService,
    private readonly bookingsService: BookingsService,
  ) {}

  async getFlightStatus(flightNumber: string): Promise<FlightTrackingRecord> {
    const normalized = flightNumber.trim().toUpperCase();

    // Check Firestore first
    try {
      const doc = await this.firebaseService.firestore
        .collection(this.flightsCollection)
        .doc(normalized.replace(/\s+/g, '_'))
        .get();

      if (doc.exists) {
        return doc.data() as FlightTrackingRecord;
      }
    } catch (e) {
      this.logger.warn(`Firestore read failed for flight: ${e.message}`);
    }

    // Fallback to simulated live radar
    const mock = FlightsService.MOCK_FLIGHTS[normalized];
    if (mock) {
      return mock;
    }

    // Default generic record
    const now = new Date();
    return {
      flightNumber: normalized,
      airlineCode: normalized.startsWith('PX') ? 'PX' : normalized.startsWith('CG') ? 'CG' : 'OTHER',
      airlineName: normalized.startsWith('PX') ? 'Air Niugini' : 'PNG Air',
      originAirport: 'POM',
      destinationAirport: 'LAE',
      scheduledDeparture: new Date(now.getTime() - 30 * 60 * 1000).toISOString(),
      scheduledArrival: new Date(now.getTime() + 30 * 60 * 1000).toISOString(),
      estimatedArrival: new Date(now.getTime() + 30 * 60 * 1000).toISOString(),
      status: 'AIRBORNE',
      delayMinutes: 0,
      lastUpdated: now.toISOString(),
    };
  }

  async updateFlightDelay(
    flightNumber: string,
    delayMinutes: number,
    reason: string = 'Weather disruption over Markham Valley',
  ): Promise<FlightTrackingRecord> {
    const flight = await this.getFlightStatus(flightNumber);
    const scheduledDate = new Date(flight.scheduledArrival);
    const newEstimatedDate = new Date(scheduledDate.getTime() + delayMinutes * 60 * 1000);

    flight.delayMinutes = delayMinutes;
    flight.estimatedArrival = newEstimatedDate.toISOString();
    flight.status = delayMinutes > 15 ? 'DELAYED' : 'AIRBORNE';
    flight.lastUpdated = new Date().toISOString();

    const docId = flightNumber.trim().toUpperCase().replace(/\s+/g, '_');

    try {
      await this.firebaseService.firestore
        .collection(this.flightsCollection)
        .doc(docId)
        .set(flight, { merge: true });

      // Record flight event
      await this.firebaseService.firestore.collection(this.flightEventsCollection).add({
        flightNumber,
        delayMinutes,
        newEta: flight.estimatedArrival,
        reason,
        timestamp: new Date().toISOString(),
      });
    } catch (e) {
      this.logger.warn(`Could not save flight update: ${e.message}`);
    }

    this.logger.log(`Flight ${flightNumber} updated with ${delayMinutes}m delay. New ETA: ${flight.estimatedArrival}`);
    return flight;
  }
}

