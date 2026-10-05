import 'package:flutter/material.dart';
import 'package:grubbd_app/features/shell/social_bottom_bar.dart';
import 'package:grubbd_app/core/network/posts_api.dart';

class PostDetailScreen extends StatefulWidget {
  const PostDetailScreen({super.key, required this.post, this.api});
  final FoodPost post;
  final PostsApi? api;
  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  late final PostsApi api = widget.api ?? PostsApi();
  late Future<List<Map<String, dynamic>>> comments = api.comments(widget.post.id);
  final commentController = TextEditingController();
  @override
  void dispose() {
    commentController.dispose();
    super.dispose();
  }
  Future<void> addComment() async {
    final text = commentController.text.trim();
    if (text.isEmpty) return;
    await api.addComment(widget.post.id, text);
    commentController.clear();
    if (mounted) setState(() {
      comments = api.comments(widget.post.id);
    });
  }
  @override
  Widget build(BuildContext context) {
    final post = widget.post;
    return Scaffold(
      bottomNavigationBar: const SocialBottomBar(),
      appBar: AppBar(title: Text(post.restaurantName)),
      body: ListView(padding: const EdgeInsets.all(16), children: _content(post)),
    );
  }

  List<Widget> _content(FoodPost post) {
    return [
      if (post.imageUrl != null && post.imageUrl!.isNotEmpty)
        ClipRRect(borderRadius: BorderRadius.circular(16), child: Image.network(post.imageUrl!, height: 240, fit: BoxFit.cover)),
      const SizedBox(height: 16),
      Text(post.authorName, style: const TextStyle(fontWeight: FontWeight.w700)),
      const SizedBox(height: 8),
      Text(post.story, style: const TextStyle(fontSize: 17, height: 1.4)),
      _chips('What I had', post.dishes),
      _chips('Vibe', post.vibes),
      Row(children: [IconButton(onPressed: () => api.toggleLike(post.id), icon: const Icon(Icons.favorite_border)), Text('${post.likeCount} likes')]),
      const Divider(height: 32),
      const Text('Comments', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
      _comments(),
      TextField(controller: commentController, onSubmitted: (_) => addComment(), decoration: InputDecoration(hintText: 'Add a comment', suffixIcon: IconButton(onPressed: addComment, icon: const Icon(Icons.send)))),
    ];
  }

  Widget _chips(String title, List<String> values) {
    if (values.isEmpty) return const SizedBox.shrink();
    return Padding(padding: const EdgeInsets.only(top: 18), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontWeight: FontWeight.w800)), Wrap(spacing: 8, children: values.map((value) => Chip(label: Text(value))).toList())]));
  }

  Widget _comments() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: comments,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const LinearProgressIndicator();
        if (snapshot.hasError) return const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Text('Could not load comments'));
        return Column(children: snapshot.data!.map((item) => ListTile(title: Text(item['author']?.toString() ?? 'User'), subtitle: Text(item['text']?.toString() ?? ''))).toList());
      },
    );
  }
}
