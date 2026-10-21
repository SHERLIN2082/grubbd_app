import 'package:flutter/material.dart';
import 'package:grubbd_app/core/widgets/app_back_button.dart';
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
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.96),
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: const [
                        BoxShadow(color: Color(0x28000000), blurRadius: 24, offset: Offset(0, 8)),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const AppBackButton(),
                            const SizedBox(width: 8),
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
                        const Center(
                          child: Text(
                            '🔑',
                            style: TextStyle(fontSize: 40),
                          ),
                        ),
                        const SizedBox(height: 10),
                        const Center(
                          child: Text(
                            'Enter the room code',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF1E1A1A),
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Center(
                          child: Text(
                            'Ask the session host for their 5-character code.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 13.5, color: Color(0xFF756D69)),
                          ),
                        ),
                        const SizedBox(height: 24),
                        TextField(
                          key: const Key('room-code-field'),
                          controller: codeController,
                          maxLength: 5,
                          textAlign: TextAlign.center,
                          textCapitalization: TextCapitalization.characters,
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 10,
                            color: Color(0xFFFF594D),
                          ),
                          decoration: InputDecoration(
                            counterText: '',
                            hintText: 'A7B2C',
                            hintStyle: const TextStyle(
                              color: Color(0xFFD4C8C2),
                              fontSize: 28,
                              letterSpacing: 8,
                            ),
                            filled: true,
                            fillColor: const Color(0xFFFFF6F4),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(18),
                              borderSide: const BorderSide(color: Color(0xFFFF594D), width: 1.5),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(18),
                              borderSide: BorderSide(color: const Color(0xFFFF594D).withOpacity(0.3), width: 1.5),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(18),
                              borderSide: const BorderSide(color: Color(0xFFFF594D), width: 2),
                            ),
                          ),
                          onChanged: (_) {
                            if (errorMessage != null) {
                              setState(() => errorMessage = null);
                            }
                          },
                          onSubmitted: (_) => joinSession(),
                        ),
                        if (errorMessage != null) ...[
                          const SizedBox(height: 10),
                          Center(
                            child: Text(
                              errorMessage!,
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w700, fontSize: 13),
                            ),
                          ),
                        ],
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: FilledButton(
                            key: const Key('join-session-submit'),
                            onPressed: isJoining ? null : joinSession,
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFFFF594D),
                              elevation: 2,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                            child: isJoining
                                ? const SizedBox.square(
                                    dimension: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text('Join Session', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
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
