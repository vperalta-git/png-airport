# Control Room Operations & Pilot Deployment Runbook
**Location:** Lae, Morobe Province, Papua New Guinea  
**Aviation Gateway:** Nadzab Tomodachi International Airport (AYNZ / LAE)  
**Primary Highway Corridor:** Markham Valley / Highlands Highway (42.5 km)

---

## 1. Control Room Operational Workflow

### Stage 1: Incoming Booking Reception & Availability
1. When a new transfer request enters the queue (`BOOKING_REQUESTED`), the Control Room operator verifies:
   - Flight number and airline (Air Niugini `PX` or PNG Air `CG`).
   - Estimated arrival time against live radar.
   - Number of passengers and luggage requirements (determining vehicle category: 4WD LandCruiser 79, Armored Prado, or Coaster Bus).
   - Security requirement (Armed chase car or Close Protection Convoy).
2. The availability engine automatically locks candidate resources (`resource_reservations`) to prevent double-booking.

### Stage 2: Pre-Flight Staging Target Calculation
- Standard Touchdown-to-Curbside clearing time at Nadzab:
  - Domestic arrivals: **25 minutes** (baggage collection).
  - VIP / Chartered arrivals: **15 minutes**.
- Recommended staging arrival for driver: **15 minutes prior to aircraft touchdown**.

### Stage 3: Flight Delay Recalculation
- When Air Niugini or PNG Air reports a delay:
  1. The Cloud Run flight service recalculates `recommendedPickupDatetime = touchdown + 25m`.
  2. If the delay exceeds 30 minutes, an automated notification is dispatched to the assigned driver and passenger.
  3. The Control Room radar board marks the flight in amber (`DELAYED`) and adjusts the dispatch timeline.

### Stage 4: Passenger Meet & Verification at Nadzab Terminal
- Driver stages at designated bay (Bay 1-3) and displays digital meeting board.
- Driver scans the passenger's cryptographic QR code or enters the 6-digit offline OTP (`482910`).
- The system confirms match against the manifest, advancing the state to `PASSENGER_VERIFIED` $\rightarrow$ `PASSENGER_ONBOARD`.

### Stage 5: Transit & Highway Corridor Monitoring
- Highway transit speed along the Markham Valley corridor is monitored via Firebase Realtime Database telemetry.
- Speed limit: **80 km/h** (rural highway), **50 km/h** (Lae urban limits).
- If a vehicle halts unexpectedly for > 5 minutes outside designated checkpoints:
  - Control Room initiates VHF voice radio check (`Channel 3 - 156.800 MHz`).
  - If no response within 2 minutes, dispatch Standby Quick Response Force (QRF).

### Stage 6: Emergency SOS Protocol (P1 Attack / Ambush / Rollover)
- If Driver or Security Officer triggers the **ONE-TOUCH EMERGENCY SOS**:
  1. Audio siren and red visual strobe triggers across all Control Room consoles.
  2. Live GPS location locks onto satellite map.
  3. Immediate phone/radio contact to RPNGC Morobe Provincial Police Command (`+675 472 0000`).
  4. Quick Response Force (QRF) LandCruiser deployed from Nadzab Base Depot.

### Stage 7: Destination Arrival & e-POD Closeout
- Driver arrives at destination (e.g. Lae International Hotel, Crossroads Hotel, or industrial port facility).
- Passenger signs electronic Proof of Delivery (e-POD) on mobile screen.
- Booking status advances to `COMPLETED`:
  - Automatically releases vehicle, driver, and guard reservations.
  - Automatically triggers IRC PNG Tax Invoice generation with 10% GST.
  - Initiates 80/20 partner fleet revenue settlement.

---

## 2. Emergency Contacts Directory (Morobe Province)

| Agency | Contact | Frequency / Number |
| :--- | :--- | :--- |
| **Control Room Base Command** | Dispatch Desk | VHF 156.800 MHz / +675 472 8899 |
| **RPNGC Police Headquarters Lae** | Morobe Police Command | +675 472 2222 / 112 |
| **Nadzab Airport Operations** | NAC Airport Duty Officer | +675 472 0000 |
| **Angau Memorial Hospital** | Emergency Ambulance | +675 472 5555 |
| **St. John Ambulance PNG** | National Emergency Response | 111 |

