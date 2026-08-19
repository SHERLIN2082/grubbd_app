import 'package:flutter/material.dart';
import 'package:grubbd_app/core/network/create_session_api.dart';
import 'package:grubbd_app/features/first_screen/first_screen.dart';
import 'package:grubbd_app/features/sessions/map_confirmation_screen.dart';

class LocationSearchScreen extends StatefulWidget {
  const LocationSearchScreen({super.key, required this.api});

  final CreateSessionApi api;

  @override
  State<LocationSearchScreen> createState() => _LocationSearchScreenState();
}

class _LocationSearchScreenState extends State<LocationSearchScreen> {
  // Stores what the user types in the search box.
  final searchController = TextEditingController();

  // These values control what is displayed on the screen.
  List<LocationSuggestion> suggestions = [];
  bool isSearching = false;
  String? errorMessage;

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> searchLocations() async {
    // Step 1: Read and validate the user's search.
    final query = searchController.text.trim();
    if (query.length < 2) {
      setState(() => errorMessage = 'Enter at least two characters');
      return;
    }

    // Step 2: Show the loading indicator.
    setState(() {
      isSearching = true;
      errorMessage = null;
    });

    try {
      // Step 3: Ask the API for matching locations.
      final results = await widget.api.searchLocations(query);
      if (!mounted) return;
      setState(() => suggestions = results);
    } catch (error) {
      if (!mounted) return;
      setState(() => errorMessage = readableError(error));
    }

    if (mounted) setState(() => isSearching = false);
  }

  Future<void> selectLocation(LocationSuggestion suggestion) async {
    setState(() => isSearching = true);

    try {
      // Get the address and coordinates for the selected result.
      final location = await widget.api.getLocationDetails(suggestion.placeId);
      if (!mounted) return;

      // Open the map and wait for the user to confirm a point.
      final confirmed = await Navigator.push<SessionLocation>(
        context,
        MaterialPageRoute(
          builder: (_) =>
              MapConfirmationScreen(location: location, api: widget.api),
        ),
      );

      // Send the confirmed location back to CreateSessionScreen.
      if (confirmed != null && mounted) {
        Navigator.pop(context, confirmed);
      }
    } catch (error) {
      if (!mounted) return;
      setState(() => errorMessage = readableError(error));
    }

    if (mounted) setState(() => isSearching = false);
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
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xF2FFF8EE),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: const [
                        BoxShadow(color: Colors.black26, blurRadius: 18),
                      ],
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            IconButton(
                              onPressed: () => Navigator.pop(context),
                              icon: const Icon(Icons.arrow_back),
                            ),
                            const Text(
                              'Choose Location',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          key: const Key('location-search-field'),
                          controller: searchController,
                          decoration: InputDecoration(
                            hintText: 'Search an area or address',
                            filled: true,
                            fillColor: Colors.white,
                            prefixIcon: const Icon(Icons.search),
                            suffixIcon: IconButton(
                              onPressed: searchLocations,
                              icon: const Icon(Icons.arrow_forward),
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          onSubmitted: (_) => searchLocations(),
                        ),
                        if (errorMessage != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: Text(
                              errorMessage!,
                              style: const TextStyle(color: Colors.red),
                            ),
                          ),
                        const SizedBox(height: 12),
                        Expanded(child: _buildResults()),
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

  Widget _buildResults() {
    if (isSearching) return const Center(child: CircularProgressIndicator());

    if (suggestions.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.location_searching, size: 52, color: Color(0xFFE94F54)),
            SizedBox(height: 12),
            Text('No results', style: TextStyle(fontWeight: FontWeight.w800)),
            SizedBox(height: 4),
            Text(
              'Search for a nearby city, neighborhood, or address.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      itemCount: suggestions.length,
      separatorBuilder: (_, _) => const Divider(),
      itemBuilder: (context, index) {
        final suggestion = suggestions[index];
        return ListTile(
          leading: const CircleAvatar(
            backgroundColor: Color(0xFFE94F54),
            foregroundColor: Colors.white,
            child: Icon(Icons.location_on),
          ),
          title: Text(suggestion.description),
          onTap: () => selectLocation(suggestion),
        );
      },
    );
  }
}
