import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:grubbd_app/core/network/create_session_api.dart';
import 'package:grubbd_app/features/first_screen/first_screen.dart';
import 'package:grubbd_app/features/sessions/location_search_screen.dart';

class CreateSessionScreen extends StatefulWidget {
  const CreateSessionScreen({super.key, this.api});

  final CreateSessionApi? api;

  @override
  State<CreateSessionScreen> createState() => _CreateSessionScreenState();
}

class _CreateSessionScreenState extends State<CreateSessionScreen> {
  late final CreateSessionApi api;
  SessionLocation? selectedLocation;
  double radiusKm = 3;
  Set<int> selectedPrices = {1};
  String matchRule = 'ALL';
  bool isLoadingLocation = false;
  bool isCreating = false;

  @override
  void initState() {
    super.initState();
    api = widget.api ?? CreateSessionApi();
    useCurrentLocation();
  }

  Future<void> useCurrentLocation() async {
    setState(() => isLoadingLocation = true);

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) throw Exception('Please turn on location services');

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        throw Exception('Location permission is required');
      }

      final position = await Geolocator.getCurrentPosition();
      final location = await api.reverseGeocode(
        position.latitude,
        position.longitude,
      );

      if (mounted) {
        setState(() => selectedLocation = location);
      }
    } catch (error) {
      if (mounted) {
        showMessage(error.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => isLoadingLocation = false);
    }
  }

  Future<void> chooseLocation() async {
    final location = await Navigator.push<SessionLocation>(
      context,
      MaterialPageRoute(builder: (_) => LocationSearchScreen(api: api)),
    );

    if (location != null && mounted) {
      setState(() => selectedLocation = location);
    }
  }

  Future<void> createSession() async {
    if (selectedLocation == null) {
      showMessage('Please choose a location');
      return;
    }
    if (selectedPrices.isEmpty) {
      showMessage('Please choose at least one price');
      return;
    }

    setState(() => isCreating = true);
    try {
      final session = await api.createSession(
        location: selectedLocation!,
        radiusKm: radiusKm,
        priceLevels: selectedPrices.toList()..sort(),
        matchRule: matchRule,
      );

      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Session created!'),
          content: Text(
            'Share room code ${session.roomCode} with your friends.',
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Done'),
            ),
          ],
        ),
      );
    } catch (error) {
      if (mounted) {
        showMessage(error.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => isCreating = false);
    }
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          const FirstScreen(showBranding: false),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 430),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xF2FFF8EE),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: const [
                        BoxShadow(color: Colors.black26, blurRadius: 18),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            IconButton(
                              onPressed: () => Navigator.pop(context),
                              icon: const Icon(Icons.arrow_back),
                            ),
                            const Text(
                              'Create Session',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: FilledButton(
                                onPressed: useCurrentLocation,
                                child: const Text('Current Location'),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: OutlinedButton(
                                onPressed: chooseLocation,
                                child: const Text('Choose Location'),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        _locationCard(),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Search radius',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                            Text('${radiusKm.round()} km'),
                          ],
                        ),
                        Slider(
                          key: const Key('radius-slider'),
                          value: radiusKm,
                          min: 1,
                          max: 20,
                          divisions: 19,
                          onChanged: (value) =>
                              setState(() => radiusKm = value),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Price',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          children: [1, 2, 3, 4].map((price) {
                            return FilterChip(
                              label: Text(List.filled(price, r'$').join()),
                              selected: selectedPrices.contains(price),
                              onSelected: (selected) {
                                setState(() {
                                  if (selected) {
                                    selectedPrices.add(price);
                                  } else {
                                    selectedPrices.remove(price);
                                  }
                                });
                              },
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'Match rule',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                        RadioGroup<String>(
                          groupValue: matchRule,
                          onChanged: (value) {
                            if (value != null) {
                              setState(() => matchRule = value);
                            }
                          },
                          child: const Column(
                            children: [
                              RadioListTile<String>(
                                value: 'ALL',
                                title: Text('Everyone must agree'),
                              ),
                              RadioListTile<String>(
                                value: 'MAJORITY',
                                title: Text('Most people agree'),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: FilledButton(
                            key: const Key('create-session-submit'),
                            onPressed: isCreating ? null : createSession,
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFFE94F54),
                            ),
                            child: isCreating
                                ? const CircularProgressIndicator(
                                    color: Colors.white,
                                  )
                                : const Text('Create'),
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

  Widget _locationCard() {
    if (isLoadingLocation) {
      return const Center(child: CircularProgressIndicator());
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFE4B5),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(Icons.location_on, color: Color(0xFFE94F54)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              selectedLocation?.address ?? 'Choose a location to continue',
            ),
          ),
        ],
      ),
    );
  }
}
