import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:grubbd_app/core/network/swipe_deck_api.dart';
import 'package:grubbd_app/features/first_screen/first_screen.dart';

class ResultsScreen extends StatefulWidget {
  const ResultsScreen({super.key, required this.sessionId, required this.api});

  final String sessionId;
  final SwipeDeckApi api;

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> {
  List<SessionResult> results = [];
  final Map<String, Future<Uint8List>> photos = {};
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    loadResults();
  }

  Future<void> loadResults() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final loadedResults = await widget.api.getResults(widget.sessionId);
      if (!mounted) return;

      setState(() {
        results = loadedResults;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        errorMessage = error.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          const FirstScreen(showBranding: false),
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 430),
                child: Container(
                  margin: const EdgeInsets.all(20),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xF2FFF8EE),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: const [
                      BoxShadow(color: Colors.black26, blurRadius: 18),
                    ],
                  ),
                  child: _buildContent(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (errorMessage != null) {
      return _buildError();
    }

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
              'Results',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Text(
          '${results.length} delicious matches',
          style: const TextStyle(fontSize: 25, fontWeight: FontWeight.w900),
        ),
        const Text('Ranked by your group\'s yes votes'),
        const SizedBox(height: 18),
        Expanded(
          child: results.isEmpty
              ? const Center(child: Text('No restaurants have votes yet.'))
              : ListView.builder(
                  itemCount: results.length,
                  itemBuilder: (context, index) {
                    return _buildResultCard(results[index], index);
                  },
                ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            key: const Key('new-session-button'),
            onPressed: openNewSession,
            child: const Text('New Session'),
          ),
        ),
      ],
    );
  }

  Widget _buildResultCard(SessionResult result, int index) {
    final address = result.restaurant.address ?? 'Address unavailable';
    final distance = result.distanceKm;
    final locationText = distance == null
        ? address
        : '$address · ${distance.toStringAsFixed(1)} km';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                width: 72,
                height: 72,
                child: _buildPhoto(result.restaurant),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    result.restaurant.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    locationText,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.grey.shade700),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    '${result.yesCount} yes votes',
                    style: const TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            CircleAvatar(
              radius: 16,
              backgroundColor: const Color(0xFFFFE4B5),
              child: Text('${index + 1}'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhoto(SwipeRestaurant restaurant) {
    final reference = restaurant.photoReference;
    if (reference == null || reference.isEmpty) {
      return _photoPlaceholder();
    }

    return FutureBuilder<Uint8List>(
      future: photos.putIfAbsent(
        reference,
        () => widget.api.getPhoto(reference),
      ),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return Image.memory(snapshot.data!, fit: BoxFit.cover);
        }
        if (snapshot.hasError) {
          return _photoPlaceholder();
        }
        return const Center(child: CircularProgressIndicator(strokeWidth: 2));
      },
    );
  }

  Widget _photoPlaceholder() {
    return Container(
      color: const Color(0xFFFFE4B5),
      child: const Icon(Icons.restaurant, color: Color(0xFFE94F54)),
    );
  }

  Widget _buildError() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(errorMessage!, textAlign: TextAlign.center),
        const SizedBox(height: 12),
        FilledButton(onPressed: loadResults, child: const Text('Try again')),
      ],
    );
  }

  void openNewSession() {
    Navigator.pushNamedAndRemoveUntil(
      context,
      '/create-session',
      (route) => route.settings.name == '/home',
    );
  }
}
