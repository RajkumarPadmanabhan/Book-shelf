import 'package:flutter_test/flutter_test.dart';
import 'package:shelfwise/data/models.dart';
import 'package:shelfwise/services/book_qr.dart';

void main() {
  test('book list round-trips through the QR text', () {
    final books = [
      Item(title: 'Piranesi', author: 'Susanna Clarke', desc: 'A house of endless halls.', isbn: '9781635575637', rating: 5),
      Item(title: 'Hamnet', author: 'Maggie O’Farrell'),
    ];
    final qr = encodeBooks('Raj', books)!;
    expect(qr, startsWith('shelfwise:1:'));
    final list = decodeBooks(qr)!;
    expect(list.from, 'Raj');
    expect(list.books.map((b) => b.title), ['Piranesi', 'Hamnet']);
    expect(list.books.first.author, 'Susanna Clarke');
    expect(list.books.first.isbn, '9781635575637');
    expect(list.books.first.rating, 5);
    expect(list.books.first.desc, 'A house of endless halls.');
  });

  test('long descriptions are shortened to fit one code', () {
    final long = List.filled(60, 'A very long description of a cosy book.').join(' ');
    final books = [for (var i = 0; i < 12; i++) Item(title: 'Book $i', author: 'Author $i', desc: '$long $i')];
    final qr = encodeBooks('Raj', books)!;
    expect(qr.length, lessThanOrEqualTo(qrMaxChars));
    expect(decodeBooks(qr)!.books, hasLength(12));
  });

  test('other QR codes are ignored', () {
    expect(decodeBooks('https://example.com'), isNull);
    expect(decodeBooks('shelfwise:1:not-base64!'), isNull);
  });
}
