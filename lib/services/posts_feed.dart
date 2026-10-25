import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../data/posts_models.dart';
import '../data/store.dart';
import 'firebase_boot.dart';

class SharedShelf {
  final String name;
  final String emoji;
  final List<({String title, String author})> books;

  const SharedShelf({required this.name, required this.emoji, required this.books});
}

/// Shared Explore feed. A post written on any phone is stored in Firestore
/// and shown to every install that opens Explore.
class PostsFeed {
  static StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _sub;
  static final Set<String> _gone = {};
  static Timer? _libraryTimer;
  static String _libraryStamp = '';
  static bool _listening = false;

  static Future<void> start() async {
    if (_sub != null) return;
    try {
      await ensureFirebase();
      _sub = FirebaseFirestore.instance.collection('posts').orderBy('ts', descending: true).limit(200).snapshots().listen(
        (snap) {
          final remote = <Post>[];
          for (final doc in snap.docs) {
            if (_gone.contains(doc.id)) continue;
            try {
              final data = Map<String, dynamic>.from(doc.data());
              data['id'] = doc.id;
              data['mine'] = store.ownsPost(doc.id);
              _stripCovers(data);
              remote.add(Post.fromJson(data));
            } catch (e) {
              debugPrint('Skipping a post that could not be read: $e');
            }
          }
          store.applySharedPosts(remote);
        },
        onError: (Object e) => debugPrint('Explore feed unavailable: $e'),
      );
      await _publishMine();
      if (!_listening) {
        store.addListener(_scheduleLibrary);
        _listening = true;
      }
      _scheduleLibrary();
    } catch (e) {
      debugPrint('Explore feed did not start: $e');
    }
  }

  static String? get currentUid => FirebaseAuth.instance.currentUser?.uid;

  static Future<void> publish(Post post) async {
    try {
      await ensureFirebase();
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null || uid.isEmpty) {
        debugPrint('Could not share post ${post.id}: not signed in');
        return;
      }
      final data = post.toJson()
        ..['mine'] = false
        ..['uid'] = uid;
      _stripCovers(data);
      await FirebaseFirestore.instance.collection('posts').doc(post.id).set(data);
    } catch (e) {
      debugPrint('Could not share post ${post.id}: $e');
    }
  }

  /// Cover filenames only make sense on the phone that owns the file.
  static void _stripCovers(Map<String, dynamic> data) {
    data.remove('bc');
    final books = data['books'];
    if (books is! List) return;
    data['books'] = [
      for (final book in books)
        if (book is Map) (Map<String, dynamic>.from(book)..remove('c')) else book,
    ];
  }

  static Future<void> remove(String id) async {
    _gone.add(id);
    try {
      await ensureFirebase();
      await FirebaseFirestore.instance.collection('posts').doc(id).delete();
    } catch (e) {
      debugPrint('Could not remove post $id: $e');
    }
  }

  static Future<void> _publishMine() async {
    for (final post in store.posts.where((p) => p.mine)) {
      await publish(post);
    }
  }

  static void _scheduleLibrary() {
    _libraryTimer?.cancel();
    _libraryTimer = Timer(const Duration(seconds: 2), () {
      unawaited(publishLibrary());
    });
  }

  /// Shares shelf names and book titles for the signed-in account. Book files stay on the phone.
  static Future<void> publishLibrary() async {
    try {
      await ensureFirebase();
      final uid = currentUid;
      if (uid == null || uid.isEmpty) return;
      final shelves = <Map<String, dynamic>>[];
      for (final col in store.cols) {
        final books = <Map<String, String>>[];
        for (final book in col.books) {
          final title = book.title.trim();
          if (title.isEmpty) continue;
          books.add({'t': title, 'a': book.author.trim()});
        }
        shelves.add({'name': col.name, 'emoji': col.emoji, 'books': books});
      }
      final data = {
        'uid': uid,
        'n': store.profile.name,
        'h': store.profile.handle,
        'shelves': shelves,
      };
      final stamp = jsonEncode(data);
      if (stamp == _libraryStamp) return;
      await FirebaseFirestore.instance.collection('libraries').doc(uid).set(data);
      _libraryStamp = stamp;
    } catch (e) {
      debugPrint('Could not share shelves: $e');
    }
  }

  static Future<List<SharedShelf>> shelvesFor(String uid) async {
    await ensureFirebase();
    final doc = await FirebaseFirestore.instance.collection('libraries').doc(uid).get();
    final raw = doc.data()?['shelves'];
    if (raw is! List) return const [];
    final shelves = <SharedShelf>[];
    for (final entry in raw) {
      if (entry is! Map) continue;
      final map = entry.map((k, v) => MapEntry('$k', v));
      final books = <({String title, String author})>[];
      final listed = map['books'];
      if (listed is List) {
        for (final book in listed) {
          if (book is! Map) continue;
          final b = book.map((k, v) => MapEntry('$k', v));
          final title = (b['t'] ?? '').toString().trim();
          if (title.isEmpty) continue;
          books.add((title: title, author: (b['a'] ?? '').toString().trim()));
        }
      }
      final name = (map['name'] ?? '').toString().trim();
      if (name.isEmpty && books.isEmpty) continue;
      shelves.add(SharedShelf(name: name.isEmpty ? 'Shelf' : name, emoji: (map['emoji'] ?? '📚').toString(), books: books));
    }
    return shelves;
  }
}
