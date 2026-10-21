import 'package:flutter/material.dart';
import 'package:grubbd_app/core/widgets/app_back_button.dart';
import 'package:geolocator/geolocator.dart';
import 'package:grubbd_app/core/network/create_session_api.dart';
import 'package:grubbd_app/features/first_screen/first_screen.dart';
import 'package:grubbd_app/features/sessions/location_search_screen.dart';
import 'package:grubbd_app/features/lobby/lobby_screen.dart';
import 'package:grubbd_app/core/network/profile_api.dart';

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
  String? foodPreference;
  final manualMinimumController = TextEditingController(text: '1');
  final manualMaximumController = TextEditingController(text: '4');

  @override
  void initState() {
    super.initState();
    api = widget.api ?? CreateSessionApi();
    useCurrentLocation();
  }

  @override
  void dispose() {
    manualMinimumController.dispose();
    manualMaximumController.dispose();
    super.dispose();
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
      showMessage('Please choose a location to search for restaurants');
      return;
    }
    final minimumPrice = int.tryParse(manualMinimumController.text.trim());
    final maximumPrice = int.tryParse(manualMaximumController.text.trim());
    if (minimumPrice == null || maximumPrice == null ||
        minimumPrice < 0 || maximumPrice > 4 || minimumPrice > maximumPrice) {
      showMessage('Enter a valid price range from 0 to 4');
      return;
    }

    final pricesForRequest = {
      ...selectedPrices,
      for (var price = minimumPrice; price <= maximumPrice; price++) price,
    }.toList()..sort();

    setState(() => isCreating = true);
    try {
      if (foodPreference != null) {
        await ProfileApi().saveFoodPreference(foodPreference!);
      }

      final session = await api.createSession(
        location: selectedLocation!,
        radiusKm: radiusKm,
        priceLevels: pricesForRequest,
        matchRule: matchRule,
      );

      if (!mounted) return;
      await Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => LobbyScreen(sessionId: session.id)),
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
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
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
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 26),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.96),
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: const [
                        BoxShadow(color: Color(0x28000000), blurRadius: 24, offset: Offset(0, 8)),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Top back button and title
                        Row(
                          children: [
                            const AppBackButton(),
                            const SizedBox(width: 8),
                            const Text(
                              'Create Session 🍔',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF1E1A1A),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 8),

                        // Beginner explainer
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF0EC),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFFF594D).withOpacity(0.15)),
                          ),
                          child: const Row(
                            children: [
                              Text('💡', style: TextStyle(fontSize: 22)),
                              SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Set your dining area and budget. Once created, invite friends to swipe right on restaurants together!',
                                  style: TextStyle(fontSize: 12.5, color: Color(0xFF5F3928), height: 1.35),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 18),

                        // Location buttons
                        Row(
                          children: [
                            Expanded(
                              child: FilledButton.icon(
                                onPressed: useCurrentLocation,
                                icon: const Icon(Icons.my_location_rounded, size: 18),
                                label: const Text('My Location'),
                                style: FilledButton.styleFrom(
                                  backgroundColor: const Color(0xFFFF594D),
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: chooseLocation,
                                icon: const Icon(Icons.map_outlined, size: 18, color: Color(0xFFFF594D)),
                                label: const Text('Choose Map', style: TextStyle(fontWeight: FontWeight.w800)),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  side: const BorderSide(color: Color(0xFFFF594D), width: 1.5),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),
                        _locationCard(),

                        const SizedBox(height: 20),

                        // Food preference
                        const Text(
                          'Food Preference 🥗',
                          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5, color: Color(0xFF1E1A1A)),
                        ),
                        const SizedBox(height: 6),
                        DropdownButtonFormField<String>(
                          initialValue: foodPreference,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: const Color(0xFFFFF9EE),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(color: Colors.black.withOpacity(0.08)),
                            ),
                          ),
                          hint: const Text('All Cuisines (No restrictions)'),
                          items: const [
                            DropdownMenuItem(value: 'Any food', child: Text('🍕 Any food')),
                            DropdownMenuItem(value: 'Vegetarian', child: Text('🥗 Vegetarian Friendly')),
                            DropdownMenuItem(value: 'Non-vegetarian', child: Text('🥩 Meat & Non-veg')),
                          ],
                          onChanged: (value) => setState(() => foodPreference = value),
                        ),

                        const SizedBox(height: 22),

                        // Search radius
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Search Radius 📍',
                              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5, color: Color(0xFF1E1A1A)),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFE0D9),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '${radiusKm.round()} km',
                                style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFFFF594D)),
                              ),
                            ),
                          ],
                        ),
                        Slider(
                          key: const Key('radius-slider'),
                          value: radiusKm,
                          min: 1,
                          max: 20,
                          divisions: 19,
                          activeColor: const Color(0xFFFF594D),
                          onChanged: (value) => setState(() => radiusKm = value),
                        ),

                        const SizedBox(height: 14),

                        // Price
                        const Text(
                          'Price Level 💵',
                          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5, color: Color(0xFF1E1A1A)),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          children: [
                            (1, r'$ Budget'),
                            (2, r'$$ Moderate'),
                            (3, r'$$$ Fancy'),
                            (4, r'$$$$ Splurge'),
                          ].map((item) {
                            final price = item.$1;
                            final label = item.$2;
                            final isSelected = selectedPrices.contains(price);
                            return FilterChip(
                              label: Text(label),
                              selected: isSelected,
                              selectedColor: const Color(0xFFFFE0D9),
                              backgroundColor: Colors.white,
                              labelStyle: TextStyle(
                                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                color: isSelected ? const Color(0xFFFF594D) : const Color(0xFF2C2523),
                                fontSize: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(
                                  color: isSelected ? const Color(0xFFFF594D) : Colors.black.withOpacity(0.08),
                                ),
                              ),
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

                        // Match rule
                        const Text(
                          'Match Rule 🤝',
                          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5, color: Color(0xFF1E1A1A)),
                        ),
                        const SizedBox(height: 8),
                        RadioGroup<String>(
                          groupValue: matchRule,
                          onChanged: (value) {
                            if (value != null) {
                              setState(() => matchRule = value);
                            }
                          },
                          child: Column(
                            children: [
                              _matchRuleTile(
                                value: 'ALL',
                                title: 'Unanimous Match 🎯',
                                subtitle: 'Every member in the group must swipe YES to match',
                              ),
                              const SizedBox(height: 8),
                              _matchRuleTile(
                                value: 'MAJORITY',
                                title: 'Majority Rules 🗳️',
                                subtitle: 'The restaurant with the highest YES votes wins',
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 26),

                        // Create Button
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: FilledButton(
                            key: const Key('create-session-submit'),
                            onPressed: isCreating ? null : createSession,
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFFFF594D),
                              elevation: 2,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                            child: isCreating
                                ? const SizedBox.square(
                                    dimension: 22,
                                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                  )
                                : const Text(
                                    'Create Dinner Session 🚀',
                                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                                  ),
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

  Widget _matchRuleTile({
    required String value,
    required String title,
    required String subtitle,
  }) {
    final isSelected = matchRule == value;
    return Container(
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFFFFF0EC) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected ? const Color(0xFFFF594D) : Colors.black.withOpacity(0.08),
          width: isSelected ? 1.8 : 1,
        ),
      ),
      child: RadioListTile<String>(
        value: value,
        activeColor: const Color(0xFFFF594D),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12, color: Color(0xFF756D69))),
      ),
    );
  }

  Widget _locationCard() {
    if (isLoadingLocation) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Center(child: CircularProgressIndicator(color: Color(0xFFFF594D))),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8EE),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFF9F1C).withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.location_on_rounded, color: Color(0xFFFF594D), size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              selectedLocation?.address ?? 'Tap "My Location" or choose on map',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF2C2523)),
            ),
          ),
        ],
      ),
    );
  }
}
