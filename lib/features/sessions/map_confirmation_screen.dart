import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:grubbd_app/core/network/create_session_api.dart';
import 'package:grubbd_app/features/first_screen/first_screen.dart';
import 'package:latlong2/latlong.dart';

class MapConfirmationScreen extends StatefulWidget {
  const MapConfirmationScreen({super.key, required this.location, this.api});

  final SessionLocation location;
  final CreateSessionApi? api;

  @override
  State<MapConfirmationScreen> createState() => _MapConfirmationScreenState();
}

class _MapConfirmationScreenState extends State<MapConfirmationScreen> {
  // The API converts a tapped coordinate into a readable address.
  late final CreateSessionApi api;

  // This changes whenever the user taps a new point on the map.
  late SessionLocation selectedLocation;
  bool isUpdatingLocation = false;

  @override
  void initState() {
    super.initState();
    api = widget.api ?? CreateSessionApi();
    selectedLocation = widget.location;
  }

  Future<void> selectMapPoint(LatLng point) async {
    // Show a loader while the new address is being found.
    setState(() => isUpdatingLocation = true);

    try {
      // Convert the tapped latitude and longitude into an address.
      final location = await api.reverseGeocode(
        point.latitude,
        point.longitude,
      );
      if (!mounted) return;
      setState(() => selectedLocation = location);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(readableError(error))));
    }

    if (mounted) setState(() => isUpdatingLocation = false);
  }

  String readableError(Object error) {
    return error.toString().replaceFirst('Exception: ', '');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          const FirstScreen(showBranding: false),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 430),
                  child: Container(
                    width: double.infinity,
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
                      color: const Color(0xF2FFF8EE),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: const [
                        BoxShadow(color: Colors.black26, blurRadius: 18),
                      ],
                    ),
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              IconButton(
                                onPressed: () => Navigator.pop(context),
                                icon: const Icon(Icons.arrow_back),
                              ),
                              Expanded(
                                child: Text(
                                  selectedLocation.address,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Stack(
                            fit: StackFit.expand,
                            alignment: Alignment.center,
                            children: [
                              Positioned.fill(child: _buildMap()),
                              if (isUpdatingLocation)
                                const Center(
                                  child: CircularProgressIndicator(),
                                ),
                              Positioned(
                                left: 16,
                                right: 16,
                                bottom: 16,
                                child: SizedBox(
                                  height: 52,
                                  child: FilledButton(
                                    key: const Key('confirm-location-button'),
                                    onPressed: () {
                                      // Return the selected point to the
                                      // previous screen.
                                      Navigator.pop(context, selectedLocation);
                                    },
                                    style: FilledButton.styleFrom(
                                      backgroundColor: const Color(0xFFE94F54),
                                    ),
                                    child: const Text('Confirm Location'),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMap() {
    // flutter_map uses LatLng to decide the map center and marker position.
    final point = LatLng(selectedLocation.latitude, selectedLocation.longitude);

    return FlutterMap(
      options: MapOptions(
        initialCenter: point,
        initialZoom: 15,
        onTap: (_, tappedPoint) => selectMapPoint(tappedPoint),
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.example.grubbd_app',
        ),
        MarkerLayer(
          markers: [
            Marker(
              point: point,
              width: 58,
              height: 58,
              child: const Icon(
                Icons.location_on,
                key: Key('map-location-marker'),
                size: 58,
                color: Color(0xFFE94F54),
              ),
            ),
          ],
        ),
        const RichAttributionWidget(
          attributions: [TextSourceAttribution('OpenStreetMap contributors')],
        ),
      ],
    );
  }
}
