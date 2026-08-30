---
type: "query"
date: "2026-08-07T20:54:39.066626+00:00"
question: "Mapbox is installed now and will be replaced with Google Maps before production"
contributor: "graphify"
source_nodes: ["MapsService", "Branch", "DeliveryZone", "Order", "RouteService", "AppMapView"]
---

# Q: Mapbox is installed now and will be replaced with Google Maps before production

## Answer

Recommended keeping Mapbox during development behind the existing SDK-neutral facades, then migrating to Google Maps before production. Do not use the removed Google Drawing Library; use a custom Google Maps polygon editor in Flutter admin or Google Maps plus Terra Draw for a web admin. Replace the backend legacy Distance Matrix endpoint with Routes API Compute Route Matrix. Before provider migration, add true branch-level zones, fee configuration, automatic branch resolution, overlap tie-breaking, signed quote locking, and branch-aware kitchen dispatch because the current zones and fee configuration are restaurant-level although Branch and Order.branchId already exist.

## Source Nodes

- MapsService
- Branch
- DeliveryZone
- Order
- RouteService
- AppMapView