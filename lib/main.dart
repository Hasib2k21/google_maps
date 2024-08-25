import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:async';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: MapScreen(),
    );
  }
}

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  late GoogleMapController _mapController;
  LatLng _initialPosition = const LatLng(20.5937, 78.9629); // Default position (India)
  bool _locationPermissionGranted = false;
  Marker? _currentLocationMarker;
  final List<LatLng> _polylineCoordinates = [];
  late Timer _timer;
  CameraPosition? _currentCameraPosition;

  @override
  void initState() {
    super.initState();
    _checkLocationPermission();
  }

  @override
  void dispose() {
    _mapController.dispose();
    _timer.cancel();
    super.dispose();
  }

  Future<void> _checkLocationPermission() async {
    PermissionStatus permission = await Permission.locationWhenInUse.status;
    if (permission.isGranted) {
      _getCurrentLocation();
      setState(() {
        _locationPermissionGranted = true;
      });
      _startLocationUpdates();
    } else {
      PermissionStatus permissionStatus = await Permission.locationWhenInUse.request();
      if (permissionStatus.isGranted) {
        _getCurrentLocation();
        setState(() {
          _locationPermissionGranted = true;
        });
        _startLocationUpdates();
      } else {
        setState(() {
          _locationPermissionGranted = false;
        });
      }
    }
  }

  Future<void> _getCurrentLocation() async {
    Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    LatLng currentPosition = LatLng(position.latitude, position.longitude);

    setState(() {
      _initialPosition = currentPosition;
      _polylineCoordinates.add(currentPosition);
      _currentLocationMarker = Marker(
        markerId: const MarkerId('currentLocation'),
        position: currentPosition,
        infoWindow: InfoWindow(
          title: 'My Current Location',
          snippet: '${position.latitude}, ${position.longitude}',
        ),
      );
      _currentCameraPosition = CameraPosition(target: currentPosition, zoom: 14);
    });

    // Move the camera to the user's current position with animation
    _mapController.animateCamera(
      CameraUpdate.newCameraPosition(_currentCameraPosition!),
    );
  }

  void _startLocationUpdates() {
    _timer = Timer.periodic(const Duration(seconds: 10), (Timer timer) async {
      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      LatLng newPosition = LatLng(position.latitude, position.longitude);

      setState(() {
        _initialPosition = newPosition;
        _polylineCoordinates.add(newPosition);
        _currentLocationMarker = Marker(
          markerId: const MarkerId('currentLocation'),
          position: newPosition,
          infoWindow: InfoWindow(
            title: 'My Current Location',
            snippet: '${position.latitude}, ${position.longitude}',
          ),
        );
        _currentCameraPosition = CameraPosition(target: newPosition, zoom: 14);
      });

      // Move the camera to the new position with animation
      _mapController.animateCamera(
        CameraUpdate.newCameraPosition(_currentCameraPosition!),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Real-Time Location Tracker')),
      body: _locationPermissionGranted
          ? GoogleMap(
        initialCameraPosition: CameraPosition(target: _initialPosition, zoom: 14),
        myLocationEnabled: true,
        markers: _currentLocationMarker != null ? {_currentLocationMarker!} : {},
        polylines: {
          Polyline(
            polylineId: const PolylineId('route'),
            points: _polylineCoordinates,
            color: Colors.blue,
            width: 5,
          ),
        },
        onMapCreated: (GoogleMapController controller) {
          _mapController = controller;
        },
      )
          : const Center(child: Text('Location permission not granted')),
    );
  }

}
