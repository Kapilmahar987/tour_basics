import 'dart:async' show Completer, StreamSubscription;

import 'package:flutter/material.dart'
    show
        BuildContext,
        Colors,
        SafeArea,
        Scaffold,
        State,
        StatefulWidget,
        Widget;
import 'package:flutter_polyline_points/flutter_polyline_points.dart'
    show PointLatLng, PolylinePoints;
import 'package:google_map/google_map_Api.dart' show GoogleMapApi;
import 'package:google_maps_flutter/google_maps_flutter.dart'
    show
        CameraPosition,
        CameraUpdate,
        GoogleMap,
        GoogleMapController,
        LatLng,
        MapType,
        Marker,
        MarkerId,
        Polyline,
        PolylineId;
import 'package:location/location.dart' show Location, LocationData;

class TrackinPage extends StatefulWidget {
  const TrackinPage({super.key});

  @override
  State<TrackinPage> createState() => _TrackinPageState();
}

class _TrackinPageState extends State<TrackinPage> {
  LatLng sourceLocation = LatLng(23.1817690, 77.3019810);

  LatLng destinationLatlng = LatLng(23.1818331, 77.3018043);

  bool isLoading = true;

  Completer<GoogleMapController> _controller = Completer();

  Set<Marker> _marker = Set<Marker>();
  Set<Polyline> _polyline = Set<Polyline>();

  List<LatLng> polylineCoordinates = [];
  late PolylinePoints polylinePoints;

  late StreamSubscription<LocationData> subscription;

  late LocationData currentLocation;
  late LocationData destinationLocation;
  late Location location;
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    location = Location();
    polylinePoints = PolylinePoints();

    subscription = location.onLocationChanged.listen((currentLocation) {
      currentLocation = currentLocation;
    });
    setInitialLocation();
  }

  void setInitialLocation() async {
    currentLocation = await location.getLocation();
    destinationLocation = LocationData.fromMap({
      "latitude": destinationLatlng.latitude,
      "longitude": destinationLatlng.longitude,
    });
  }

  void showLocationPoints() {
    var sourcePosition = LatLng(
        currentLocation.latitude ?? 0.0, currentLocation.longitude ?? 0.0);

    var destinationPosition =
        LatLng(destinationLatlng.latitude, destinationLatlng.longitude);

    _marker.add(Marker(
      markerId: MarkerId('sourcePosition'),
      position: sourcePosition,
    ));

    setState(() {
      _marker.add(Marker(
        markerId: MarkerId('destinationPosition'),
        position: destinationPosition,
      ));
    });

    setPolylinesInMap();
  }

  void setPolylinesInMap() async {
    var result = await polylinePoints.getRouteBetweenCoordinates(
        GoogleMapApi().url,
        PointLatLng(
            currentLocation.latitude ?? 0.0, currentLocation.longitude ?? 0.0),
        PointLatLng(destinationLatlng.latitude, destinationLatlng.longitude));

    if (result.points.isNotEmpty) {
      result.points.forEach((pointLatLng) {
        polylineCoordinates
            .add(LatLng(pointLatLng.latitude, pointLatLng.longitude));
      });
    }
    _polyline.add(Polyline(
      polylineId: PolylineId('polyline'),
      width: 5,
      color: Colors.blueAccent,
      points: polylineCoordinates,
    ));
  }

  void updatePintsOnMap() async {
    CameraPosition cameraPosition = CameraPosition(
      zoom: 20,
      tilt: 80,
      bearing: 30,
      target: LatLng(
          currentLocation.latitude ?? 0.0, currentLocation.longitude ?? 0.0),
    );

    final GoogleMapController controller = await _controller.future;
    controller.animateCamera(CameraUpdate.newCameraPosition(cameraPosition));

    var sourcePosition = LatLng(
        currentLocation.latitude ?? 0.0, currentLocation.longitude ?? 0.0);

    _marker.removeWhere((marker) => marker.mapsId.value == "sourcePosition");

    setState(() {
      _marker.add(Marker(
        markerId: MarkerId('sourcePosition'),
        position: sourcePosition,
      ));
    });
  }

  @override
  Widget build(BuildContext context) {
    CameraPosition initialCameraPosition = CameraPosition(
        zoom: 20,
        tilt: 80,
        bearing: 30,
        target: LatLng(
            currentLocation.latitude ?? 0.0, currentLocation.longitude ?? 0.0));

    return SafeArea(
      child: Scaffold(
        body: GoogleMap(
          markers: _marker,
          polylines: _polyline,
          mapType: MapType.normal,
          initialCameraPosition: initialCameraPosition,
          onMapCreated: (GoogleMapController controller) {
            _controller.complete(controller);
            showLocationPoints();
          },
        ),
      ),
    );
  }
}
