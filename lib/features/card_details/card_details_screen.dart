import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:grubbd_app/core/network/swipe_deck_api.dart';
import 'package:grubbd_app/features/first_screen/first_screen.dart';
import 'package:url_launcher/url_launcher.dart';

class CardDetailsScreen extends StatefulWidget {
  const CardDetailsScreen({
    super.key,
    required this.sessionId,
    required this.restaurantId,
    this.api,
  });

  final String sessionId;
  final String restaurantId;
  final SwipeDeckApi? api;

  @override
  State<CardDetailsScreen> createState() => _CardDetailsScreenState();
}

class _CardDetailsScreenState extends State<CardDetailsScreen> {
  late final SwipeDeckApi api;
  SwipeRestaurant? restaurant;
  Uint8List? photo;
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    api = widget.api ?? SwipeDeckApi();
    loadRestaurant();
  }

  Future<void> loadRestaurant() async {
    // Show the loader and clear an old error before trying again.
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final result = await api.getRestaurant(
        widget.sessionId,
        widget.restaurantId,
      );

      // Load the image only when this restaurant has a photo reference.
      Uint8List? loadedPhoto;
      final photoReference = result.photoReference;
      if (photoReference != null && photoReference.isNotEmpty) {
        try {
          loadedPhoto = await api.getPhoto(photoReference);
        } catch (_) {
          // Keep photo empty. The UI will show a restaurant icon instead.
        }
      }

      if (!mounted) return;
      setState(() {
        restaurant = result;
        photo = loadedPhoto;
      });
    } catch (error) {
      if (mounted) {
        setState(() {
          errorMessage = error.toString().replaceFirst('Exception: ', '');
        });
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> openGoogleMaps() async {
    // Read the Google Maps link returned by our backend.
    final url = restaurant?.googleMapsUrl;
    if (url == null || url.isEmpty) {
      showMessage('Google Maps is not available for this restaurant');
      return;
    }

    final opened = await launchUrl(
      Uri.parse(url),
      mode: LaunchMode.externalApplication,
    );
    if (!opened && mounted) showMessage('Could not open Google Maps');
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
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: 430,
                    maxHeight: 760,
                  ),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xF2FFF8EE),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: const [
                        BoxShadow(color: Colors.black26, blurRadius: 18),
                      ],
                    ),
                    child: _content(),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _content() {
    if (isLoading) return const Center(child: CircularProgressIndicator());
    if (errorMessage != null || restaurant == null) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(errorMessage ?? 'Could not load restaurant details'),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: loadRestaurant,
            child: const Text('Try again'),
          ),
        ],
      );
    }

    final item = restaurant!;
    final screenHeight = MediaQuery.sizeOf(context).height;
    final imageHeight = (screenHeight * 0.28).clamp(170.0, 230.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back),
            ),
            const Text(
              'Card Details',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: SizedBox(
            width: double.infinity,
            height: imageHeight,
            child: photo == null
                ? Container(
                    color: const Color(0xFFFFE4B5),
                    child: const Icon(
                      Icons.restaurant,
                      size: 80,
                      color: Color(0xFFE94F54),
                    ),
                  )
                : Image.memory(photo!, fit: BoxFit.cover),
          ),
        ),
        const SizedBox(height: 22),
        Text(
          item.name,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            const Icon(Icons.star, size: 18, color: Colors.amber),
            Text(item.rating?.toStringAsFixed(1) ?? 'New'),
            const SizedBox(width: 14),
            Text(_priceText(item.priceLevel)),
          ],
        ),
        if (item.address?.isNotEmpty == true) ...[
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.location_on_outlined, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  item.address!,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
        const Spacer(),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: FilledButton.icon(
            key: const Key('open-google-maps-button'),
            onPressed: openGoogleMaps,
            icon: const Icon(Icons.map_outlined),
            label: const Text('Open in Google Maps'),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFE94F54),
            ),
          ),
        ),
      ],
    );
  }

  String _priceText(int? priceLevel) {
    if (priceLevel == null) return 'Price unavailable';
    if (priceLevel == 0) return 'Free';
    return List.filled(priceLevel, r'$').join();
  }
}
