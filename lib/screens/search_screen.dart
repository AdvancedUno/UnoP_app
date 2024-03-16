import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:unop/screens/group_profile_screen.dart';
import 'package:unop/screens/post_screen.dart';
import 'package:unop/screens/profile_screen.dart';
import 'package:unop/utils/colors.dart';
import 'package:shared_preferences/shared_preferences.dart';


class SearchHistoryManager {
  static const String _historyKey = 'search_history';

  static Future<List<String>> getSearchHistory() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_historyKey) ?? [];
  }

  static Future<void> saveSearchQuery(String query) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> history = prefs.getStringList(_historyKey) ?? [];
    history.insert(0, query);
    history = history.toSet().toList();
    await prefs.setStringList(_historyKey, history);
  }

  static Future<void> clearSearchHistory() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove(_historyKey);
  }

  static Future<void> deleteSearchHistory(String query) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> history = prefs.getStringList(_historyKey) ?? [];
    history.remove(query);
    history = history.toSet().toList();
    await prefs.setStringList(_historyKey, history);
  }
}


class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}


class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _textFormFieldFocusNode = FocusNode();
  bool isSearching = false;

  @override
  void initState() {
    super.initState();
    _textFormFieldFocusNode.addListener(() {
      setState(() {
        isSearching = _textFormFieldFocusNode.hasFocus;
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _textFormFieldFocusNode.dispose();
    super.dispose();
  }

  // Searching group name using stream query.
  Stream<QuerySnapshot<Map<String, dynamic>>> streamUserData(String userInput) {
    userInput = userInput.trim().toLowerCase(); 
    if (userInput.isEmpty) {
      return const Stream.empty();
    } else {
      return FirebaseFirestore.instance
          .collection('group')
          .where('groupNameLowerCase', isGreaterThanOrEqualTo: userInput)
          .where('groupNameLowerCase', isLessThan: '$userInput\uf8ff')
          .snapshots();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          backgroundColor: appbarColor,
          title: Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _searchController,
                  focusNode: _textFormFieldFocusNode,
                  decoration: InputDecoration(
                      hintText: 'Search',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: isSearching
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                setState(() {
                                  isSearching = true;
                                });
                              },
                            )
                          : null),
                  onChanged:(_) {
                    setState(() {
                      isSearching = true;
                    });
                  },
                  onFieldSubmitted: (String _) {
                    _handleSubmission();
                  },
                ),
              ),
              if (isSearching)
                TextButton(
                  onPressed: () {
                    _searchController.clear();
                    _textFormFieldFocusNode.unfocus();
                  },
                  child: const Text('Cancel'),
                ),
            ],
          )
        ),
      body: (isSearching)
          ? (_searchController.text.trim().isEmpty)
            ? _buildSearchHistory()
            : _buildSearchFilter()
          : _buildDefaultContent(),
    );
  }  

  void _handleSubmission() {
    if (_searchController.text.isNotEmpty) {
      SearchHistoryManager.saveSearchQuery(_searchController.text);
    }
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => SearchResultScreen(
          searchQuery: _searchController.text, focusNode: _textFormFieldFocusNode),
      ),
    );
    print('here');
  }

  Widget _buildSearchHistory() {
    return FutureBuilder<List<String>>(
      future: SearchHistoryManager.getSearchHistory(),
          builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Text('Error: ${snapshot.error}');
          } else {  
            List<String> history = snapshot.data ?? [];
            if (history.isNotEmpty) {           
              return ListView(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(left: 15.0),
                        child: Text(
                          'Recent:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          SearchHistoryManager.clearSearchHistory();
                          setState(() {
                            isSearching = true;
                          });
                        },
                        child: const Text('Clear All'),
                      ),
                    ],
                  ),
                  Column(
                    children: history.map((query) => ListTile(
                      leading: const Icon(Icons.search),
                      trailing: IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          SearchHistoryManager.deleteSearchHistory(query);
                          setState(() {
                            isSearching = true;
                          });
                        },
                      ),
                      title: Text(query),
                      onTap: () {
                        _searchController.text = query;
                        _handleSubmission();
                      },
                    )).toList(),
                  ),
                ],
              );
            } else {
              return Container();
            }
          }
        },
      );
  }
  
  Widget _buildSearchFilter() {
    return StreamBuilder(
      stream: streamUserData(_searchController.text),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        } else {
          var userData = (snapshot.data! as dynamic).docs;
          if (userData.isNotEmpty) {
            return ListView.builder(
                itemCount: userData.length,
                itemBuilder: (context, index) {
                  var doc = userData[index];
                  var groupid = doc.data().containsKey('groupid')
                      ? doc['groupid']
                      : 'DefaultGroupID';
                  var photoUrl = doc.data().containsKey('photoUrl')
                      ? doc['photoUrl']
                      : 'defaultImageUrl';
                  var groupName = doc.data().containsKey('groupName')
                      ? doc['groupName']
                      : 'Unknown Group';
                  return InkWell(
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => GroupProfileScreen(
                          groupid: groupid,
                        ),
                      ),
                    ),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundImage: photoUrl != null
                            ? CachedNetworkImageProvider(photoUrl)
                            : null,
                        onBackgroundImageError:
                            (exception, stackTrace) {
                          print("Error loading image: $exception");
                        },
                        radius: 16,
                        child: photoUrl == null
                            ? const CircularProgressIndicator()
                            : null,
                      ),
                      title: Text(groupName),
                    ),
                  );
                });
          } else {
            return Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                Center(
                  child: Text('No results found for "${_searchController.text}"'),
                ),
              ],
            );
          }
        }
      }
    );
  }

  Widget _buildDefaultContent() {
    return FutureBuilder(
        future: FirebaseFirestore.instance
            .collection('posts')
            .orderBy('datePublished')
            .get(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No posts available.'));
          }
          return MasonryGridView.count(
            crossAxisCount: 2,
            itemCount: (snapshot.data! as dynamic).docs.length,
            itemBuilder: (context, index) {
              var doc = (snapshot.data! as dynamic).docs[index];
              var postId = doc.data().containsKey('postId') &&
                      doc['postId'].isNotEmpty
                  ? doc['postId']
                  : 'defaultID';
              var postUrl = doc.data().containsKey('postUrl') &&
                      doc['postUrl'].isNotEmpty
                  ? doc['postUrl'][0]
                  : 'defaultImageUrl';
              var groupid = doc.data().containsKey('groupId')
                      ? doc['groupId']
                      : 'DefaultUID';
              return GestureDetector(
                onTap: () async {
                  QuerySnapshot postsSnapshot = await FirebaseFirestore.instance
                    .collection('posts')
                    .where('groupId', arrayContains: groupid[0].toString())
                    .get();
                  List<Map<String, dynamic>> posts = postsSnapshot.docs
                    .map((doc) => doc.data() as Map<String, dynamic>)
                    .toList();
                  int index = posts.indexWhere((post) => post["postId"] == postId);                    
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => PostsScreen(  
                        posts: posts,                
                        desiredIndex: index
                      ),
                    ),
                  );
                },
                child: Image(
                  image: CachedNetworkImageProvider(postUrl),
                  fit: BoxFit
                      .cover, 
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(Icons.error);
                  },
                )
              );
            },
          );
        },
      );
    }
}


class SearchResultScreen extends StatefulWidget {
  final String searchQuery; 
  FocusNode focusNode = FocusNode();

  SearchResultScreen({super.key, required this.searchQuery, required this.focusNode});  

  @override
  State<SearchResultScreen> createState() => _SearchResultScreenState();
}


class _SearchResultScreenState extends State<SearchResultScreen> {

  Future<QuerySnapshot<Map<String, dynamic>>> getFilteredGroupNames(String userInput) {
    userInput = userInput.trim().toLowerCase(); 
    return FirebaseFirestore.instance
        .collection('group')
        .where('groupNameLowerCase', isGreaterThanOrEqualTo: userInput)
        .where('groupNameLowerCase', isLessThan: '$userInput}\uf8ff')
        .get();
  }

  Future<QuerySnapshot<Map<String, dynamic>>> getFilteredUserNames(String userInput) {
    userInput = userInput.trim().toLowerCase(); 
    return FirebaseFirestore.instance
        .collection('users')
        .where('usernameLowerCase', isGreaterThanOrEqualTo: userInput)
        .where('usernameLowerCase', isLessThan: '$userInput}\uf8ff')
        .get();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: appbarColor,
          title: TextFormField(
            initialValue: widget.searchQuery,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
            ),
            onTap: () {
              Navigator.pop(context);
              widget.focusNode.requestFocus();
            },
          ),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Groups'),
              Tab(text: 'Accounts'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            buildSearchResults(context, 'Groups'),
            buildSearchResults(context, 'Accounts'),
          ],
        ),
      ),
    );
  }

  Widget buildSearchResults(BuildContext context, String tabName) {
    if (tabName == 'Groups') {
      return FutureBuilder(
        future: getFilteredGroupNames(widget.searchQuery),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Text('Error: ${snapshot.error}');
          } else {
            var userData = (snapshot.data! as dynamic).docs;
            if (userData.isNotEmpty) {
              return ListView.builder(
                itemCount: userData.length,
                itemBuilder: (context, index) {
                  var doc = userData[index];
                  var groupid = doc.data().containsKey('groupid')
                      ? doc['groupid']
                      : 'DefaultGroupID';
                  var photoUrl = doc.data().containsKey('photoUrl')
                      ? doc['photoUrl']
                      : 'defaultImageUrl';
                  var groupName = doc.data().containsKey('groupName')
                      ? doc['groupName']
                      : 'Unknown Group';
                  return InkWell(
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => GroupProfileScreen(
                          groupid: groupid,
                        ),
                      ),
                    ),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundImage: photoUrl != null
                            ? CachedNetworkImageProvider(photoUrl)
                            : null,
                        onBackgroundImageError:
                            (exception, stackTrace) {
                          print("Error loading image: $exception");
                        },
                        radius: 16,
                        child: photoUrl == null
                            ? const CircularProgressIndicator()
                            : null,
                      ),
                      title: Text(groupName),
                    ),
                  );
                }
              );
            } else {
              return Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  Center(
                    child: Text('No results found for "${widget.searchQuery}"'),
                  ),
                ],
              );
            }
          }
        }
      );
    } else {
      return FutureBuilder(
        future: getFilteredUserNames(widget.searchQuery),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Text('Error: ${snapshot.error}');
          } else {
            var userData = (snapshot.data! as dynamic).docs;
            if (userData.isNotEmpty) {
              return ListView.builder(
                itemCount: userData.length,
                itemBuilder: (context, index) {
                  var doc = userData[index];
                  var uid = doc.data().containsKey('uid')
                        ? doc['uid']
                        : 'DefaultUID';
                    var photoUrl = doc.data().containsKey('photoUrl')
                        ? doc['photoUrl']
                        : 'defaultImageUrl';
                    var username = doc.data().containsKey('username')
                        ? doc['username']
                        : 'Unknown User';
                  return InkWell(
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => ProfileScreen(
                          uid: uid,
                        ),
                      ),
                    ),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundImage: photoUrl != null
                            ? CachedNetworkImageProvider(photoUrl)
                            : null,
                        onBackgroundImageError: (exception, stackTrace) {
                          print("Error loading image: $exception");
                        },
                        radius: 16,
                        child: photoUrl == null
                            ? const CircularProgressIndicator()
                            : null,
                      ),
                      title: Text(username),
                    ),
                  );
                },
              );
            } else {
              return Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  Center(
                    child: Text('No results found for "${widget.searchQuery}"'),
                  ),
                ],
              );
            }
          }
        },
      );
    }
  }
}