import 'package:flutter/material.dart';
import 'package:grubbd_app/core/widgets/app_back_button.dart';
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
  double rating = 4.0;
  bool saving = false;

  final samplePhotos = const [
    ('🍕 Pizza', 'https://images.unsplash.com/photo-1513104890138-7c749659a591?auto=format&fit=crop&w=600&q=80'),
    ('🍜 Ramen', 'https://images.unsplash.com/photo-1569718212165-3a8278d5f624?auto=format&fit=crop&w=600&q=80'),
    ('🍔 Burger', 'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?auto=format&fit=crop&w=600&q=80'),
    ('🌮 Tacos', 'https://images.unsplash.com/photo-1565299585323-38d6b0865b47?auto=format&fit=crop&w=600&q=80'),
    ('🍰 Cake', 'https://images.unsplash.com/photo-1578985545062-69928b1d9587?auto=format&fit=crop&w=600&q=80'),
  ];

  final popularDishes = const [
    'Truffle Fries',
    'Margherita Pizza',
    'Tonkotsu Ramen',
    'Spicy Crispy Chicken',
    'Matcha Latte',
    'Tacos al Pastor',
  ];

  final presetVibes = const [
    '✨ Cozy & Chill',
    '🌿 Aesthetic Decor',
    '🌙 Late Night Cravings',
    '🎶 Lively & Upbeat',
    '💻 Laptop Friendly',
    '🕯️ Romantic Date',
    '🎉 Group Celebration',
  ];

  @override
  void dispose() {
    restaurantController.dispose();
    storyController.dispose();
    imageController.dispose();
    dishesController.dispose();
    vibesController.dispose();
    super.dispose();
  }

  void addDish(String dish) {
    final current = _split(dishesController.text);
    if (!current.contains(dish)) {
      current.add(dish);
      setState(() {
        dishesController.text = current.join(', ');
      });
    }
  }

  void toggleVibe(String vibe) {
    final current = _split(vibesController.text);
    if (current.contains(vibe)) {
      current.remove(vibe);
    } else {
      current.add(vibe);
    }
    setState(() {
      vibesController.text = current.join(', ');
    });
  }

  Future<void> publish() async {
    if (restaurantController.text.trim().isEmpty || storyController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Color(0xFF1E1A1A),
          content: Text('Please add both a restaurant name and your review story!'),
        ),
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Color(0xFF2E7D32),
            content: Text('Your Grubb has been shared with foodies! 🎉'),
          ),
        );
        Navigator.pop(context, true);
      }
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

  String _getRatingComment(double val) {
    if (val >= 4.8) return '5.0 · Mind-blowing bite! Must try! 🔥';
    if (val >= 4.0) return '${val.toStringAsFixed(1)} · Super delicious & satisfying! 😋';
    if (val >= 3.0) return '${val.toStringAsFixed(1)} · Pretty good overall 🙂';
    if (val >= 2.0) return '${val.toStringAsFixed(1)} · Average / nothing special 😐';
    return '${val.toStringAsFixed(1)} · Not great, would skip 😕';
  }

  @override
  Widget build(BuildContext context) {
    final selectedVibes = _split(vibesController.text);
    final previewUrl = imageController.text.trim();

    return Scaffold(
      bottomNavigationBar: const SocialBottomBar(),
      appBar: AppBar(
        leading: const AppBackButton(),
        title: const Text('Post a Grubb 📸'),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        children: [
          // Beginner intro card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF0EC),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFFF594D).withOpacity(0.2)),
            ),
            child: Row(
              children: const [
                Text('🍽️', style: TextStyle(fontSize: 28)),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'What made this meal memorable? Share photos, top dishes, and vibes to help others eat well!',
                    style: TextStyle(fontSize: 13, color: Color(0xFF5F3928), height: 1.35),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 22),

          // 1. Where did you eat?
          const Text(
            '1. Restaurant Name *',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF1E1A1A)),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: restaurantController,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.location_on_rounded, color: Color(0xFFFF594D)),
              hintText: 'e.g. Bella Italia, Tokyo Ramen Bar, Jo\'s Bakery',
            ),
          ),

          const SizedBox(height: 20),

          // 2. Add a Photo
          const Text(
            '2. Add a Photo (Optional)',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF1E1A1A)),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: imageController,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.image_outlined, color: Color(0xFFFF594D)),
              hintText: 'Paste image link or pick a food sample below',
              suffixIcon: imageController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () => setState(() => imageController.clear()),
                    )
                  : null,
            ),
          ),
          const SizedBox(height: 10),

          // Quick sample photo selectors
          Wrap(
            spacing: 8,
            children: samplePhotos.map((sample) {
              return ActionChip(
                label: Text(sample.$1, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: BorderSide(color: Colors.black.withOpacity(0.08)),
                ),
                onPressed: () {
                  setState(() {
                    imageController.text = sample.$2;
                  });
                },
              );
            }).toList(),
          ),

          if (previewUrl.isNotEmpty) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.network(
                previewUrl,
                height: 180,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Container(
                  height: 90,
                  color: Colors.grey.shade200,
                  alignment: Alignment.center,
                  child: const Text('Could not load image from link', style: TextStyle(color: Colors.grey)),
                ),
              ),
            ),
          ],

          const SizedBox(height: 22),

          // 3. Rating with Stars
          const Text(
            '3. How was the food? ⭐',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF1E1A1A)),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.black.withOpacity(0.06)),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    final starVal = index + 1.0;
                    return IconButton(
                      iconSize: 36,
                      onPressed: () => setState(() => rating = starVal),
                      icon: Icon(
                        rating >= starVal
                            ? Icons.star_rounded
                            : (rating >= starVal - 0.5 ? Icons.star_half_rounded : Icons.star_outline_rounded),
                        color: const Color(0xFFFFB300),
                      ),
                    );
                  }),
                ),
                Text(
                  _getRatingComment(rating),
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Color(0xFF8D6E63)),
                ),
              ],
            ),
          ),

          const SizedBox(height: 22),

          // 4. Your Story / Review
          const Text(
            '4. Your Review Story *',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF1E1A1A)),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: storyController,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: 'Describe the flavor, portion size, stand-out dish, or what you loved most!',
            ),
          ),

          const SizedBox(height: 22),

          // 5. Dishes Ordered
          const Text(
            '5. What did you order? 🍽️',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF1E1A1A)),
          ),
          const SizedBox(height: 4),
          const Text(
            'Tap popular dishes below or type them separated by commas',
            style: TextStyle(fontSize: 12, color: Color(0xFF756D69)),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: dishesController,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.restaurant_menu_rounded, color: Color(0xFFFF594D)),
              hintText: 'e.g. Garlic Naan, Truffle Pasta',
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: popularDishes.map((dish) {
              return ActionChip(
                label: Text('+ $dish', style: const TextStyle(fontSize: 12)),
                backgroundColor: const Color(0xFFFFF8EE),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                onPressed: () => addDish(dish),
              );
            }).toList(),
          ),

          const SizedBox(height: 22),

          // 6. Vibe Check
          const Text(
            '6. Vibe Check ✨',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF1E1A1A)),
          ),
          const SizedBox(height: 4),
          const Text(
            'Select all that describe the atmosphere',
            style: TextStyle(fontSize: 12, color: Color(0xFF756D69)),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: presetVibes.map((vibe) {
              final isSelected = selectedVibes.contains(vibe);
              return FilterChip(
                label: Text(vibe),
                selected: isSelected,
                selectedColor: const Color(0xFFFFE0D9),
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: isSelected ? const Color(0xFFFF594D) : Colors.black.withOpacity(0.08),
                  ),
                ),
                labelStyle: TextStyle(
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                  color: isSelected ? const Color(0xFFFF594D) : const Color(0xFF2C2523),
                  fontSize: 12.5,
                ),
                onSelected: (_) => toggleVibe(vibe),
              );
            }).toList(),
          ),

          const SizedBox(height: 32),

          // Submit Button
          SizedBox(
            width: double.infinity,
            height: 54,
            child: FilledButton.icon(
              onPressed: saving ? null : publish,
              icon: saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Icon(Icons.send_rounded),
              label: Text(
                saving ? 'Publishing...' : 'Publish Your Grubb 🚀',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFFF594D),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
