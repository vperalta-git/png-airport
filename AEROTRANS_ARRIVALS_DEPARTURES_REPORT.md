# Separate Arrivals and Departures

Updated: 10 November 2026. PNG2 NestJS/Firebase/Flutter retained.

## Completed

- Separate Arrivals and Departures queues for Customer, Control Room, Driver and
  Supervisor; retained All transfers and per-section Active/History/All filters.
- Separate customer booking entry with the selected direction fixed before quoting.
  Arrival form collects the Lae drop-off address; departure form collects the Lae
  pickup address. Details label both endpoints and lists identify direction.
- Selected section/status chips use white text on navy for clear contrast.
- Dedicated authenticated `/api/v1/bookings/arrivals` and `/departures` endpoints
  preserve tenant, branch, airport, customer and assigned-driver restrictions.
- Independent backend arrival/departure operational summaries, while existing
  totals and the aggregate booking endpoint remain available.
- Correct direction-specific driver workflow: airport pickup (`AT_AIRPORT`) for
  arrivals; customer-location pickup (`AT_PICKUP`) for departures, followed by
  airport drop-off. Both require accepted inspection and backend pickup OTP.
- Shared resource locks prevent assigning the same driver/vehicle to simultaneous
  arrival and departure work. Trip completion still leaves payment unverified.
- Updated TypeScript/Dart enum contract, fixtures and offline source adapter.
  Existing APK files, accounts, fleet records and existing bookings were not reset.

## Modified source

Backend bookings controller/service and reports service; shared TypeScript v1
contract, enum fixture and contract tests; shared Flutter contract model, booking
screens, offline adapter and focused UI/contract/offline tests; connected test fakes;
hosted API/browser acceptance scripts; README.md; docs/website.md; docs/contracts-v1.md;
docs/arrivals-departures.md; update.txt; this report.

A local checkpoint was taken before editing. Source updates use the separate clean
publication checkout, retaining the original repository history, index and origin.
Only the isolated Firebase test environment is used; airport-png-c866b is unchanged.

## Verification

- Backend compilation passed; 39 unit tests passed.
- Six shared TypeScript contract tests passed, including rejection of the wrong
  pickup state and attempts to bypass OTP with an ordinary status update.
- Flutter analysis clean. Shared regression suite: 51 passed, 5 offline-flag-only
  UI cases skipped normally. A separate run with AEROTRANS_OFFLINE_DEMO=true
  passed all 5 offline UI cases. Focused offline workflow tests: 7 passed;
  Dart contract/parser tests: 7 passed.
- Real hosted API acceptance passed for both full transfer directions, including
  departure OTP at the customer location, completion/payment separation, endpoint
  filtering/ownership and cross-direction driver/vehicle reservation conflicts.
- Website release build/deployment succeeded for commit 3db726b at
  https://png-airport-kappa.vercel.app. Real Edge checks passed for all four
  desktop roles and Customer at 390px, including arrival/departure switching,
  departure booking entry visibility, scoped API reads and account switching.
  Supervisor management remains accessible. No localhost/live-project requests
  or browser runtime errors were observed. Full trip execution was API-tested;
  not every booking action was clicked through in the browser.
  No physical-device or production test is claimed.

## Compatibility and remaining work

The v1 field destinationAddress retains its existing city-endpoint meaning: arrival
drop-off or departure pickup. Airport endpoint comes from airportId. Direction is
fixed by the server quotation. Refresh existing website tabs for the new parser.

No flight schedules/provider integration, airline check-in buffers, commercial
tariffs or tax policies were invented. Future work can add operator-approved flight
metadata and explicit pickup/drop-off objects in a versioned contract migration.
Existing exported APKs have not been rebuilt; hosted native Android configuration
and physical-phone acceptance remain separate work.
