import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

import '../../theme/app_colors.dart';
import '../geo_point.dart';
import '../map_marker.dart';
import 'coordinate_conversions.dart';

/// The Mapbox-backed implementation of the map view.
///
/// This widget is the implementation layer behind the SDK-neutral
/// [AppMapView] facade (`core/widgets/map/app_map_view.dart`). It is the only
/// map-rendering widget allowed to import `mapbox_maps_flutter`
/// (Requirement 10.4) and it converts the SDK-neutral [GeoPoint]/[MapMarker]
/// inputs into Mapbox [Position]/annotation types via the conversion
/// extensions in `coordinate_conversions.dart`.
///
/// A Mapbox → Google Maps migration would replace this file (and its sibling
/// implementation files) without touching any screen.
class MapboxMapView extends StatefulWidget {
  /// SDK-neutral camera center. Falls back to Dhaka when null.
  final GeoPoint? initialCamera;

  /// SDK-neutral route to draw as a polyline.
  final List<GeoPoint>? route;

  /// SDK-neutral markers to render. Markers of kind [MapMarkerKind.rider] are
  /// drawn as a directional arrow rotated by [MapMarker.headingDegrees]
  /// (Requirement 6.6); all other markers are drawn as circles.
  final List<MapMarker>? markers;

  const MapboxMapView({
    super.key,
    this.initialCamera,
    this.route,
    this.markers,
  });

  @override
  State<MapboxMapView> createState() => _MapboxMapViewState();
}

class _MapboxMapViewState extends State<MapboxMapView> {
  /// Default camera center (Dhaka) preserved from the original implementation.
  static final Position _dhaka = Position(90.4125, 23.8103);

  MapboxMap? _mapboxMap;
  PolylineAnnotationManager? _polylineManager;
  CircleAnnotationManager? _circleManager;
  PointAnnotationManager? _pointManager;
  bool _isDisposed = false;

  /// Cached directional rider marker bitmap (PNG bytes), generated lazily.
  Uint8List? _riderIcon;

  @override
  void didUpdateWidget(MapboxMapView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_mapboxMap != null &&
        (!_geoListEquals(widget.route, oldWidget.route) ||
            !_markerListEquals(widget.markers, oldWidget.markers))) {
      unawaited(_drawAnnotations());
    }
  }

  Future<void> _onMapCreated(MapboxMap mapboxMap) async {
    if (!mounted || _isDisposed) return;
    _mapboxMap = mapboxMap;

    try {
      _polylineManager =
          await mapboxMap.annotations.createPolylineAnnotationManager();
      _circleManager =
          await mapboxMap.annotations.createCircleAnnotationManager();
      _pointManager =
          await mapboxMap.annotations.createPointAnnotationManager();
    } on MissingPluginException catch (e) {
      debugPrint(
        '[MapboxMapView] Plugin channel unavailable during manager creation: $e',
      );
      return;
    } on PlatformException catch (e) {
      debugPrint(
        '[MapboxMapView] Platform error during manager creation: $e',
      );
      return;
    }

    await _drawAnnotations();
  }

  Future<void> _drawAnnotations() async {
    if (!mounted || _isDisposed) return;
    final map = _mapboxMap;
    if (map == null) return;

    // Clear old annotations across all managers.
    try {
      await _polylineManager?.deleteAll();
      await _circleManager?.deleteAll();
      await _pointManager?.deleteAll();
    } on PlatformException catch (e) {
      debugPrint(
        '[MapboxMapView] Annotation channels were torn down; recreating managers: $e',
      );
      // Android GL surface can be destroyed while this widget still exists.
      // Recreate annotation managers and continue instead of crashing.
      try {
        _polylineManager =
            await map.annotations.createPolylineAnnotationManager();
        _circleManager = await map.annotations.createCircleAnnotationManager();
        _pointManager = await map.annotations.createPointAnnotationManager();
      } on MissingPluginException catch (recreateErr) {
        debugPrint(
          '[MapboxMapView] Plugin missing while recreating managers: $recreateErr',
        );
        return;
      } on PlatformException catch (recreateErr) {
        debugPrint(
          '[MapboxMapView] Platform error while recreating managers: $recreateErr',
        );
        return;
      } catch (recreateErr) {
        debugPrint(
          '[MapboxMapView] Could not recreate annotation managers: $recreateErr',
        );
        return;
      }
    } catch (e) {
      debugPrint('[MapboxMapView] Failed to clear annotations: $e');
      return;
    }

    final route = widget.route;
    if (route != null && route.isNotEmpty) {
      final positions = route.map((p) => p.toPosition()).toList();

      await _polylineManager?.create(
        PolylineAnnotationOptions(
          geometry: LineString(coordinates: positions),
          lineColor: AppColors.primary.toARGB32(),
          lineWidth: 5.0,
          lineJoin: LineJoin.ROUND,
        ),
      );

      // Fit the camera to the route bounds.
      try {
        final cameraOptions = await map.cameraForCoordinatesPadding(
          positions.map((p) => Point(coordinates: p)).toList(),
          CameraOptions(),
          MbxEdgeInsets(top: 100.0, left: 50.0, bottom: 400.0, right: 50.0),
          null,
          null,
        );
        await map.flyTo(cameraOptions, MapAnimationOptions(duration: 1000));
      } catch (e) {
        debugPrint('Error fitting camera to route: $e');
      }
    }

    final markers = widget.markers;
    if (markers != null && markers.isNotEmpty) {
      // Non-rider markers render as circles (preserves prior behavior).
      final circleOptions = markers
          .where((m) => m.kind != MapMarkerKind.rider)
          .map(
            (m) => CircleAnnotationOptions(
              geometry: Point(coordinates: m.point.toPosition()),
              circleColor: _colorForKind(m.kind).toARGB32(),
              circleRadius: 8.0,
              circleStrokeColor: Colors.white.toARGB32(),
              circleStrokeWidth: 3.0,
            ),
          )
          .toList();
      if (circleOptions.isNotEmpty) {
        await _circleManager?.createMulti(circleOptions);
      }

      // Rider markers render as a directional arrow rotated by heading.
      final riderMarkers =
          markers.where((m) => m.kind == MapMarkerKind.rider).toList();
      if (riderMarkers.isNotEmpty) {
        final icon = await _riderMarkerIcon();
        for (final marker in riderMarkers) {
          await _pointManager?.create(
            PointAnnotationOptions(
              geometry: Point(coordinates: marker.point.toPosition()),
              image: icon,
              iconSize: 1.0,
              // Mapbox rotates the icon clockwise in degrees, matching a
              // compass heading where 0 == north.
              iconRotate: marker.headingDegrees ?? 0.0,
            ),
          );
        }
      }
    }
  }

  /// Marker fill color per kind, staying within the brand palette.
  Color _colorForKind(MapMarkerKind kind) {
    switch (kind) {
      case MapMarkerKind.pickup:
        return AppColors.primary;
      case MapMarkerKind.dropoff:
        return AppColors.busy;
      case MapMarkerKind.rider:
      case MapMarkerKind.generic:
        return AppColors.primary;
    }
  }

  /// Lazily builds (and caches) the directional rider marker bitmap: a brand
  /// arrow on a white disc, drawn pointing up so Mapbox's clockwise
  /// `iconRotate` aligns it with the rider heading (Requirement 6.6).
  Future<Uint8List> _riderMarkerIcon() async {
    final cached = _riderIcon;
    if (cached != null) return cached;

    const size = 72.0;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final center = Offset(size / 2, size / 2);
    final radius = size / 2 - 4;

    canvas.drawCircle(center, radius, Paint()..color = Colors.white);
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = AppColors.primary
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0,
    );

    final arrow = Path()
      ..moveTo(center.dx, size * 0.20) // tip (north)
      ..lineTo(size * 0.72, size * 0.76) // bottom-right
      ..lineTo(center.dx, size * 0.60) // inner notch
      ..lineTo(size * 0.28, size * 0.76) // bottom-left
      ..close();
    canvas.drawPath(arrow, Paint()..color = AppColors.primary);

    final image =
        await recorder.endRecording().toImage(size.toInt(), size.toInt());
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    final result = bytes!.buffer.asUint8List();
    _riderIcon = result;
    return result;
  }

  @override
  void dispose() {
    _isDisposed = true;
    _polylineManager = null;
    _circleManager = null;
    _pointManager = null;
    _mapboxMap = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final center = widget.initialCamera?.toPosition() ?? _dhaka;
    return MapWidget(
      key: const ValueKey('mapWidget'),
      onMapCreated: _onMapCreated,
      // ignore: deprecated_member_use — removed in the planned Mapbox→Google Maps migration.
      cameraOptions: CameraOptions(
        center: Point(coordinates: center),
        zoom: 14.0,
      ),
      styleUri: MapboxStyles.LIGHT,
    );
  }
}

bool _geoListEquals(List<GeoPoint>? a, List<GeoPoint>? b) {
  if (identical(a, b)) return true;
  if (a == null || b == null || a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

bool _markerListEquals(List<MapMarker>? a, List<MapMarker>? b) {
  if (identical(a, b)) return true;
  if (a == null || b == null || a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
