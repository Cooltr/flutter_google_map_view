import 'dart:async';

import 'package:flutter/services.dart';
import 'package:map_view/camera_position.dart';
import 'package:map_view/location.dart';
import 'package:map_view/map_options.dart';
import 'package:map_view/marker.dart';
import 'package:map_view/polygon.dart';
import 'package:map_view/polyline.dart';
import 'package:map_view/toolbar_action.dart';

export 'camera_position.dart';
export 'camera_position.dart';
export 'location.dart';
export 'locations.dart';
export 'map_options.dart';
export 'map_view_type.dart';
export 'marker.dart';
export 'static_map_provider.dart';
export 'toolbar_action.dart';

class MapView {
  MethodChannel _channel = const MethodChannel("com.apptreesoftware.map_view");
  StreamController<Marker> _annotationStreamController =
      new StreamController.broadcast();
  StreamController<Polyline> _polylineStreamController =
      new StreamController.broadcast();
  StreamController<Polygon> _polygonStreamController =
      new StreamController.broadcast();
  StreamController<Location> _locationChangeStreamController =
      new StreamController.broadcast();
  StreamController<Location> _mapInteractionStreamController =
      new StreamController.broadcast();
  StreamController<CameraPosition> _cameraStreamController =
      new StreamController.broadcast();
  StreamController<int> _toolbarActionStreamController =
      new StreamController.broadcast();
  StreamController<Null> _mapReadyStreamController =
      new StreamController.broadcast();
  StreamController<Marker> _infoWindowStreamController =
      new StreamController.broadcast();

  Map<String, Marker> _annotations = {};
  Map<String, Polyline> _polylines = {};
  Map<String, Polygon> _polygons = {};

  MapView() {
    _channel.setMethodCallHandler(_handleMethod);
  }

  static bool _apiKeySet = false;

  static void setApiKey(String apiKey) {
    MethodChannel c = const MethodChannel("com.apptreesoftware.map_view");
    c.invokeMethod('setApiKey', apiKey);
    _apiKeySet = true;
  }

  void show(MapOptions mapOptions, {List<ToolbarAction> toolbarActions}) {
    if (!_apiKeySet) {
      throw "API Key must be set before calling `show`. Use MapView.setApiKey";
    }
    List<Map> actions = [];
    if (toolbarActions != null) {
      actions = toolbarActions.map((t) => t.toMap).toList();
    }
    _channel.invokeMethod(
        'show', {"mapOptions": mapOptions.toMap(), "actions": actions});
  }

  void dismiss() {
    _annotations.clear();
    _polylines.clear();
    _polygons.clear();
    _channel.invokeMethod('dismiss');
  }

  List<Marker> get markers => _annotations.values.toList(growable: false);

  List<Polyline> get polylines => _polylines.values.toList(growable: false);

  List<Polygon> get polygons => _polygons.values.toList(growable: false);

  void setMarkers(List<Marker> annotations) {
    _annotations.clear();
    annotations.forEach((a) => _annotations[a.id] = a);
    _channel.invokeMethod('setAnnotations',
        annotations.map((a) => a.toMap()).toList(growable: false));
  }

  void clearAnnotations() {
    _channel.invokeMethod('clearAnnotations');
  }

  void addMarker(Marker marker) {
    if (_annotations.containsKey(marker.id)) {
      return;
    }
    _annotations[marker.id] = marker;
    _channel.invokeMethod('addAnnotation', marker.toMap());
  }

  void removeMarker(Marker marker) {
    if (!_annotations.containsKey(marker.id)) {
      return;
    }
    _annotations.remove(marker.id);
    _channel.invokeMethod('removeAnnotation', marker.toMap());
  }

  void setPolylines(List<Polyline> polylines) {
    _polylines.clear();
    polylines.forEach((a) => _polylines[a.id] = a);
    _channel.invokeMethod('setPolylines',
        polylines.map((a) => a.toMap()).toList(growable: false));
  }

  void clearPolylines() {
    _channel.invokeMethod('clearPolylines');
  }

  void addPolyline(Polyline polyline) {
    if (_polylines.containsKey(polyline.id)) {
      return;
    }
    _polylines[polyline.id] = polyline;
    _channel.invokeMethod('addPolyline', polyline.toMap());
  }

  void removePolyline(Polyline polyline) {
    if (!_polylines.containsKey(polyline.id)) {
      return;
    }
    _polylines.remove(polyline.id);
    _channel.invokeMethod('removePolyline', polyline.toMap());
  }

  void setPolygons(List<Polygon> polygons) {
    _polygons.clear();
    polygons.forEach((a) => _polygons[a.id] = a);
    _channel.invokeMethod(
        'setPolygons', polygons.map((a) => a.toMap()).toList(growable: false));
  }

  void clearPolygons() {
    _channel.invokeMethod('clearPolygons');
  }

  void addPolygon(Polygon polygon) {
    if (_polygons.containsKey(polygon.id)) {
      return;
    }
    _polygons[polygon.id] = polygon;
    _channel.invokeMethod('addPolygon', polygon.toMap());
  }

  void removePolygon(Polygon polygon) {
    if (!_polygons.containsKey(polygon.id)) {
      return;
    }
    _polygons.remove(polygon.id);
    _channel.invokeMethod('removePolygon', polygon.toMap());
  }

  void zoomToFit({int padding: 50}) {
    _channel.invokeMethod('zoomToFit', padding);
  }

  void zoomToAnnotations(List<String> annotationIds, {double padding: 50.0}) {
    _channel.invokeMethod('zoomToAnnotations',
        {"annotations": annotationIds, "padding": padding});
  }

  void zoomToPolylines(List<String> polylines, {double padding: 50.0}) {
    _channel.invokeMethod(
        'zoomToPolylines', {"polylines": polylines, "padding": padding});
  }

  void zoomToPolygons(List<String> polygonsIds, {double padding: 50.0}) {
    _channel.invokeMethod(
        'zoomToPolygons', {"polygons": polygonsIds, "padding": padding});
  }

  void setCameraPosition(double latitude, double longitude, double zoom) {
    _channel.invokeMethod("setCamera",
        {"latitude": latitude, "longitude": longitude, "zoom": zoom});
  }

  void showInfoWindowForMarker(Marker marker) {
    if (!_annotations.containsKey(marker.id)) {
      return;
    }
    _annotations.remove(marker.id);
    _channel.invokeMethod('showInfoWindowForMarker', marker.toMap());
  }

  Future<Location> get centerLocation async {
    Map locationMap = await _channel.invokeMethod("getCenter");
    return new Location(locationMap["latitude"], locationMap["longitude"]);
  }

  Future<double> get zoomLevel async {
    return await _channel.invokeMethod("getZoomLevel");
  }

  Future<List<Marker>> get visibleAnnotations async {
    List<dynamic> ids = await _channel.invokeMethod("getVisibleMarkers");
    var annotations = <Marker>[];
    for (var id in ids) {
      var annotation = _annotations[id];
      annotations.add(annotation);
    }
    return annotations;
  }

  Future<List<Polyline>> get visiblePolyLines async {
    List<dynamic> ids = await _channel.invokeMethod("getVisiblePolylines");
    var polylines = <Polyline>[];
    for (var id in ids) {
      var polyline = _polylines[id];
      polylines.add(polyline);
    }
    return polylines;
  }

  Future<List<Polygon>> get visiblePolygons async {
    List<dynamic> ids = await _channel.invokeMethod("getVisiblePolygons");
    var polygons = <Polygon>[];
    for (var id in ids) {
      var polygon = _polygons[id];
      polygons.add(polygon);
    }
    return polygons;
  }

  Stream<Marker> get onTouchAnnotation => _annotationStreamController.stream;

  Stream<Polyline> get onTouchPolyline =>
      _polylineStreamController.stream;

  Stream<Polygon> get onTouchPolygon => _polygonStreamController.stream;

  Stream<Location> get onLocationUpdated =>
      _locationChangeStreamController.stream;

  Stream<Location> get onMapTapped => _mapInteractionStreamController.stream;

  Stream<CameraPosition> get onCameraChanged => _cameraStreamController.stream;

  Stream<int> get onToolbarAction => _toolbarActionStreamController.stream;

  Stream<Null> get onMapReady => _mapReadyStreamController.stream;

  Stream<Marker> get onInfoWindowTapped => _infoWindowStreamController.stream;

  Future<dynamic> _handleMethod(MethodCall call) async {
    switch (call.method) {
      case "onMapReady":
        _mapReadyStreamController.add(null);
        return new Future.value("");
      case "locationUpdated":
        Map args = call.arguments;
        _locationChangeStreamController.add(new Location.fromMap(args));
        return new Future.value("");
      case "annotationTapped":
        String id = call.arguments;
        var annotation = _annotations[id];
        if (annotation != null) {
          _annotationStreamController.add(annotation);
        }
        return new Future.value("");
      case "polylineTapped":
        String id = call.arguments;
        var polyline = _polylines[id];
        if (polyline != null) {
          _polylineStreamController.add(polyline);
        }
        return new Future.value("");
      case "polygonTapped":
        String id = call.arguments;
        var polygon = _polygons[id];
        if (polygon != null) {
          _polygonStreamController.add(polygon);
        }
        return new Future.value("");
      case "infoWindowTapped":
        String id = call.arguments;
        var annotation = _annotations[id];
        if (annotation != null) {
          _infoWindowStreamController.add(annotation);
        }
        return new Future.value("");
      case "mapTapped":
        Map locationMap = call.arguments;
        Location location = new Location.fromMap(locationMap);
        _mapInteractionStreamController.add(location);
        return new Future.value("");
      case "cameraPositionChanged":
        _cameraStreamController.add(new CameraPosition.fromMap(call.arguments));
        return new Future.value("");
      case "onToolbarAction":
        _toolbarActionStreamController.add(call.arguments);
        break;
    }
    return new Future.value("");
  }
}
