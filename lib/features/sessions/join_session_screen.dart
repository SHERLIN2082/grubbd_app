import 'package:flutter/material.dart';
import 'package:grubbd_app/core/network/home_api.dart';
import 'package:grubbd_app/features/first_screen/first_screen.dart';
import 'package:grubbd_app/features/lobby/lobby_screen.dart';

class JoinSessionScreen extends StatefulWidget {
  const JoinSessionScreen({super.key, this.homeApi, this.initialRoomCode});

  final HomeApi? homeApi;
  final String? initialRoomCode;

  @override
  State<JoinSessionScreen> createState() => _JoinSessionScreenState();
}

class _JoinSessionScreenState extends State<JoinSessionScreen> {
  late final TextEditingController codeController;
  late final HomeApi homeApi;
  bool isJoining = false;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    codeController = TextEditingController(text: widget.initialRoomCode ?? '');
    homeApi = widget.homeApi ?? HomeApi();
  }

  @override
  void dispose() {
    codeController.dispose();
    super.dispose();
  }

  Future<void> joinSession() async {
    final roomCode = codeController.text.trim().toUpperCase();

    if (roomCode.length != 5) {
      setState(() => errorMessage = 'Enter a valid 5-character room code');
      return;
    }

    setState(() {
      isJoining = true;
      errorMessage = null;
    });

    try {
      final session = await homeApi.joinSession(roomCode);
      if (!mounted) return;
      await Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => LobbyScreen(sessionId: session.id)),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() {
        errorMessage = error.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) setState(() => isJoining = false);
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
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xF2FFF8EE),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: const [
                        BoxShadow(color: Colors.black26, blurRadius: 18),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            IconButton(
                              onPressed: () => Navigator.pop(context),
                              icon: const Icon(Icons.arrow_back),
                            ),
                            const Text(
                              'Join Session',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        const Text(
                          'Enter the room code',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Ask the session host for their 5-character code.',
                        ),
                        const SizedBox(height: 22),
                        TextField(
                          key: const Key('room-code-field'),
                          controller: codeController,
                          maxLength: 5,
                          textAlign: TextAlign.center,
                          textCapitalization: TextCapitalization.characters,
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 10,
                          ),
                          decoration: InputDecoration(
                            hintText: 'A7B2C',
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          onChanged: (_) {
                            if (errorMessage != null) {
                              setState(() => errorMessage = null);
                            }
                          },
                          onSubmitted: (_) => joinSession(),
                        ),
                        if (errorMessage != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Text(
                              errorMessage!,
                              style: const TextStyle(color: Colors.red),
                            ),
                          ),
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: FilledButton(
                            key: const Key('join-session-submit'),
                            onPressed: isJoining ? null : joinSession,
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFFE94F54),
                            ),
                            child: isJoining
                                ? const SizedBox.square(
                                    dimension: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text('Join Session'),
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
}
