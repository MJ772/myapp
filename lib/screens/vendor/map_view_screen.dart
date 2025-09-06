
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:myapp/services/repair_request_service.dart';

class MapViewScreen extends StatefulWidget {
  const MapViewScreen({super.key});

  @override
  State<MapViewScreen> createState() => _MapViewScreenState();
}

class _MapViewScreenState extends State<MapViewScreen> {
  final RepairRequestService _repairRequestService = RepairRequestService();
  Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    _fetchAndSetMarkers();
  }

  void _fetchAndSetMarkers() async {
    try {
      final requests = await _repairRequestService.fetchRepairRequests().first;
      final markers = requests
          .where((request) => request.status == 'open')
          .map((request) {
        return Marker(
          markerId: MarkerId(request.id),
          position: LatLng(request.location.latitude, request.location.longitude),
          infoWindow: InfoWindow(
            title: request.description,
            snippet: 'Tap to view details',
            onTap: () {
              Navigator.pushNamed(
                context,
                '/repairRequestDetails',
                arguments: request.id,
              );
            },
          ),
        );
      }).toSet();
      setState(() {
        _markers = markers;
      });
    } catch (e) {
      // Handle error
    }
  }

  @override
  Widget build(BuildContext context) {
    return GoogleMap(
      initialCameraPosition: const CameraPosition(
        target: LatLng(51.5074, -0.1278), // Default location, e.g., London
        zoom: 10,
      ),
      markers: _markers,
    );
  }
}
