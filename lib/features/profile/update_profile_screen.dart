import 'dart:math';
import 'package:flutter/material.dart';
import 'package:grubbd_app/core/network/home_api.dart';
import 'package:grubbd_app/core/network/profile_api.dart';
import 'package:grubbd_app/core/widgets/avatar_image.dart';

const List<String> kAvailableAvatars = [
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

/// Helper function to display the Update Profile Pop-up Dialog directly over the current screen.
Future<bool?> showUpdateProfileDialog(
  BuildContext context, {
  String? currentName,
  String? currentAvatar,
  ProfileApi? profileApi,
  HomeApi? homeApi,
}) {
  return showDialog<bool>(
    context: context,
    barrierDismissible: true,
    builder: (ctx) => UpdateProfileDialog(
      initialName: currentName,
      initialAvatar: currentAvatar,
      profileApi: profileApi,
      homeApi: homeApi,
    ),
  );
}

/// Fallback / route wrapper for `/update-profile`.
/// Renders [UpdateProfileDialog] as a centered pop-up modal over a semi-transparent scrim.
class UpdateProfileScreen extends StatelessWidget {
  const UpdateProfileScreen({
    super.key,
    this.initialName,
    this.initialAvatar,
    this.profileApi,
    this.homeApi,
  });

  final String? initialName;
  final String? initialAvatar;
  final ProfileApi? profileApi;
  final HomeApi? homeApi;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black.withOpacity(0.55),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: UpdateProfileDialog(
            initialName: initialName,
            initialAvatar: initialAvatar,
            profileApi: profileApi,
            homeApi: homeApi,
            onDismiss: () => Navigator.of(context).maybePop(false),
            onSaved: (_) => Navigator.of(context).pop(true),
          ),
        ),
      ),
    );
  }
}

/// In-place Pop-up Modal Dialog for editing foodie profile & avatar.
class UpdateProfileDialog extends StatefulWidget {
  const UpdateProfileDialog({
    super.key,
    this.initialName,
    this.initialAvatar,
    this.profileApi,
    this.homeApi,
    this.onDismiss,
    this.onSaved,
  });

  final String? initialName;
  final String? initialAvatar;
  final ProfileApi? profileApi;
  final HomeApi? homeApi;
  final VoidCallback? onDismiss;
  final ValueChanged<bool>? onSaved;

  @override
  State<UpdateProfileDialog> createState() => _UpdateProfileDialogState();
}

class _UpdateProfileDialogState extends State<UpdateProfileDialog> {
  final _nameController = TextEditingController();
  final _scrollController = ScrollController();
  late final ProfileApi _profileApi;
  late final HomeApi _homeApi;

  int _selectedAvatarIndex = 0;
  bool _isLoading = false;
  bool _isSaving = false;
  String? _errorMessage;

  String get _selectedAvatar => kAvailableAvatars[_selectedAvatarIndex];

  @override
  void initState() {
    super.initState();
    _profileApi = widget.profileApi ?? ProfileApi();
    _homeApi = widget.homeApi ?? HomeApi();

    if (widget.initialName != null) {
      _nameController.text = widget.initialName!;
    }
    if (widget.initialAvatar != null) {
      _selectedAvatarIndex = _findAvatarIndex(widget.initialAvatar!);
    }

    if (widget.initialName == null || widget.initialAvatar == null) {
      _loadProfile();
    }
  }

  int _findAvatarIndex(String avatar) {
    final clean = avatar.trim().replaceAll('\\', '/');
    for (var i = 0; i < kAvailableAvatars.length; i++) {
      if (kAvailableAvatars[i] == clean ||
          kAvailableAvatars[i].endsWith(clean) ||
          clean.endsWith(kAvailableAvatars[i])) {
        return i;
      }
      final fileName = kAvailableAvatars[i].split('/').last;
      if (clean.endsWith(fileName)) {
        return i;
      }
    }
    return 0;
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);
    try {
      final homeData = await _homeApi.loadHome();
      if (!mounted) return;
      if (_nameController.text.isEmpty && homeData.displayName.isNotEmpty) {
        _nameController.text = homeData.displayName;
      }
      if (widget.initialAvatar == null && homeData.avatar.isNotEmpty) {
        _selectedAvatarIndex = _findAvatarIndex(homeData.avatar);
      }
    } catch (_) {
      // In guest or test environment without network, keep defaults
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _shuffleAvatar() {
    final random = Random();
    int newIndex;
    do {
      newIndex = random.nextInt(kAvailableAvatars.length);
    } while (newIndex == _selectedAvatarIndex && kAvailableAvatars.length > 1);

    setState(() {
      _selectedAvatarIndex = newIndex;
    });

    // Auto-scroll to selected avatar in the horizontal list
    if (_scrollController.hasClients) {
      final offset = newIndex * 68.0;
      _scrollController.animateTo(
        offset.clamp(0.0, _scrollController.position.maxScrollExtent),
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      );
    }
  }

  Future<void> _saveProfile() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter your foodie nickname';
      });
      return;
    }

    setState(() {
      _errorMessage = null;
      _isSaving = true;
    });

    try {
      await _profileApi.saveProfile(
        displayName: name,
        avatar: _selectedAvatar,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Text('Profile updated successfully! 🎉'),
            ],
          ),
          backgroundColor: Color(0xFF26A69A),
          behavior: SnackBarBehavior.floating,
        ),
      );

      if (widget.onSaved != null) {
        widget.onSaved!(true);
      } else {
        Navigator.of(context).pop(true);
      }
    } catch (error) {
      if (!mounted) return;
      final msg = error.toString().replaceFirst('Exception: ', '');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: const Color(0xFFE53935),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _closeDialog() {
    if (widget.onDismiss != null) {
      widget.onDismiss!();
    } else {
      Navigator.of(context).maybePop(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      elevation: 16,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(22, 20, 22, 22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Top Title Bar with Close Button
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFE0D9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.person_pin_rounded,
                      color: Color(0xFFFF594D),
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Update Profile ✨',
                          style: TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF1E1A1A),
                          ),
                        ),
                        Text(
                          'Customize your avatar & foodie name',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF756D69),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Close',
                    icon: const Icon(Icons.close_rounded, color: Color(0xFF756D69)),
                    onPressed: _closeDialog,
                  ),
                ],
              ),

              const SizedBox(height: 18),

              if (_isLoading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Center(
                    child: CircularProgressIndicator(color: Color(0xFFFF594D)),
                  ),
                )
              else ...[
                // Hero Avatar Preview
                Center(
                  child: Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFF594D), Color(0xFFFF9F1C)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFFF594D).withOpacity(0.25),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Container(
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          padding: const EdgeInsets.all(4),
                          child: AvatarImage(
                            avatar: _selectedAvatar,
                            fallbackText: _nameController.text.isNotEmpty
                                ? _nameController.text[0].toUpperCase()
                                : '😋',
                            size: 84,
                          ),
                        ),
                      ),
                      // Shuffle mini-badge on hero
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: _shuffleAvatar,
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            padding: const EdgeInsets.all(7),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E1A1A),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x33000000),
                                  blurRadius: 6,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.shuffle_rounded,
                              size: 15,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 8),

                // Shuffle Helper Button
                Center(
                  child: TextButton.icon(
                    onPressed: _shuffleAvatar,
                    icon: const Icon(Icons.shuffle_rounded, size: 16, color: Color(0xFFFF594D)),
                    label: const Text(
                      'Shuffle Avatar',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFFF594D),
                      ),
                    ),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Avatar Horizontal Picker
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Choose Your Avatar',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1E1A1A),
                      ),
                    ),
                    Text(
                      '${_selectedAvatarIndex + 1} of ${kAvailableAvatars.length}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF756D69),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                SizedBox(
                  height: 72,
                  child: ListView.separated(
                    controller: _scrollController,
                    scrollDirection: Axis.horizontal,
                    itemCount: kAvailableAvatars.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 10),
                    itemBuilder: (context, index) {
                      final isSelected = index == _selectedAvatarIndex;
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedAvatarIndex = index;
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFFFFE0D9)
                                : const Color(0xFFF9F7F5),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isSelected
                                  ? const Color(0xFFFF594D)
                                  : Colors.black.withOpacity(0.08),
                              width: isSelected ? 2.5 : 1.2,
                            ),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: const Color(0xFFFF594D).withOpacity(0.2),
                                      blurRadius: 8,
                                      offset: const Offset(0, 3),
                                    )
                                  ]
                                : null,
                          ),
                          padding: const EdgeInsets.all(4),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              AvatarImage(
                                avatar: kAvailableAvatars[index],
                                fallbackText: '${index + 1}',
                                size: 48,
                              ),
                              if (isSelected)
                                Positioned(
                                  top: 0,
                                  right: 0,
                                  child: Container(
                                    padding: const EdgeInsets.all(2),
                                    decoration: const BoxDecoration(
                                      color: Color(0xFFFF594D),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.check,
                                      size: 10,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 20),

                // Name Input
                const Text(
                  'Foodie Nickname',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1E1A1A),
                  ),
                ),
                const SizedBox(height: 8),

                TextField(
                  key: const Key('profile-name-field'),
                  controller: _nameController,
                  textCapitalization: TextCapitalization.words,
                  onChanged: (_) {
                    if (_errorMessage != null) {
                      setState(() => _errorMessage = null);
                    }
                  },
                  decoration: InputDecoration(
                    hintText: 'e.g. Alex Rivera, TacoKing',
                    hintStyle: const TextStyle(color: Color(0xFFA59E9A), fontSize: 14),
                    prefixIcon: const Icon(
                      Icons.alternate_email_rounded,
                      color: Color(0xFFFF594D),
                      size: 20,
                    ),
                    suffixIcon: _nameController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18, color: Color(0xFF756D69)),
                            onPressed: () {
                              _nameController.clear();
                              setState(() {});
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: const Color(0xFFF9F7F5),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: Colors.black.withOpacity(0.08)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: Colors.black.withOpacity(0.08)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: Color(0xFFFF594D), width: 2),
                    ),
                    errorText: _errorMessage,
                  ),
                ),

                const SizedBox(height: 6),
                const Text(
                  'This name appears in dinner polls, squads & shared reviews.',
                  style: TextStyle(
                    fontSize: 11,
                    color: Color(0xFF756D69),
                    fontWeight: FontWeight.w500,
                  ),
                ),

                const SizedBox(height: 24),

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: OutlinedButton(
                        onPressed: _isSaving ? null : _closeDialog,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          side: BorderSide(color: Colors.black.withOpacity(0.12)),
                        ),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF555555),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 3,
                      child: ElevatedButton(
                        key: const Key('save-profile-button'),
                        onPressed: _isSaving ? null : _saveProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF594D),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: _isSaving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.2,
                                  color: Colors.white,
                                ),
                              )
                            : const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.check_rounded, size: 18),
                                  SizedBox(width: 6),
                                  Text(
                                    'Save Changes',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 15,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
