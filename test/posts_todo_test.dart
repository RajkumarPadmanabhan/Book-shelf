import 'package:flutter_test/flutter_test.dart';
import 'package:shelfwise/data/models.dart';
import 'package:shelfwise/data/posts_models.dart';

void main() {
  test('a post keeps up to three books and still reads an older single-book post', () {
    final post = Post.fromJson({
      'id': 'p1',
      'n': 'Ada',
      'h': 'ada',
      'books': [
        {'t': 'One', 'a': 'A', 'd': 'First'},
        {'t': 'Two', 'a': 'B'},
        {'t': 'Three', 'a': 'C'},
        {'t': 'Four', 'a': 'D'},
      ],
      'items': [
        {'k': 'l', 't': 'Loved these.'}
      ],
    });
    expect(post.books.map((b) => b.title), ['One', 'Two', 'Three']);
    expect(post.bookTitle, 'One');
    expect(post.books.first.desc, 'First');

    final legacy = Post.fromJson({
      'id': 'old',
      'n': 'Ada',
      'h': 'ada',
      'bt': 'Rebecca',
      'ba': 'Du Maurier',
      'items': [],
    });
    expect(legacy.books, hasLength(1));
    expect(legacy.bookTitle, 'Rebecca');
    expect(legacy.bookAuthor, 'Du Maurier');
  });

  test('an older to-do with a due time still reminds, a date with no time does not', () {
    final older = Todo.fromJson({'text': 'Read', 'due': 1700000000000});
    expect(older.timed, isTrue);
    expect(older.reminds, isTrue);

    final quiet = Todo.fromJson({'text': 'Read', 'due': 1700000000000, 'tm': false});
    expect(quiet.timed, isFalse);
    expect(quiet.reminds, isFalse);

    final someday = Todo(text: 'Someday');
    expect(someday.reminds, isFalse);
    expect(someday.toJson().containsKey('tm'), isFalse);
  });
}
