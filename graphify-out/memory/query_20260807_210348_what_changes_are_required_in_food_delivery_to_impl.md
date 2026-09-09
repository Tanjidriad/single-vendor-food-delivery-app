---
type: "query"
date: "2026-08-07T21:03:48.235262+00:00"
question: "What changes are required in Food_delivery to implement a 10-branch location-based system?"
contributor: "graphify"
source_nodes: ["Branch", "DeliveryZone", "DeliveryFeeConfig", "Order", "MapsService", "DeliveryFeeService", "ZonesManager", "BranchSwitcher", "OrdersService", "DispatchService"]
---

# Q: What changes are required in Food_delivery to implement a 10-branch location-based system?

## Answer

The existing modular monolith can be evolved rather than rebuilt. Add branch-level delivery zones, fee configuration, hours, availability and a persisted short-lived delivery quote; create a backend-authoritative branch resolver using point-in-polygon then Routes API matrix ranking; derive branchId from quote at order placement; scope kitchen queries, sockets, push and print events to branch rooms; use branch coordinates and optional branch eligibility in rider dispatch; replace the disabled admin branch switcher and radius-only editor with branch CRUD and Google Maps plus Terra Draw polygon editing; add location and selected-branch state to customer web and Flutter clients; replace legacy Distance Matrix and Mapbox implementations with Google Routes, Places, Geocoding and Google Maps SDK before production; migrate and backfill existing data, then validate geometry, overlap, tampering, kitchen isolation, dispatch and provider failure.

## Source Nodes

- Branch
- DeliveryZone
- DeliveryFeeConfig
- Order
- MapsService
- DeliveryFeeService
- ZonesManager
- BranchSwitcher
- OrdersService
- DispatchService
- RealtimeGateway
- RouteService