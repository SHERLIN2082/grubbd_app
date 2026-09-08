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
      if (mounted) {
        setState(() {
          errorMessage = error.toString().replaceFirst('Exception: ', '');
        });
      }
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
      // Keep the last good participant list during a temporary refresh error.
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
    if (participants.length == 1) {
      final startSolo = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Start by yourself?'),
          content: const Text(
            'You are the only person in this lobby. You can start swiping now '
            'or wait for teammates to join.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Wait for teammates'),
            ),
            FilledButton(
              key: const Key('start-solo-button'),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Start solo'),
            ),
          ],
        ),
      );
      if (startSolo != true || !mounted) return;
    }

    await startSwiping();
  }

  Future<void> startSwiping() async {
    setState(() => isStarting = true);
    try {
      await api.startSession(widget.sessionId);
      if (!mounted) return;
      await openSwipeDeck();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error.toString().replaceFirst('Exception: ', '')),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => isStarting = false);
    }
  }

  Future<void> leaveLobby() async {
    if (isLeaving) return;

    if (details?.isHost == true) {
      final shouldLeave = await showLeaveConfirmation();
      if (!shouldLeave) return;
      refreshTimer?.cancel();
    }

    setState(() => isLeaving = true);

    try {
      await api.leaveSession(widget.sessionId);
      if (!mounted) return;

      Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
        ),
      );
      setState(() => isLeaving = false);
    }
  }

  Future<bool> showLeaveConfirmation() async {
    final answer = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Leave the session?'),
        content: const Text(
          'You are the host. If you leave, the session will close for everyone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            key: const Key('confirm-host-leave-button'),
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFE94F54),
            ),
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
    final inviteLink = DeepLinkService.createInviteLink(roomCode);
    final message = 'Join my Grubbd room!\nRoom code: $roomCode\n$inviteLink';

    try {
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
    } catch (_) {
      // Some browsers do not support the system share window.
    }

    await Clipboard.setData(ClipboardData(text: message));

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Invite copied to clipboard!')),
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
                  constraints: const BoxConstraints(maxWidth: 430),
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
    if (errorMessage != null || details == null) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(errorMessage ?? 'Could not load this lobby'),
          const SizedBox(height: 12),
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
              'Lobby',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
            ),
            const Spacer(),
            IconButton(onPressed: loadLobby, icon: const Icon(Icons.refresh)),
          ],
        ),
        const SizedBox(height: 8),
        const Center(
          child: Text(
            'ROOM CODE',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
          ),
        ),
        Center(
          child: SelectableText(
            lobby.roomCode,
            key: const Key('lobby-room-code'),
            style: const TextStyle(
              color: Color(0xFFE94F54),
              fontSize: 30,
              fontWeight: FontWeight.w900,
              letterSpacing: 7,
            ),
          ),
        ),
        Center(
          child: TextButton.icon(
            key: const Key('share-invite-link-button'),
            onPressed: () => shareInviteLink(lobby.roomCode),
            icon: const Icon(Icons.share),
            label: const Text('Share Invite'),
          ),
        ),
        const SizedBox(height: 16),
        _settingsCard(lobby),
        const SizedBox(height: 18),
        Text(
          '${participants.length} ${participants.length == 1 ? 'person' : 'people'} joined',
          key: const Key('participant-count'),
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 10),
        Expanded(
          child: RefreshIndicator(
            onRefresh: refreshParticipants,
            child: ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: participants.length,
              itemBuilder: (_, index) => _participantTile(participants[index]),
            ),
          ),
        ),
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
                backgroundColor: const Color(0xFFE94F54),
              ),
              child: isStarting
                  ? const SizedBox.square(
                      dimension: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(lobby.status == 'LOBBY' ? 'Start Swiping' : 'Started'),
            ),
          )
        else
          const SizedBox(
            width: double.infinity,
            child: Text(
              'Waiting for the host to start…',
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.w700),
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
        ? 'Any price'
        : lobby.priceLevels.map((level) => r'$' * level).join(' · ');
    final rule = lobby.matchRule == 'ALL'
        ? 'Everyone agrees'
        : 'Majority agrees';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFE4B5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          _settingRow(
            Icons.location_on_outlined,
            '${lobby.locationName} · $radius km',
          ),
          const SizedBox(height: 10),
          _settingRow(Icons.restaurant_outlined, '$prices · $rule'),
        ],
      ),
    );
  }

  Widget _settingRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 18, color: const Color(0xFFE94F54)),
        const SizedBox(width: 10),
        Expanded(child: Text(text, overflow: TextOverflow.ellipsis)),
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
    return Card(
      color: Colors.white,
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ListTile(
        dense: true,
        leading: AvatarImage(
          avatar: participant.avatar,
          fallbackText: initials,
          size: 34,
        ),
        title: Text(
          participant.displayName,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        trailing: Text(
          participant.isHost ? 'Host' : 'Ready',
          style: TextStyle(
            color: participant.isHost
                ? const Color(0xFFE94F54)
                : Colors.green.shade700,
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}
