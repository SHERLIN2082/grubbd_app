import 'dart:async';

import 'package:flutter/material.dart';
import 'package:grubbd_app/core/network/lobby_api.dart';
import 'package:grubbd_app/features/first_screen/first_screen.dart';

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

  @override
  void initState() {
    super.initState();
    api = widget.api ?? LobbyApi();
    loadLobby();
    refreshTimer = Timer.periodic(
      const Duration(seconds: 3),
      (_) => refreshParticipants(),
    );
  }

  @override
  void dispose() {
    refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> loadLobby() async {
    try {
      final results = await Future.wait([
        api.getSession(widget.sessionId),
        api.getParticipants(widget.sessionId),
      ]);
      if (!mounted) return;
      setState(() {
        details = results[0] as LobbyDetails;
        participants = results[1] as List<LobbyParticipant>;
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

  Future<void> refreshParticipants() async {
    if (!mounted || details == null || details!.status != 'LOBBY') return;
    try {
      final updated = await api.getParticipants(widget.sessionId);
      if (mounted) setState(() => participants = updated);
    } catch (_) {
      // Keep the last good participant list during a temporary refresh error.
    }
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
      setState(() {
        details = LobbyDetails(
          id: details!.id,
          roomCode: details!.roomCode,
          status: 'ACTIVE',
          isHost: details!.isHost,
          locationName: details!.locationName,
          radiusKm: details!.radiusKm,
          priceLevels: details!.priceLevels,
          matchRule: details!.matchRule,
        );
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Session started - time to swipe!')),
      );
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
              onPressed: () => Navigator.pop(context),
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
        leading: CircleAvatar(
          radius: 17,
          backgroundColor: const Color(0xFFFFE4B5),
          child: Text(
            participant.avatar.isEmpty ? initials : participant.avatar,
          ),
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
