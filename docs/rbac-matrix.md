# Role-Based Access Control (RBAC) Matrix

### 1. Security Groups Definition
The system establishes a multi-tiered security model utilizing Cloud Run & Firebase User Groups (`res.groups`) under the category `Airport Transfer Operations`:

| Role Name | Identifier / Group | Scope | Description |
| :--- | :--- | :--- | :--- |
| **System Administrator** | `group_airport_transfer_admin` | Global / National | Full access to code, server settings, global configs, and all airports. |
| **National Operations Manager**| `group_airport_transfer_national_mgr`| National | View and manage all airports, national analytics, cross-regional fleet reassignments. |
| **Airport Supervisor** | `group_airport_transfer_supervisor` | Multi/Single Airport | Manage local dispatches, approve high-risk escorts, override fares, resolve local incidents. |
| **Control Room Dispatcher**| `group_airport_transfer_dispatcher` | Designated Airport(s) | Real-time map monitoring, dispatch allocation, flight monitoring, P1-P4 alerts. |
| **Driver** | `group_airport_transfer_driver` | Own Assignments | Execute transit stages, submit arrival & dropoff events, view assigned passenger contacts. |
| **Security Personnel** | `group_airport_transfer_security` | Own Escorts | Armed convoy operations, route clearance, security manifests, SOS triggers. |
| **Finance / Invoicing** | `group_airport_transfer_finance` | Commercial | Create & validate customer invoices, manage corporate credit, process refunds. |
| **Corporate Travel Booker**| `group_airport_transfer_corporate_user`| Own Company | Book transfers for company staff, view company manifests, check corporate credit. |
| **Corporate Administrator**| `group_airport_transfer_corporate_admin`| Own Company | Manage company staff directory, cost centers, view consolidated monthly invoices. |
| **Passenger / Customer** | `group_airport_transfer_portal` | Own Bookings | Book personal transfers, view live vehicle ETA, present verification QR. |

---

### 2. Model Permissions Matrix

| Entity | Public / Portal | Driver / Security | Dispatcher | Supervisor | Corporate User | Admin |
| :--- | :---: | :---: | :---: | :---: | :---: | :---: |
| `airport.transfer.airport` | Read (Active) | Read | Read | Read/Write | Read (Active) | Full CRUD |
| `airport.transfer.zone` | Read (Serviceable)| Read | Read | Read/Write | Read (Serviceable)| Full CRUD |
| `airport.transfer.booking` | Read/Create (Own)| Read (Assigned) | Read/Write | Read/Write | Read/Create (Company)| Full CRUD |
| `airport.transfer.passenger` | Read/Create (Own)| Read (Assigned) | Read/Write | Read/Write | Read/Create (Company)| Full CRUD |
| `airport.transfer.dispatch` | None | Read/Update Event| Read/Write | Read/Write/Approve| None | Full CRUD |
| `airport.transfer.incident` | Create SOS (Trip)| Create/Read (Own) | Read/Write | Read/Write/Close | None | Full CRUD |
| `airport.transfer.pricing.rule`| None | None | Read | Read/Write | Read (Negotiated) | Full CRUD |
| `fleet.vehicle` | None | Read (Assigned) | Read/Assign | Read/Write | None | Full CRUD |
| `res.partner` (Corporate) | Read (Own) | None | Read | Read | Read/Write (Company)| Full CRUD |

---

### 3. Record-Level Security Rules (ir.rule)
1. **Driver Assignment Isolation**:
   - `[('driver_id.user_id', '=', user.id)]` — Drivers can only see dispatches and bookings assigned to them.
2. **Corporate Account Isolation**:
   - `[('corporate_account_id.partner_id', 'parent_of', user.partner_id.id)]` — Corporate users are strictly confined to their company's bookings and cost centers.
3. **Airport Supervisor Territorial Scope**:
   - Supervisors restricted to airports where `user.id in airport_id.supervisor_ids.ids` (unless granted national manager privileges).
