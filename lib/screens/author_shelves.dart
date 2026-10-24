import 'package:flutter/material.dart';

import '../services/posts_feed.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/dialogs.dart';

/// Opens the shelves that [uid] has shared. Book files stay on their phone.
Future<void> openAuthorShelves({required String uid, required String name}) {
  final who = name.trim().isEmpty ? 'This reader' : name.trim();
  if (uid.isEmpty) {
    toast('No shelves to show for this reader yet.');
    return Future.value();
  }
  return openDialog((_) => _AuthorShelvesDialog(uid: uid, name: who));
}

class _AuthorShelvesDialog extends StatefulWidget {
  final String uid;
  final String name;

  const _AuthorShelvesDialog({required this.uid, required this.name});

  @override
  State<_AuthorShelvesDialog> createState() => _AuthorShelvesDialogState();
}

class _AuthorShelvesDialogState extends State<_AuthorShelvesDialog> {
  late final Future<List<SharedShelf>> _shelves = PostsFeed.shelvesFor(widget.uid);

  @override
  Widget build(BuildContext context) {
    return AppDialog(
      title: '${widget.name}’s shelves',
      maxWidth: 400,
      actions: const [Btn('Close')],
      children: [
        FutureBuilder<List<SharedShelf>>(
          future: _shelves,
          builder: (context, snap) {
            if (snap.connectionState != ConnectionState.done) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 18),
                child: Text('Looking up shelves…', style: nu(14, FontWeight.w700, C.muted)),
              );
            }
            if (snap.hasError) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text('Could not open these shelves just now.', style: nu(14, FontWeight.w700, C.muted, 1.35)),
              );
            }
            final shelves = snap.data ?? const <SharedShelf>[];
            if (shelves.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text('No shelves yet.', style: nu(14, FontWeight.w700, C.muted, 1.35)),
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final shelf in shelves) ...[
                  const SizedBox(height: 12),
                  Text('${shelf.emoji} ${shelf.name}', style: nu(15, FontWeight.w800, C.ink)),
                  if (shelf.books.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text('No books on this shelf.', style: nu(13, FontWeight.w600, C.muted)),
                    )
                  else
                    for (final book in shelf.books)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          book.author.isEmpty ? book.title : '${book.title} · ${book.author}',
                          style: nu(13.5, FontWeight.w600, C.ink, 1.3),
                        ),
                      ),
                ],
              ],
            );
          },
        ),
      ],
    );
  }
}
