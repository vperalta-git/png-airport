import { Injectable, Logger, NotFoundException } from '@nestjs/common';
import { v4 as uuidv4 } from 'uuid';
import { FirebaseService } from '../../firebase/firebase.service';
import { GpsCoordinate } from '../trips/trips.service';

export type IncidentPriority = 'P1_CRITICAL' | 'P2_HIGH' | 'P3_MEDIUM' | 'P4_LOW';
export type IncidentCategory =
  | 'ARMED_ATTACK_OR_AMBUSH'
  | 'ROAD_BLOCKAGE_OR_PROTEST'
  | 'VEHICLE_MECHANICAL_FAILURE'
  | 'SUSPECTED_SURVEILLANCE'
  | 'MEDICAL_EMERGENCY'
  | 'ACCIDENT_OR_COLLISION'
  | 'SEVERE_WEATHER_LANDSLIDE'
  | 'PASSENGER_DISPUTE_OR_MISCONDUCT';

export interface IncidentReportDto {
  bookingId?: string;
  vehicleId?: string;
  driverId?: string;
  securityOfficerId?: string;
  priority: IncidentPriority;
  category: IncidentCategory;
  location: GpsCoordinate;
  description: string;
  photoAttachments?: string[];
}

export interface IncidentEntity {
  id: string;
  referenceNumber: string; // INC-YYYYMMDD-XXXX
  bookingId?: string;
  vehicleId?: string;
  driverId?: string;
  securityOfficerId?: string;
  priority: IncidentPriority;
  category: IncidentCategory;
  location: GpsCoordinate;
  description: string;
  status: 'ACTIVE_EMERGENCY' | 'UNDER_INVESTIGATION' | 'CONTAINED' | 'RESOLVED';
  qrfDispatched: boolean; // Quick Response Force
  reportedAt: string;
  resolvedAt?: string;
  resolutionNotes?: string;
  photoAttachments: string[];
}

@Injectable()
export class IncidentsService {
  private readonly logger = new Logger(IncidentsService.name);
  private readonly incidentsCollection = 'incidents';

  constructor(private readonly firebaseService: FirebaseService) {}

  async reportIncident(dto: IncidentReportDto, reporterUid: string = 'field_officer'): Promise<IncidentEntity> {
    const now = new Date();
    const yyyy = now.getFullYear();
    const mm = String(now.getMonth() + 1).padStart(2, '0');
    const dd = String(now.getDate()).padStart(2, '0');
    const rand = Math.floor(1000 + Math.random() * 9000).toString();
    const refNum = `INC-${yyyy}${mm}${dd}-${rand}`;

    const incidentId = `INC-${uuidv4().substring(0, 8).toUpperCase()}`;

    const incident: IncidentEntity = {
      id: incidentId,
      referenceNumber: refNum,
      bookingId: dto.bookingId,
      vehicleId: dto.vehicleId,
      driverId: dto.driverId,
      securityOfficerId: dto.securityOfficerId,
      priority: dto.priority,
      category: dto.category,
      location: dto.location,
      description: dto.description,
      status: 'ACTIVE_EMERGENCY',
      qrfDispatched: dto.priority === 'P1_CRITICAL',
      reportedAt: now.toISOString(),
      photoAttachments: dto.photoAttachments || [],
    };

    try {
      await this.firebaseService.firestore
        .collection(this.incidentsCollection)
        .doc(incidentId)
        .set(incident);

      // Broadcast emergency alert via Realtime Database for zero-latency Control Room alarm
      await this.firebaseService.rtdb.ref(`operational_alerts/${incidentId}`).set({
        type: 'EMERGENCY_INCIDENT',
        priority: dto.priority,
        category: dto.category,
        referenceNumber: refNum,
        bookingId: dto.bookingId,
        latitude: dto.location.latitude,
        longitude: dto.location.longitude,
        description: dto.description,
        timestamp: now.toISOString(),
      });
    } catch (e) {
      this.logger.error(`Failed to broadcast incident: ${e.message}`);
    }

    this.logger.warn(`EMERGENCY: Incident ${refNum} (${dto.priority}) logged for booking ${dto.bookingId}`);
    return incident;
  }

  async listActiveIncidents(): Promise<IncidentEntity[]> {
    try {
      const snap = await this.firebaseService.firestore
        .collection(this.incidentsCollection)
        .where('status', 'in', ['ACTIVE_EMERGENCY', 'UNDER_INVESTIGATION'])
        .get();

      return snap.docs.map((d) => d.data() as IncidentEntity);
    } catch (e) {
      this.logger.warn(`Firestore read error: ${e.message}`);
      return [];
    }
  }

  async resolveIncident(
    incidentId: string,
    notes: string,
    resolverId: string,
  ): Promise<IncidentEntity> {
    const docRef = this.firebaseService.firestore.collection(this.incidentsCollection).doc(incidentId);
    const doc = await docRef.get();
    if (!doc.exists) throw new NotFoundException(`Incident '${incidentId}' not found`);

    const incident = doc.data() as IncidentEntity;
    const now = new Date().toISOString();
    incident.status = 'RESOLVED';
    incident.resolvedAt = now;
    incident.resolutionNotes = notes;

    await docRef.set(incident, { merge: true });

    // Remove from active alerts in RTDB
    await this.firebaseService.rtdb.ref(`operational_alerts/${incidentId}`).remove();

    return incident;
  }
}

