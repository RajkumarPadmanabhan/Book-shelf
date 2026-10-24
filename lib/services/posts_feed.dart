import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../data/posts_models.dart';
import '../data/store.dart';
import 'firebase_boot.dart';

/// Shared Explore feed. A post written on any phone is stored in Firestore
/// and shown to every install that opens Explore.
class PostsFeed {
  static StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _sub;
  static final Set<String> _gone = {};

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
              data.remove('bc');
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
    } catch (e) {
      debugPrint('Explore feed did not start: $e');
    }
  }

  static Future<void> publish(Post post) async {
    try {
      await ensureFirebase();
      final data = post.toJson()
        ..['mine'] = false
        ..remove('bc');
      await FirebaseFirestore.instance.collection('posts').doc(post.id).set(data);
    } catch (e) {
      debugPrint('Could not share post ${post.id}: $e');
    }
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
}
