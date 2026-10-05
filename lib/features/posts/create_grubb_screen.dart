import 'package:flutter/material.dart';
import 'package:grubbd_app/features/shell/social_bottom_bar.dart';
import 'package:grubbd_app/core/network/posts_api.dart';

class CreateGrubbScreen extends StatefulWidget {
  const CreateGrubbScreen({super.key, this.api});

  final PostsApi? api;

  @override
  State<CreateGrubbScreen> createState() => _CreateGrubbScreenState();
}

class _CreateGrubbScreenState extends State<CreateGrubbScreen> {
  late final PostsApi api = widget.api ?? PostsApi();
  final restaurantController = TextEditingController();
  final storyController = TextEditingController();
  final imageController = TextEditingController();
  final dishesController = TextEditingController();
  final vibesController = TextEditingController();
  double rating = 4;
  bool saving = false;

  @override
  void dispose() {
    restaurantController.dispose();
    storyController.dispose();
    imageController.dispose();
    dishesController.dispose();
    vibesController.dispose();
    super.dispose();
  }

  Future<void> publish() async {
    if (restaurantController.text.trim().isEmpty || storyController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add a restaurant and your story')),
      );
      return;
    }
    setState(() => saving = true);
    try {
      var imageUrl = imageController.text.trim();
      if (imageUrl.startsWith('data:image/')) {
        imageUrl = await api.uploadImageDataUrl(imageUrl);
      }
      await api.create(
        restaurantName: restaurantController.text.trim(),
        story: storyController.text.trim(),
        imageUrl: imageUrl.isEmpty ? null : imageUrl,
        rating: rating,
        dishes: _split(dishesController.text),
        vibes: _split(vibesController.text),
      );
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.toString().replaceFirst('Exception: ', ''))),
        );
      }
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  List<String> _split(String value) => value
      .split(',')
      .map((item) => item.trim())
      .where((item) => item.isNotEmpty)
      .toList();

  InputDecoration _decoration(String label, {String? hint}) {
    return InputDecoration(labelText: label, hintText: hint);
  }

  Widget _space() => const SizedBox(height: 14);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: const SocialBottomBar(),
      appBar: AppBar(title: const Text('Create a Grubb')),
      body: ListView(padding: const EdgeInsets.all(20), children: _formFields()),
    );
  }

  List<Widget> _formFields() {
    return [
      TextField(controller: restaurantController, decoration: _decoration('Restaurant', hint: 'Where did you eat?')),
      _space(),
      TextField(controller: imageController, decoration: _decoration('Photo URL (optional)')),
      _space(),
      TextField(controller: storyController, maxLines: 4, decoration: _decoration('Your story', hint: 'Tell people what you thought')),
      _space(),
      Text('Rating ${rating.toStringAsFixed(1)} / 5'),
      Slider(value: rating, min: 0, max: 5, divisions: 10, onChanged: (value) => setState(() => rating = value)),
      TextField(controller: dishesController, decoration: _decoration('Dishes', hint: 'Separate dishes with commas')),
      _space(),
      TextField(controller: vibesController, decoration: _decoration('Vibes', hint: 'Separate vibes with commas')),
      const SizedBox(height: 24),
      SizedBox(height: 52, child: FilledButton(onPressed: saving ? null : publish, child: saving ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator()) : const Text('Post Grubb'))),
    ];
  }
}
