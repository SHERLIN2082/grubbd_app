import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:grubbd_app/core/deep_links/deep_link_service.dart';
import 'package:grubbd_app/core/network/lobby_api.dart';
import 'package:grubbd_app/core/widgets/avatar_image.dart';
import 'package:grubbd_app/features/first_screen/first_screen.dart';
import 'package:grubbd_app/features/sessions/host_left_screen.dart';
import 'package:grubbd_app/features/swipe_deck/swipe_deck_screen.dart';
import 'package:share_plus/share_plus.dart';

class LobbyScreen extends StatefulWidget {
  const LobbyScreen({super.key, required this.sessionId, this.api});

  final String sessionId;
  final LobbyApi? api;

  @override
  State<LobbyScreen> createState() => _LobbyScreenState();
}

class _LobbyScreenState extends State<LobbyScreen> {
  late final LobbyApi api;
  LobbyDetails? details;
  List<LobbyParticipant> participants = const [];
  Timer? refreshTimer;
  String? errorMessage;
  bool isLoading = true;
  bool isStarting = false;
  bool isOpeningDeck = false;
  bool isLeaving = false;

  @override
  void initState() {
    super.initState();
    api = widget.api ?? LobbyApi();
    loadLobby();
    refreshTimer = Timer.periodic(
      const Duration(seconds: 3),
      (_) => refreshLobby(),
    );
  }

  @override
  void dispose() {
    refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> loadLobby() async {
    try {
      final loadedDetails = await api.getSession(widget.sessionId);
      final loadedParticipants = await api.getParticipants(widget.sessionId);
      if (!mounted) return;

      if (loadedDetails.status == 'HOST_LEFT' && !loadedDetails.isHost) {
        await openHostLeftScreen();
        return;
      }

      setState(() {
        details = loadedDetails;
        participants = loadedParticipants;
        errorMessage = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        errorMessage = error.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> refreshLobby() async {
    if (!mounted || details == null || details!.status != 'LOBBY') return;
    try {
      final updatedDetails = await api.getSession(widget.sessionId);
      final updatedParticipants = await api.getParticipants(widget.sessionId);
      if (!mounted) return;

      if (updatedDetails.status == 'HOST_LEFT' && !updatedDetails.isHost) {
        await openHostLeftScreen();
        return;
      }

      if (updatedDetails.status == 'ACTIVE') {
        await openSwipeDeck();
        return;
      }
      setState(() {
        details = updatedDetails;
        participants = updatedParticipants;
      });
    } catch (_) {
      // Keep last good participant list during temporary error
    }
  }

  Future<void> refreshParticipants() async => refreshLobby();

  Future<void> openSwipeDeck() async {
    if (!mounted || isOpeningDeck) return;
    isOpeningDeck = true;
    refreshTimer?.cancel();
    await Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => SwipeDeckScreen(
          sessionId: widget.sessionId,
          isHost: details?.isHost ?? false,
        ),
      ),
    );
  }

  Future<void> confirmAndStartSwiping() async {
    if (participants.length <= 1) {
      final startSolo = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Start with just you? 🤔', style: TextStyle(fontWeight: FontWeight.w800)),
          content: const Text(
            'No friends have joined yet. You can swipe solo, or invite someone with the room code to swipe together!',
            style: TextStyle(fontSize: 13.5, color: Color(0xFF756D69), height: 1.35),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Wait for friends'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              style: FilledButton.styleFrom(backgroundColor: const Color(0xFFFF594D)),
              child: const Text('Start Solo'),
            ),
          ],
        ),
      );
      if (startSolo != true) return;
    }
    await startSwiping();
  }

  Future<void> startSwiping() async {
    setState(() => isStarting = true);
    try {
      await api.startSession(widget.sessionId);
      await openSwipeDeck();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.toString().replaceFirst('Exception: ', ''))),
        );
      }
    } finally {
      if (mounted) setState(() => isStarting = false);
    }
  }

  Future<void> leaveLobby() async {
    if (details == null) {
      Navigator.pop(context);
      return;
    }

    final confirmed = details!.isHost
        ? await showHostLeaveConfirmation()
        : await showParticipantLeaveConfirmation();

    if (!confirmed || !mounted) return;

    setState(() => isLeaving = true);
    try {
      await api.leaveSession(widget.sessionId);
      refreshTimer?.cancel();
      if (!mounted) return;
      Navigator.pop(context);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.toString().replaceFirst('Exception: ', ''))),
        );
      }
    } finally {
      if (mounted) setState(() => isLeaving = false);
    }
  }

  Future<bool> showParticipantLeaveConfirmation() async {
    final answer = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Leave session?'),
        content: const Text('Are you sure you want to leave this dinner lobby?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFFF594D)),
            child: const Text('Leave'),
          ),
        ],
      ),
    );
    return answer == true;
  }

  Future<bool> showHostLeaveConfirmation() async {
    final answer = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('End the session?'),
        content: const Text('You are the host. If you leave, the session will close for all members.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(
            key: const Key('confirm-host-leave-button'),
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFFF594D)),
            child: const Text('Leave Session'),
          ),
        ],
      ),
    );
    return answer == true;
  }

  Future<void> openHostLeftScreen() async {
    refreshTimer?.cancel();
    await Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const HostLeftScreen()),
    );
  }

  Future<void> shareInviteLink(String roomCode) async {
    try {
      final inviteLink = DeepLinkService.createInviteLink(roomCode);
      final message = 'Join my Grubbd food decision!\nRoom code: $roomCode\n$inviteLink';

      final result = await SharePlus.instance.share(
        ShareParams(
          title: 'Join my Grubbd room',
          subject: 'Grubbd room $roomCode',
          text: message,
        ),
      );

      if (result.status != ShareResultStatus.unavailable) {
        return;
      }

      await Clipboard.setData(ClipboardData(text: message));
    } catch (_) {
      await Clipboard.setData(
        ClipboardData(text: 'Join my Grubbd room! Room code: $roomCode'),
      );
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        backgroundColor: Color(0xFF1E1A1A),
        content: Text('Invite copied to clipboard! 📋'),
      ),
    );
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
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.96),
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: const [
                        BoxShadow(color: Color(0x28000000), blurRadius: 24, offset: Offset(0, 8)),
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
    if (isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Color(0xFFFF594D)),
            SizedBox(height: 14),
            Text('Entering food lobby...', style: TextStyle(color: Color(0xFF756D69))),
          ],
        ),
      );
    }

    if (errorMessage != null || details == null) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline_rounded, color: Color(0xFFFF594D), size: 44),
          const SizedBox(height: 12),
          Text(errorMessage ?? 'Could not load this lobby', textAlign: TextAlign.center),
          const SizedBox(height: 14),
          FilledButton(onPressed: loadLobby, child: const Text('Try again')),
        ],
      );
    }

    final lobby = details!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            IconButton(
              onPressed: isLeaving ? null : leaveLobby,
              icon: const Icon(Icons.arrow_back),
            ),
            const Text(
              'Dinner Lobby 🍔',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF1E1A1A)),
            ),
            const Spacer(),
            IconButton(
              tooltip: 'Refresh',
              onPressed: loadLobby,
              icon: const Icon(Icons.refresh_rounded),
            ),
          ],
        ),

        const SizedBox(height: 12),

        // Room Code Ticket Card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFFFF0EC), Color(0xFFFFE0D9)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFFF594D).withOpacity(0.3), width: 1.5),
          ),
          child: Column(
            children: [
              const Text(
                'INVITE CODE',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                  color: Color(0xFFFF594D),
                ),
              ),
              const SizedBox(height: 4),
              SelectableText(
                lobby.roomCode,
                key: const Key('lobby-room-code'),
                style: const TextStyle(
                  color: Color(0xFFFF594D),
                  fontSize: 34,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 8,
                ),
              ),
              const SizedBox(height: 6),
              OutlinedButton.icon(
                key: const Key('share-invite-link-button'),
                onPressed: () => shareInviteLink(lobby.roomCode),
                icon: const Icon(Icons.share_rounded, size: 16, color: Color(0xFFFF594D)),
                label: const Text(
                  'Share Invite Link 🔗',
                  style: TextStyle(color: Color(0xFFFF594D), fontWeight: FontWeight.w800, fontSize: 13),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFFFF594D), width: 1.5),
                  backgroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  minimumSize: Size.zero,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        _settingsCard(lobby),

        const SizedBox(height: 18),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${participants.length} ${participants.length == 1 ? 'person' : 'people'} joined',
              key: const Key('participant-count'),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF1E1A1A)),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.circle, color: Color(0xFF2E7D32), size: 8),
                  SizedBox(width: 4),
                  Text(
                    'Live Room',
                    style: TextStyle(color: Color(0xFF2E7D32), fontSize: 11, fontWeight: FontWeight.w800),
                  ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 8),

        Expanded(
          child: RefreshIndicator(
            color: const Color(0xFFFF594D),
            onRefresh: refreshParticipants,
            child: ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: participants.length,
              itemBuilder: (_, index) => _participantTile(participants[index]),
            ),
          ),
        ),

        const SizedBox(height: 12),

        if (lobby.isHost)
          SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton(
              key: const Key('start-swiping-button'),
              onPressed: isStarting || lobby.status != 'LOBBY'
                  ? null
                  : confirmAndStartSwiping,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFFF594D),
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: isStarting
                  ? const SizedBox.square(
                      dimension: 22,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : Text(
                      lobby.status == 'LOBBY' ? 'Start Swiping 🚀' : 'Started',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                    ),
            ),
          )
        else
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF9EE),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFFF9F1C)),
                ),
                SizedBox(width: 10),
                Text(
                  'Waiting for host to start swiping…',
                  style: TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF756D69), fontSize: 13.5),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _settingsCard(LobbyDetails lobby) {
    final radius = lobby.radiusKm == lobby.radiusKm.roundToDouble()
        ? lobby.radiusKm.round().toString()
        : lobby.radiusKm.toStringAsFixed(1);
    final prices = lobby.priceLevels.isEmpty
        ? 'Any budget'
        : lobby.priceLevels.map((level) => r'$' * level).join(' · ');
    final rule = lobby.matchRule == 'ALL'
        ? 'Unanimous match'
        : 'Majority vote';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withOpacity(0.06)),
      ),
      child: Column(
        children: [
          _settingRow(
            Icons.location_on_outlined,
            '${lobby.locationName} · Within $radius km',
          ),
          const SizedBox(height: 6),
          _settingRow(Icons.restaurant_outlined, '$prices · $rule'),
        ],
      ),
    );
  }

  Widget _settingRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: const Color(0xFFFF594D)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: Color(0xFF55504E)),
          ),
        ),
      ],
    );
  }

  Widget _participantTile(LobbyParticipant participant) {
    final initials = participant.displayName
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .take(2)
        .map((part) => part[0].toUpperCase())
        .join();
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withOpacity(0.06)),
      ),
      child: ListTile(
        dense: true,
        leading: AvatarImage(
          avatar: participant.avatar,
          fallbackText: initials,
          size: 36,
        ),
        title: Text(
          participant.displayName,
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: participant.isHost ? const Color(0xFFFFE0D9) : const Color(0xFFE8F5E9),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            participant.isHost ? 'Host ⭐' : 'Ready 👍',
            style: TextStyle(
              color: participant.isHost ? const Color(0xFFFF594D) : const Color(0xFF2E7D32),
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}
