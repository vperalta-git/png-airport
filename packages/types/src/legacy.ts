/** Legacy UI/domain declarations retained for the later app migration. Not a wire contract. */
/**
 * Core Domain Types for Papua New Guinea Airport Ground Transportation & Security Operations Platform
 */

export type UserRole =
  | "passenger"
  | "driver"
  | "security"
  | "dispatcher"
  | "supervisor"
  | "corporate"
  | "admin";

export type BookingState =
  | "draft"
  | "quotation"
  | "awaiting_payment"
  | "confirmed"
  | "flight_monitoring"
  | "resource_planning"
  | "ready_for_dispatch"
  | "dispatched"
  | "driver_en_route"
  | "at_airport"
  | "passenger_located"
  | "passenger_verified"
  | "passenger_onboard"
  | "transfer_in_progress"
  | "arrived_destination"
  | "passenger_dropped_off"
  | "completed"
  | "invoiced"
  | "closed"
  | "on_hold"
  | "cancelled"
  | "no_show"
  | "flight_cancelled"
  | "incident"
  | "aborted";

export type RiskLevel = "low" | "medium" | "high" | "extreme";

export interface Airport {
  id: number;
  name: string;
  iata_code: string;
  icao_code: string;
  city: string;
  province?: string;
  timezone: string;
  latitude: number;
  longitude: number;
  service_radius_km: number;
  transfer_enabled: boolean;
  security_service_enabled: boolean;
  meet_greet_enabled: boolean;
  arrival_instructions?: string;
  departure_instructions?: string;
  emergency_contact?: string;
  zones?: ServiceZone[];
}

export interface ServiceZone {
  id: number;
  name: string;
  code: string;
  zone_type: string;
  risk_level: RiskLevel;
  pricing_zone: string;
  center_latitude?: number;
  center_longitude?: number;
  radius_km?: number;
}

export interface VehicleCategory {
  id: number;
  name: string;
  code: string;
  passenger_capacity: number;
  baggage_capacity: number;
  security_rated: boolean;
  base_price_multiplier: number;
  icon?: string;
}

export interface Passenger {
  id?: number;
  first_name: string;
  last_name: string;
  name?: string;
  mobile?: string;
  email?: string;
  passenger_type: "primary" | "guest" | "vip" | "employee" | "crew";
  verification_status?: "pending" | "verified" | "failed";
  qr_token?: string;
  otp?: string;
}

export interface QuoteRequest {
  airport_id: number;
  zone_id?: number;
  vehicle_category_id?: number;
  distance_km?: number;
  security_required?: boolean;
  meet_greet_required?: boolean;
  corporate_account_id?: number;
}

export interface QuoteResponse {
  base_fare: number;
  distance_km: number;
  distance_charge: number;
  airport_fee: number;
  meet_greet_fee: number;
  security_escort_fee: number;
  after_hours_fee: number;
  subtotal: number;
  tax_amount: number;
  total: number;
  currency: string;
  rule_applied_id?: number;
  rule_name?: string;
}

export interface Booking {
  id: number;
  name: string;
  state: BookingState;
  airport: {
    id: number;
    name: string;
    iata: string;
  };
  pickup_location: string;
  destination: string;
  pickup_datetime: string;
  flight_number?: string;
  total_fare: number;
  payment_status: string;
  security_required: boolean;
  passengers: Passenger[];
  timeline?: OperationalTimelineEvent[];
}

export interface OperationalTimelineEvent {
  event: string;
  name: string;
  timestamp: string;
  user?: string;
}

export interface OfflineSyncEvent {
  uuid: string;
  event_type: string;
  booking_id: number;
  payload: Record<string, unknown>;
  local_timestamp: string;
  latitude?: number;
  longitude?: number;
  sync_status: "pending" | "synced" | "failed";
  retry_count: number;
}

export interface ApiResponse<T> {
  success: boolean;
  data: T | null;
  meta: {
    timestamp: string;
    request_id?: string;
  };
  error: {
    code: string;
    message: string;
  } | null;
}
