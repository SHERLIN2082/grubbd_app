import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:grubbd_app/core/network/swipe_deck_api.dart';
import 'package:grubbd_app/features/card_details/card_details_screen.dart';
import 'package:grubbd_app/features/first_screen/first_screen.dart';
import 'package:grubbd_app/features/match/match_screen.dart';

class SwipeDeckScreen extends StatefulWidget {
  const SwipeDeckScreen({super.key, required this.sessionId, this.api});

  final String sessionId;
  final SwipeDeckApi? api;

  @override
  State<SwipeDeckScreen> createState() => _SwipeDeckScreenState();
}

class _SwipeDeckScreenState extends State<SwipeDeckScreen> {
  late final SwipeDeckApi api;
  List<SwipeRestaurant> restaurants = const [];
  int currentIndex = 0;
  bool isLoading = true;
  bool isVoting = false;
  String? errorMessage;
  final Map<String, Future<Uint8List>> photoFutures = {};
  final Set<String> shownMatchIds = {};
  Timer? matchTimer;
  bool isShowingMatch = false;

  @override
  void initState() {
    super.initState();
    api = widget.api ?? SwipeDeckApi();
    loadDeck();
    matchTimer = Timer.periodic(
      const Duration(seconds: 3),
      (_) => checkForMatch(),
    );
  }

  @override
  void dispose() {
    matchTimer?.cancel();
    super.dispose();
  }

  Future<void> checkForMatch() async {
    if (!mounted || isShowingMatch) return;
    try {
      final matchId = await api.getLatestMatchId(widget.sessionId);
      if (matchId != null && !shownMatchIds.contains(matchId)) {
        await showMatch(matchId);
      }
    } catch (_) {
      // A temporary polling error should not stop restaurant swiping.
    }
  }

  Future<void> showMatch(String matchId) async {
    if (!mounted || isShowingMatch || shownMatchIds.contains(matchId)) return;
    isShowingMatch = true;
    shownMatchIds.add(matchId);
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MatchScreen(
          sessionId: widget.sessionId,
          matchId: matchId,
          api: api,
        ),
      ),
    );
    isShowingMatch = false;
  }

  Future<void> loadDeck() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });
    try {
      final result = await api.getRestaurants(widget.sessionId);
      if (!mounted) return;
      setState(() {
        restaurants = result;
        currentIndex = 0;
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

  Future<bool> submitVote(bool liked) async {
    if (isVoting || currentIndex >= restaurants.length) return false;
    final restaurant = restaurants[currentIndex];
    setState(() => isVoting = true);
    try {
      final result = await api.submitSwipe(
        sessionId: widget.sessionId,
        restaurantId: restaurant.id,
        liked: liked,
      );
      if (!mounted) return false;
      if (result.matched && result.matchId != null) {
        await showMatch(result.matchId!);
      }
      return true;
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error.toString().replaceFirst('Exception: ', '')),
          ),
        );
      }
      return false;
    } finally {
      if (mounted) setState(() => isVoting = false);
    }
  }

  Future<void> vote(bool liked) async {
    final submitted = await submitVote(liked);
    if (submitted && mounted) setState(() => currentIndex++);
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
    if (errorMessage != null) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(errorMessage!, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          FilledButton(onPressed: loadDeck, child: const Text('Try again')),
        ],
      );
    }
    if (restaurants.isEmpty) return _emptyDeck('No restaurants were found.');
    if (currentIndex >= restaurants.length) {
      return _emptyDeck('You have finished the deck!');
    }

    final restaurant = restaurants[currentIndex];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back),
            ),
            Text(
              'Card ${currentIndex + 1} of ${restaurants.length}',
              key: const Key('deck-progress'),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const Spacer(),
            const Icon(Icons.people_alt_outlined, size: 19),
          ],
        ),
        const SizedBox(height: 14),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              const cardRatio = 1.22;
              var cardWidth = constraints.maxWidth > 360
                  ? 360.0
                  : constraints.maxWidth;
              var cardHeight = cardWidth * cardRatio;

              if (cardHeight > constraints.maxHeight) {
                cardHeight = constraints.maxHeight;
                cardWidth = cardHeight / cardRatio;
              }

              return Center(
                child: SizedBox(
                  width: cardWidth,
                  height: cardHeight,
                  child: Dismissible(
                    key: ValueKey(restaurant.id),
                    direction: isVoting
                        ? DismissDirection.none
                        : DismissDirection.horizontal,
                    confirmDismiss: (direction) async {
                      return submitVote(
                        direction == DismissDirection.startToEnd,
                      );
                    },
                    onDismissed: (_) => setState(() => currentIndex++),
                    background: _swipeBackground(true),
                    secondaryBackground: _swipeBackground(false),
                    child: _restaurantCard(restaurant),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 18),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _voteButton(
              key: const Key('vote-no-button'),
              icon: Icons.close,
              color: const Color(0xFFE94F54),
              onPressed: () => vote(false),
            ),
            const SizedBox(width: 34),
            _voteButton(
              key: const Key('vote-yes-button'),
              icon: Icons.favorite,
              color: Colors.green,
              onPressed: () => vote(true),
            ),
          ],
        ),
      ],
    );
  }

  Widget _restaurantCard(SwipeRestaurant restaurant) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CardDetailsScreen(
            sessionId: widget.sessionId,
            restaurantId: restaurant.id,
            api: api,
          ),
        ),
      ),
      child: Card(
        elevation: 0,
        color: Colors.white,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _restaurantPhoto(restaurant)),
            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    restaurant.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Row(
                    children: [
                      const Icon(Icons.star, size: 18, color: Colors.amber),
                      Text(restaurant.rating?.toStringAsFixed(1) ?? 'New'),
                      const SizedBox(width: 12),
                      Text(_priceText(restaurant.priceLevel)),
                    ],
                  ),
                  if (restaurant.address?.isNotEmpty == true) ...[
                    const SizedBox(height: 8),
                    Text(
                      restaurant.address!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: Colors.grey.shade700),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _restaurantPhoto(SwipeRestaurant restaurant) {
    final reference = restaurant.photoReference;
    if (reference == null || reference.isEmpty) return _photoPlaceholder();
    return FutureBuilder<Uint8List>(
      future: photoFutures.putIfAbsent(
        reference,
        () => api.getPhoto(reference),
      ),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return Image.memory(
            snapshot.data!,
            width: double.infinity,
            height: double.infinity,
            fit: BoxFit.cover,
          );
        }
        if (snapshot.hasError) return _photoPlaceholder();
        return const Center(child: CircularProgressIndicator());
      },
    );
  }

  Widget _photoPlaceholder() {
    return Container(
      width: double.infinity,
      color: const Color(0xFFFFE4B5),
      child: const Icon(Icons.restaurant, size: 80, color: Color(0xFFE94F54)),
    );
  }

  Widget _swipeBackground(bool liked) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      alignment: liked ? Alignment.centerLeft : Alignment.centerRight,
      decoration: BoxDecoration(
        color: liked ? Colors.green : const Color(0xFFE94F54),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Text(
        liked ? 'YES' : 'NO',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 24,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  Widget _voteButton({
    required Key key,
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return IconButton.filled(
      key: key,
      onPressed: isVoting ? null : onPressed,
      style: IconButton.styleFrom(
        backgroundColor: color.withValues(alpha: 0.13),
        foregroundColor: color,
        disabledBackgroundColor: Colors.grey.shade200,
        minimumSize: const Size(58, 58),
      ),
      icon: isVoting
          ? const SizedBox.square(
              dimension: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Icon(icon),
    );
  }

  String _priceText(int? priceLevel) {
    if (priceLevel == null) return 'Price unavailable';
    if (priceLevel == 0) return 'Free';
    return List.filled(priceLevel, r'$').join();
  }

  Widget _emptyDeck(String message) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.check_circle_outline, size: 72, color: Colors.green),
        const SizedBox(height: 16),
        Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        const Text('Waiting for everyone else to finish swiping.'),
      ],
    );
  }
}
