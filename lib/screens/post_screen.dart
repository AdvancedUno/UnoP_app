import 'package:flutter/material.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:unop/utils/colors.dart';
import 'package:unop/widgets/post_card.dart';

class PostsScreen extends StatefulWidget {
  final posts;
  final int desiredIndex;
  const PostsScreen(
      {super.key, required this.posts, required this.desiredIndex});
  @override
  _PostsScreenState createState() => _PostsScreenState();
}

class _PostsScreenState extends State<PostsScreen> {
  final ItemScrollController _itemScrollController = ItemScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.posts.isNotEmpty &&
          widget.desiredIndex < widget.posts.length) {
        _itemScrollController.jumpTo(index: widget.desiredIndex);
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Posts"),
        backgroundColor: appbarColor,
      ),
      body: ScrollablePositionedList.builder(
        itemCount: widget.posts.length,
        itemBuilder: (context, index) =>
            PostCard(isFeed: false, snap: widget.posts[index]),
        itemScrollController: _itemScrollController,
      ),
    );
  }
}
