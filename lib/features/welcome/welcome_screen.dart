import 'package:flutter/material.dart';
import 'package:grubbd_app/core/network/home_api.dart';
import 'package:grubbd_app/features/first_screen/first_screen.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key, this.homeApi});

  final HomeApi? homeApi;

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  late final HomeApi homeApi;
  String? displayName;
  String? avatar;
  String? errorMessage;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    homeApi = widget.homeApi ?? HomeApi();
    loadProfile();
  }

  Future<void> loadProfile() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final homeData = await homeApi.loadHome();
      if (!mounted) return;

      setState(() {
        displayName = homeData.displayName;
        avatar = homeData.avatar;
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
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 430),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      color: const Color(0xF2FFF8EE),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: const [
                        BoxShadow(color: Colors.black26, blurRadius: 18),
                      ],
                    ),
                    child: buildContent(),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildContent() {
    if (isLoading) {
      return const SizedBox(
        height: 300,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (errorMessage != null) {
      return buildError();
    }

    return Column(
      children: [
        CircleAvatar(
          radius: 44,
          backgroundColor: const Color(0xFFE94F54),
          child: Text(avatar ?? '', style: const TextStyle(fontSize: 38)),
        ),
        const SizedBox(height: 24),
        Text(
          'Welcome to Grubbd, $displayName!',
          key: const Key('welcome-message'),
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 10),
        const Text(
          'Let\'s find something delicious together.',
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 30),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: FilledButton(
            key: const Key('welcome-continue-button'),
            onPressed: openHome,
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFE94F54),
            ),
            child: const Text('Continue'),
          ),
        ),
      ],
    );
  }

  Widget buildError() {
    return Column(
      children: [
        Text(errorMessage!, textAlign: TextAlign.center),
        const SizedBox(height: 12),
        FilledButton(onPressed: loadProfile, child: const Text('Try again')),
      ],
    );
  }

  void openHome() {
    Navigator.pushReplacementNamed(context, '/home');
  }
}
