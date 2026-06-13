import 'package:flutter/material.dart';

import '../../map/geo_point.dart';
import '../../map/map_marker.dart';
import '../../map/mapbox/mapbox_map_view.dart';

/// SDK-neutral map facade used by every screen.
///
/// [AppMapView] keeps its public API free of any map-SDK types
/// (Requirement 10.1, 10.4): callers pass [GeoPoint] for the camera and route,
/// and [MapMarker] for markers. The widget simply delegates rendering to the
/// private Mapbox implementation ([MapboxMapView]) under `core/map/mapbox/`,
/// which performs all `GeoPoint ↔ Position` conversion. Swapping the map SDK
/// only requires replacing that implementation layer — screens stay untouched.
class AppMapView extends StatefulWidget {
  /// SDK-neutral camera center. Falls back to a default when null.
  final GeoPoint? initialCamera;

  /// SDK-neutral route to draw as a polyline.
  final List<GeoPoint>? route;

  /// SDK-neutral markers to render, including the directional rider marker
  /// ([MapMarkerKind.rider]) which uses [MapMarker.headingDegrees].
  final List<MapMarker>? markers;

  const AppMapView({
    super.key,
    this.initialCamera,
    this.route,
    this.markers,
  });

  @override
  State<AppMapView> createState() => _AppMapViewState();
}

class _AppMapViewState extends State<AppMapView> {
  @override
  Widget build(BuildContext context) {
    return MapboxMapView(
      initialCamera: widget.initialCamera,
      route: widget.route,
      markers: widget.markers,
    );
  }
}
