import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:grubbd_app/core/constants/app_assets.dart';
import 'package:grubbd_app/core/network/profile_api.dart';

class AvatarSetupScreen extends StatefulWidget {
  const AvatarSetupScreen({super.key, this.profileApi});

  final ProfileApi? profileApi;

  @override
  State<AvatarSetupScreen> createState() => _AvatarSetupScreenState();
}

class _AvatarSetupScreenState extends State<AvatarSetupScreen> {
  static const avatars = [
    'assets/images/avatars/avatar-1.png',
    'assets/images/avatars/avatar-2.png',
    'assets/images/avatars/avatar-3.png',
    'assets/images/avatars/avatar-4.png',
    'assets/images/avatars/avatar-5.png',
    'assets/images/avatars/avatar-6.png',
    'assets/images/avatars/avatar-7.png',
    'assets/images/avatars/avatar-8.png',
    'assets/images/avatars/avatar-9.png',
    'assets/images/avatars/avatar-10.png',
    'assets/images/avatars/avatar-11.png',
    'assets/images/avatars/avatar-12.png',
    'assets/images/avatars/avatar-13.png',
    'assets/images/avatars/avatar-14.png',
    'assets/images/avatars/avatar-15.png',
    'assets/images/avatars/avatar-16.png',
    'assets/images/avatars/avatar-17.png',
    'assets/images/avatars/avatar-18.png',
    'assets/images/avatars/avatar-19.png',
    'assets/images/avatars/avatar-20.png',
  ];

  final nameController = TextEditingController();
  late final ProfileApi profileApi;
  int selectedAvatarIndex = 0;
  int avatarSlideDirection = 1;
  bool isSaving = false;

  String get selectedAvatar => avatars[selectedAvatarIndex];

  @override
  void initState() {
    super.initState();
    profileApi = widget.profileApi ?? ProfileApi();
  }

  @override
  void dispose() {
    nameController.dispose();
    super.dispose();
  }

  Future<void> saveProfile() async {
    final name = nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please enter your name')));
      return;
    }

    setState(() => isSaving = true);

    try {
      await profileApi.saveProfile(displayName: name, avatar: selectedAvatar);

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Profile saved!')));
      await Navigator.pushReplacementNamed(context, '/welcome');
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
        ),
      );
    } finally {
      if (mounted) setState(() => isSaving = false);
    }
  }

  void showPreviousAvatar() {
    setState(() {
      avatarSlideDirection = -1;
      selectedAvatarIndex =
          (selectedAvatarIndex - 1 + avatars.length) % avatars.length;
    });
  }

  void showNextAvatar() {
    setState(() {
      avatarSlideDirection = 1;
      selectedAvatarIndex = (selectedAvatarIndex + 1) % avatars.length;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const Image(
            image: AssetImage(AppAssets.firstScreenBackground),
            fit: BoxFit.cover,
            alignment: Alignment.center,
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight:
                      MediaQuery.sizeOf(context).height -
                      MediaQuery.paddingOf(context).vertical -
                      40,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 430),
                    child: Container(
                    padding: const EdgeInsets.fromLTRB(18, 22, 18, 20),
                    decoration: BoxDecoration(
                      color: const Color(0xFFA48D78),
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x66000000),
                          blurRadius: 0,
                          offset: Offset(5, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'How do you want your friends call you?',
                          style: GoogleFonts.merriweather(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            height: 1.15,
                            shadows: const [
                              Shadow(
                                color: Colors.black38,
                                offset: Offset(0, 2),
                                blurRadius: 2,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          key: const Key('profile-name-field'),
                          controller: nameController,
                          style: GoogleFonts.merriweather(
                            color: const Color(0xFF5F3928),
                            fontWeight: FontWeight.w700,
                          ),
                          maxLength: 100,
                          decoration: InputDecoration(
                            counterText: '',
                            hintText: 'enter your name',
                            hintStyle: GoogleFonts.merriweather(
                              color: Color(0xFF9E9E9E),
                              fontWeight: FontWeight.w700,
                            ),
                            labelStyle: GoogleFonts.merriweather(),
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 13,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(3),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        Text(
                          'pick an avatar which matches your personality',
                          style: GoogleFonts.merriweather(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            height: 1.2,
                            shadows: const [
                              Shadow(
                                color: Colors.black38,
                                offset: Offset(0, 2),
                                blurRadius: 2,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          height: 132,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              IconButton(
                                key: const Key('previous-avatar-button'),
                                onPressed: showPreviousAvatar,
                                iconSize: 68,
                                color: Colors.white,
                                splashRadius: 36,
                                icon: const Icon(Icons.chevron_left),
                              ),
                              Expanded(
                                child: Center(
                                  child: AnimatedSwitcher(
                                    duration: const Duration(milliseconds: 320),
                                    switchInCurve: Curves.easeOutCubic,
                                    switchOutCurve: Curves.easeInCubic,
                                    transitionBuilder: (child, animation) {
                                      final offsetAnimation = Tween<Offset>(
                                        begin: Offset(
                                          avatarSlideDirection * 0.45,
                                          0,
                                        ),
                                        end: Offset.zero,
                                      ).animate(animation);

                                      return FadeTransition(
                                        opacity: animation,
                                        child: SlideTransition(
                                          position: offsetAnimation,
                                          child: child,
                                        ),
                                      );
                                    },
                                    child: Image.asset(
                                      selectedAvatar,
                                      key: ValueKey(selectedAvatar),
                                      height: 118,
                                      fit: BoxFit.contain,
                                      errorBuilder:
                                          (context, error, stackTrace) {
                                            return const Icon(
                                              Icons.person,
                                              size: 108,
                                              color: Colors.white,
                                            );
                                          },
                                    ),
                                  ),
                                ),
                              ),
                              IconButton(
                                key: const Key('next-avatar-button'),
                                onPressed: showNextAvatar,
                                iconSize: 68,
                                color: Colors.white,
                                splashRadius: 36,
                                icon: const Icon(Icons.chevron_right),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: FilledButton(
                            key: const Key('save-profile-button'),
                            onPressed: isSaving ? null : saveProfile,
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFFF4F1EA),
                              foregroundColor: const Color(0xFFA48D78),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            child: isSaving
                                ? const SizedBox.square(
                                    dimension: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Color(0xFFA48D78),
                                    ),
                                  )
                                : Text(
                                    'Continue',
                                    style: GoogleFonts.merriweather(
                                      color: const Color(0xFFA48D78),
                                      fontSize: 20,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
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
