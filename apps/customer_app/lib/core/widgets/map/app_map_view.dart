import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

import '../../map/models/app_map_route_point.dart';
import '../../theme/app_colors.dart';
import 'models/app_map_controller.dart';
import 'models/app_map_marker.dart';

class AppMapboxController implements AppMapController {
  AppMapboxController(this.mapboxMap);

  final MapboxMap mapboxMap;

  @override
  Future<void> animateTo(
    double latitude,
    double longitude, {
    double zoom = 15.0,
  }) async {
    final cameraOptions = CameraOptions(
      center: Point(coordinates: Position(longitude, latitude)),
      zoom: zoom,
    );
    await mapboxMap.flyTo(cameraOptions, MapAnimationOptions(duration: 500));
  }

  @override
  Future<void> fitBounds(
    double minLat,
    double minLng,
    double maxLat,
    double maxLng,
  ) async {
    final cameraOptions = await mapboxMap.cameraForCoordinateBounds(
      CoordinateBounds(
        southwest: Point(coordinates: Position(minLng, minLat)),
        northeast: Point(coordinates: Position(maxLng, maxLat)),
        infiniteBounds: false,
      ),
      MbxEdgeInsets(top: 48, left: 48, bottom: 48, right: 48),
      null,
      null,
      null,
      null,
    );
    await mapboxMap.flyTo(cameraOptions, MapAnimationOptions(duration: 500));
  }
}

/// Mapbox-backed map used on order tracking, checkout, and address picker.
class AppMapView extends StatefulWidget {
  const AppMapView({
    super.key,
    required this.initialLatitude,
    required this.initialLongitude,
    required this.markers,
    this.route = const [],
    this.onMapCreated,
    this.onTap,
    this.fitMarkersInView = true,
  });

  final double initialLatitude;
  final double initialLongitude;
  final List<AppMapMarker> markers;
  final List<AppMapRoutePoint> route;
  final ValueChanged<AppMapController>? onMapCreated;
  final ValueChanged<AppMapMarker>? onTap;
  final bool fitMarkersInView;

  @override
  State<AppMapView> createState() => _AppMapViewState();
}

class _AppMapViewState extends State<AppMapView> {
  MapboxMap? _mapboxMap;
  PointAnnotationManager? _pointManager;
  PolylineAnnotationManager? _polylineManager;
  bool _mapReady = false;
  bool _styleLoaded = false;
  String? _lastAnnotationSignature;

  static final Map<int, Uint8List> _iconCache = {};
  Uint8List? _riderArrowIcon;

  @override
  void didUpdateWidget(covariant AppMapView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_styleLoaded &&
        (widget.markers != oldWidget.markers ||
            widget.route != oldWidget.route)) {
      unawaited(_syncAnnotations());
    }
  }

  Color _colorForMarker(AppMapMarker marker) {
    switch (marker.id) {
      case 'rider':
        return const Color(0xFF22C55E);
      case 'restaurant':
        return const Color(0xFFF59E0B);
      case 'home':
      case 'delivery':
        return const Color(0xFF3B82F6);
      default:
        return AppColors.secondary500;
    }
  }

  double _iconScaleForMarker(AppMapMarker marker) {
    switch (marker.id) {
      case 'rider':
        return 1.35;
      case 'restaurant':
        return 1.15;
      default:
        return 1.0;
    }
  }

  Future<Uint8List> _markerBitmap(Color fill, {double scale = 1.0}) async {
    final cacheKey = Object.hash(fill.toARGB32(), scale);
    final cached = _iconCache[cacheKey];
    if (cached != null) return cached;

    final size = 56.0 * scale;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final center = Offset(size / 2, size / 2);

    canvas.drawCircle(
      center,
      size / 2 - 2,
      Paint()..color = Colors.white,
    );
    canvas.drawCircle(
      center,
      size / 2 - 6,
      Paint()..color = fill,
    );

    final image =
        await recorder.endRecording().toImage(size.toInt(), size.toInt());
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    final result = bytes!.buffer.asUint8List();
    _iconCache[cacheKey] = result;
    return result;
  }

  Future<Uint8List> _riderArrowBitmap() async {
    final cached = _riderArrowIcon;
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
        ..color = const Color(0xFF22C55E)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0,
    );

    final arrow = Path()
      ..moveTo(center.dx, size * 0.20)
      ..lineTo(size * 0.72, size * 0.76)
      ..lineTo(center.dx, size * 0.60)
      ..lineTo(size * 0.28, size * 0.76)
      ..close();
    canvas.drawPath(arrow, Paint()..color = const Color(0xFF22C55E));

    final image =
        await recorder.endRecording().toImage(size.toInt(), size.toInt());
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    final result = bytes!.buffer.asUint8List();
    _riderArrowIcon = result;
    return result;
  }

  Future<void> _onMapCreated(MapboxMap mapboxMap) async {
    _mapboxMap = mapboxMap;
    widget.onMapCreated?.call(AppMapboxController(mapboxMap));

    await mapboxMap.compass.updateSettings(CompassSettings(enabled: false));
    await mapboxMap.scaleBar.updateSettings(ScaleBarSettings(enabled: false));

    if (mounted) {
      setState(() => _mapReady = true);
    }
  }

  Future<void> _onStyleLoaded(StyleLoadedEventData event) async {
    final map = _mapboxMap;
    if (map == null) return;

    _styleLoaded = true;
    _pointManager = await map.annotations.createPointAnnotationManager();
    _polylineManager = await map.annotations.createPolylineAnnotationManager();
    await _syncAnnotations();
  }

  String _annotationSignature() {
    final markerSig = widget.markers
        .map(
          (m) =>
              '${m.id}:${m.latitude}:${m.longitude}:${m.headingDegrees ?? ""}',
        )
        .join('|');
    final routeSig = widget.route
        .map((p) => '${p.latitude},${p.longitude}')
        .join('|');
    return '$markerSig#$routeSig';
  }

  Future<void> _syncAnnotations({bool retrying = false}) async {
    final map = _mapboxMap;
    if (map == null || !_styleLoaded) return;

    final signature = _annotationSignature();
    if (!retrying && signature == _lastAnnotationSignature) {
      return;
    }

    if (_pointManager == null) {
      _pointManager = await map.annotations.createPointAnnotationManager();
    }
    if (_polylineManager == null) {
      _polylineManager =
          await map.annotations.createPolylineAnnotationManager();
    }

    try {
      await _polylineManager?.deleteAll();
      await _pointManager?.deleteAll();
    } catch (_) {
      if (retrying) return;
      _pointManager = await map.annotations.createPointAnnotationManager();
      _polylineManager =
          await map.annotations.createPolylineAnnotationManager();
      return _syncAnnotations(retrying: true);
    }

    final route = widget.route;
    if (route.length >= 2) {
      final positions =
          route.map((p) => Position(p.longitude, p.latitude)).toList();
      await _polylineManager?.create(
        PolylineAnnotationOptions(
          geometry: LineString(coordinates: positions),
          lineColor: AppColors.primary.toARGB32(),
          lineWidth: 5.0,
          lineJoin: LineJoin.ROUND,
        ),
      );
    }

    for (final marker in widget.markers) {
      final isRiderArrow =
          marker.id == 'rider' && marker.headingDegrees != null;

      if (isRiderArrow) {
        final icon = await _riderArrowBitmap();
        await _pointManager!.create(
          PointAnnotationOptions(
            geometry: Point(
              coordinates: Position(marker.longitude, marker.latitude),
            ),
            image: icon,
            iconSize: 1.0,
            iconRotate: marker.headingDegrees ?? 0.0,
          ),
        );
        continue;
      }

      final scale = _iconScaleForMarker(marker);
      final icon = await _markerBitmap(
        _colorForMarker(marker),
        scale: scale,
      );
      await _pointManager!.create(
        PointAnnotationOptions(
          geometry: Point(
            coordinates: Position(marker.longitude, marker.latitude),
          ),
          image: icon,
          iconSize: scale,
        ),
      );
    }

    _lastAnnotationSignature = signature;

    if (widget.fitMarkersInView) {
      await _fitCamera();
    } else if (widget.markers.length == 1) {
      final m = widget.markers.first;
      await map.flyTo(
        CameraOptions(
          center: Point(coordinates: Position(m.longitude, m.latitude)),
          zoom: 15.0,
        ),
        MapAnimationOptions(duration: 400),
      );
    }
  }

  Future<void> _fitCamera() async {
    final map = _mapboxMap;
    if (map == null) return;

    final positions = <Position>[];

    for (final p in widget.route) {
      positions.add(Position(p.longitude, p.latitude));
    }
    for (final m in widget.markers) {
      positions.add(Position(m.longitude, m.latitude));
    }

    if (positions.isEmpty) return;

    if (positions.length == 1) {
      await map.flyTo(
        CameraOptions(center: Point(coordinates: positions.first), zoom: 15.0),
        MapAnimationOptions(duration: 400),
      );
      return;
    }

    try {
      final cameraOptions = await map.cameraForCoordinatesPadding(
        positions.map((p) => Point(coordinates: p)).toList(),
        CameraOptions(),
        MbxEdgeInsets(top: 56, left: 40, bottom: 56, right: 40),
        null,
        null,
      );
      await map.flyTo(cameraOptions, MapAnimationOptions(duration: 500));
    } catch (_) {
      await _fitMarkersOnly(map);
    }
  }

  Future<void> _fitMarkersOnly(MapboxMap map) async {
    if (widget.markers.isEmpty) return;

    var minLat = widget.markers.first.latitude;
    var maxLat = minLat;
    var minLng = widget.markers.first.longitude;
    var maxLng = minLng;

    for (final m in widget.markers) {
      if (m.latitude < minLat) minLat = m.latitude;
      if (m.latitude > maxLat) maxLat = m.latitude;
      if (m.longitude < minLng) minLng = m.longitude;
      if (m.longitude > maxLng) maxLng = m.longitude;
    }

    final cameraOptions = await map.cameraForCoordinateBounds(
      CoordinateBounds(
        southwest: Point(coordinates: Position(minLng, minLat)),
        northeast: Point(coordinates: Position(maxLng, maxLat)),
        infiniteBounds: false,
      ),
      MbxEdgeInsets(top: 56, left: 40, bottom: 56, right: 40),
      null,
      null,
      null,
      null,
    );
    await map.flyTo(cameraOptions, MapAnimationOptions(duration: 500));
  }

  @override
  Widget build(BuildContext context) {
    final center = Position(
      widget.initialLongitude,
      widget.initialLatitude,
    );

    return Stack(
      fit: StackFit.expand,
      children: [
        if (!_mapReady)
          const ColoredBox(
            color: Color(0xFFE5E7EB),
            child: Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          ),
        MapWidget(
          key: const ValueKey('customer_app_map'),
          styleUri: MapboxStyles.STANDARD,
          cameraOptions: CameraOptions(
            center: Point(coordinates: center),
            zoom: 14.0,
          ),
          onMapCreated: _onMapCreated,
          onStyleLoadedListener: _onStyleLoaded,
        ),
      ],
    );
  }
}
