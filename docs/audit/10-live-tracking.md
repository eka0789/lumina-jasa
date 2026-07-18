# 10 — Live Tracking Feature Audit

**Audit date:** 2026-07-18  
**Auditor:** Automated + Manual  
**Status:** WARNING (Contains Role Constraint Defect)

---

## 1. Technical Implementation Summary

The location tracking feature is used by customers to track providers traveling to service locations. It runs via a client-side geolocation publisher and a Supabase Realtime Postgres subscription layer.

### System Architecture
- **Publisher:** `booking-tracking.tsx` retrieves the device's GPS coordinates using `navigator.geolocation` and publishes them to the database using the `publish_tracking_point` RPC.
- **Database Storage:** Coordinates are stored in `tracking_points` using a PostGIS `geography(point, 4326)` representation.
- **Subscription:** The customer's browser listens to changes on the `tracking_points` table filtered by `booking_id` via Supabase Realtime.

---

## 2. Security & Geofencing Constraints

The `publish_tracking_point` RPC applies multiple validation rules to prevent fake or spoofed location submissions:

### 1. Geofencing Coordinates (Indonesia Boundary Limits)
Coordinates must fall within the sovereign geographical boundaries of the Republic of Indonesia:
$$\text{Latitude} \in [-11.5^\circ, 6.5^\circ]$$
$$\text{Longitude} \in [94.0^\circ, 142.0^\circ]$$
If coordinates are outside this bounding box, the update is rejected.

### 2. Physical Metric Checks
- GPS accuracy must be within realistic bounds: $\text{Accuracy} \in [0, 5000]$ meters.
- The tracking point timestamp cannot be set in the future: $\text{captured\_at} \le \text{now()} + \text{2 minutes}$.

### 3. State & Actor Access Controls
- Location updates are only allowed if the booking is currently in `'en_route'` or `'in_progress'` status.

---

## 3. Major Defect Identified: Role Lookup Mismatch

During database policy review, a mismatch was found between the roles defined in the database schema and those checked by the tracking function:

### 1. Role Constraints (`0001_initial_schema.sql`)
The `provider_members` table restricts membership roles to three specific choices:
```sql
create table public.provider_members (
  -- ...
  role text not null check (role in ('owner','manager','worker')),
  -- ...
);
```

### 2. Function Check Logic (`0008_ai_realtime_mvp.sql`)
However, the tracking function checks for a different set of roles:
```sql
if b.id is null or not private.is_provider_member(b.provider_id, array['owner','dispatcher','technician']) ... then
  raise exception 'tracking point denied' using errcode = '42501';
end if;
```

### 3. Impact Analysis
Because `'dispatcher'` and `'technician'` cannot be written to `provider_members.role` (which only permits `'owner'`, `'manager'`, `'worker'`), any provider worker (technician) will be rejected by `publish_tracking_point`. **Only the provider owner will be able to publish tracking points.**

### 4. Remediation Plan
Update the role check array in `publish_tracking_point` to include `'worker'` and `'manager'`, or align the role definitions:
```diff
- not private.is_provider_member(b.provider_id, array['owner','dispatcher','technician'])
+ not private.is_provider_member(b.provider_id, array['owner','manager','worker'])
```
