import 'dart:convert';
import 'dart:io';

import '../data/models.dart';

/// Books shared as a QR code: `shelfwise:1:` + base64url(zlib(JSON)).
/// Only the details travel (no covers or book files), so it fits in one code.
const _prefix = 'shelfwise:1:';

/// Past this the code gets too dense to scan reliably from a screen or photo.
const qrMaxChars = 1700;

class SharedBook {
  final String title, author, desc, isbn;
  final int rating; // the sender's stars, 0 = not rated
  const SharedBook({required this.title, this.author = '', this.desc = '', this.isbn = '', this.rating = 0});

  factory SharedBook.of(Item b) => SharedBook(title: b.title, author: b.author, desc: b.desc, isbn: b.isbn, rating: b.rating);

  Map<String, dynamic> toJson(int descMax) => {
        't': title,
        if (author.isNotEmpty) 'a': author,
        if (desc.isNotEmpty && descMax > 0) 'd': _cut(desc, descMax),
        if (isbn.isNotEmpty) 'i': isbn,
        if (rating > 0) 'r': rating,
      };

  factory SharedBook.fromJson(Map<String, dynamic> j) => SharedBook(
        title: '${j['t'] ?? ''}'.trim(),
        author: '${j['a'] ?? ''}'.trim(),
        desc: '${j['d'] ?? ''}'.trim(),
        isbn: '${j['i'] ?? ''}'.trim(),
        rating: ((j['r'] as num?)?.toInt() ?? 0).clamp(0, 5),
      );
}

class BookList {
  final String from;
  final List<SharedBook> books;
  const BookList(this.from, this.books);
}

String _cut(String s, int max) => s.length <= max ? s : '${s.substring(0, max - 1).trimRight()}…';

/// The QR text for [books] from [from], shortening descriptions until it fits.
/// Null when even titles alone are too much for one code.
String? encodeBooks(String from, List<Item> books) {
  final list = books.map(SharedBook.of).toList();
  for (final descMax in const [400, 220, 120, 60, 0]) {
    final json = jsonEncode({'f': from, 'b': [for (final b in list) b.toJson(descMax)]});
    final s = _prefix + base64Url.encode(zlib.encode(utf8.encode(json)));
    if (s.length <= qrMaxChars) return s;
  }
  return null;
}

/// Reads a scanned code; null when it isn't a Shelfwise book list.
BookList? decodeBooks(String raw) {
  final s = raw.trim();
  if (!s.startsWith(_prefix)) return null;
  try {
    final bytes = zlib.decode(base64Url.decode(base64Url.normalize(s.substring(_prefix.length))));
    final j = jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;
    final books = [
      for (final e in (j['b'] as List? ?? const []))
        if (e is Map) SharedBook.fromJson(e.cast<String, dynamic>()),
    ].where((b) => b.title.isNotEmpty).toList();
    if (books.isEmpty) return null;
    final from = '${j['f'] ?? ''}'.trim();
    return BookList(from.isEmpty ? 'a friend' : from, books);
  } catch (_) {
    return null;
  }
}
