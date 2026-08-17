import 'package:flutter/material.dart';
import 'package:grubbd_app/core/network/profile_api.dart';
import 'package:grubbd_app/features/first_screen/first_screen.dart';

class AvatarSetupScreen extends StatefulWidget {
  const AvatarSetupScreen({super.key, this.profileApi});

  final ProfileApi? profileApi;

  @override
  State<AvatarSetupScreen> createState() => _AvatarSetupScreenState();
}

class _AvatarSetupScreenState extends State<AvatarSetupScreen> {
  static const avatars = [
    '🐶',
    '🐱',
    '🐰',
    '🐻',
    '🐼',
    '🦊',
    '🐯',
    '🦁',
    '🐵',
    '🐸',
    '🐨',
    '🐮',
    '🐷',
    '🐥',
    '🦄',
    '🐙',
    '🐢',
    '🐬',
    '🦋',
    '🐝',
    '🦉',
    '🐧',
    '🐳',
    '🦖',
  ];

  final nameController = TextEditingController();
  late final ProfileApi profileApi;
  String selectedAvatar = avatars.first;
  bool isSaving = false;

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
      await Navigator.pushReplacementNamed(context, '/home');
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const FirstScreen(showBranding: false),
          SafeArea(
            child: SingleChildScrollView(
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
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Your profile',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 14),
                        const Text(
                          'How should friends see you?',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text('Pick a name and a fun food personality.'),
                        const SizedBox(height: 20),
                        TextField(
                          key: const Key('profile-name-field'),
                          controller: nameController,
                          maxLength: 100,
                          decoration: InputDecoration(
                            labelText: 'Your name',
                            hintText: 'Alex',
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Choose an avatar',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 12),
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 6,
                                crossAxisSpacing: 9,
                                mainAxisSpacing: 9,
                              ),
                          itemCount: avatars.length,
                          itemBuilder: (context, index) {
                            final avatar = avatars[index];
                            final isSelected = avatar == selectedAvatar;

                            return InkWell(
                              key: Key('avatar-$avatar'),
                              borderRadius: BorderRadius.circular(12),
                              onTap: () {
                                setState(() => selectedAvatar = avatar);
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? const Color(0xFFE94F54)
                                      : const Color(0xFFFFE4B5),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  avatar,
                                  style: TextStyle(
                                    color: isSelected
                                        ? Colors.white
                                        : const Color(0xFF5F3928),
                                    fontWeight: FontWeight.w800,
                                    fontSize: 24,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 20),
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFE4B5),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: const Color(0xFFE94F54),
                                foregroundColor: Colors.white,
                                child: Text(
                                  selectedAvatar,
                                  style: const TextStyle(fontSize: 22),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  nameController.text.trim().isEmpty
                                      ? 'Here\'s how others will see you'
                                      : nameController.text.trim(),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: FilledButton(
                            key: const Key('save-profile-button'),
                            onPressed: isSaving ? null : saveProfile,
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFFE94F54),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: isSaving
                                ? const SizedBox.square(
                                    dimension: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text('Continue'),
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
