import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:grubbd_app/core/network/swipe_deck_api.dart';
import 'package:grubbd_app/features/first_screen/first_screen.dart';
import 'package:url_launcher/url_launcher.dart';

class MatchScreen extends StatefulWidget {
  const MatchScreen({
    super.key,
    required this.sessionId,
    required this.matchId,
    required this.api,
  });

  final String sessionId;
  final String matchId;
  final SwipeDeckApi api;

  @override
  State<MatchScreen> createState() => _MatchScreenState();
}

class _MatchScreenState extends State<MatchScreen> {
  MatchDetails? match;
  Uint8List? photo;
  String? errorMessage;
  bool isLoading = true;
  bool isChoosing = false;

  @override
  void initState() {
    super.initState();
    loadMatch();
  }

  Future<void> loadMatch() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });
    try {
      final result = await widget.api.getMatch(
        widget.sessionId,
        widget.matchId,
      );
      Uint8List? loadedPhoto;
      final reference = result.restaurant.photoReference;
      if (reference != null && reference.isNotEmpty) {
        try {
          loadedPhoto = await widget.api.getPhoto(reference);
        } catch (_) {}
      }
      if (!mounted) return;
      setState(() {
        match = result;
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

  Future<void> chooseRestaurant() async {
    setState(() => isChoosing = true);
    try {
      await widget.api.chooseFinalRestaurant(
        widget.sessionId,
        match!.restaurant.id,
      );
      if (!mounted) return;
      await openMaps();
    } catch (error) {
      if (mounted) {
        showMessage(error.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => isChoosing = false);
    }
  }

  Future<void> openMaps() async {
    final url = match?.restaurant.googleMapsUrl;
    if (url == null || url.isEmpty) {
      showMessage('Google Maps is not available');
      return;
    }
    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
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
    if (errorMessage != null || match == null) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(errorMessage ?? 'Could not load the match'),
          const SizedBox(height: 12),
          FilledButton(onPressed: loadMatch, child: const Text('Try again')),
        ],
      );
    }

    final item = match!.restaurant;
    final screenHeight = MediaQuery.sizeOf(context).height;
    final imageHeight = (screenHeight * 0.27).clamp(160.0, 220.0);
    return Column(
      children: [
        const Spacer(),
        const Text('✦  ✦  ✦', style: TextStyle(color: Color(0xFFE94F54))),
        const SizedBox(height: 8),
        const Text(
          "It's a Match!",
          style: TextStyle(
            color: Color(0xFFE94F54),
            fontSize: 30,
            fontWeight: FontWeight.w900,
          ),
        ),
        Text(
          match!.voters.length == 1
              ? 'You matched with this restaurant.'
              : 'Your group matched with this restaurant.',
        ),
        const SizedBox(height: 22),
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
        const SizedBox(height: 20),
        Text(
          item.name,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 6),
        Text(
          item.address ?? '',
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 12),
        _voterAvatars(),
        const Spacer(),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Keep Swiping'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: FilledButton(
                key: const Key('match-action-button'),
                onPressed: isChoosing
                    ? null
                    : match!.isHost
                    ? chooseRestaurant
                    : openMaps,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFE94F54),
                ),
                child: isChoosing
                    ? const SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(match!.isHost ? 'Go With This' : 'Open Maps'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _voterAvatars() {
    return Wrap(
      spacing: 8,
      alignment: WrapAlignment.center,
      children: match!.voters.map((voter) {
        final initial = voter.name.isEmpty ? '?' : voter.name[0].toUpperCase();
        return CircleAvatar(
          backgroundColor: const Color(0xFFFFE4B5),
          child: Text(voter.avatar.isEmpty ? initial : voter.avatar),
        );
      }).toList(),
    );
  }
}
