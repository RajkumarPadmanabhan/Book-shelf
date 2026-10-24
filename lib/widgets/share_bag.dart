import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../data/models.dart';
import '../data/store.dart';
import '../services/book_qr.dart';
import '../services/sfx.dart';
import '../services/share_image.dart';
import '../theme.dart';
import 'book_cover.dart';
import 'common.dart';
import 'dialogs.dart';

/// Home's share bag. Long-press a book on a Home shelf and drop it on the bag
/// to add a copy (the book stays on its shelf); tap the bag to see what's in
/// it and share everything as one QR code.
class ShareBagUi {
  static final dragging = ValueNotifier(false); // a book is being dragged on Home
  static final hover = ValueNotifier(false); // ...and the finger is over the bag
  static final _key = GlobalKey();

  /// Whether the finger at [global] is over the bag.
  static bool hits(Offset global) {
    final box = _key.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.attached) return false;
    return (box.localToGlobal(Offset.zero) & box.size).inflate(22).contains(global);
  }
}

/// The bag at the bottom of Home: shown while a book is dragged, or while it
/// holds books. It waits on the right and slides to the middle during a drag.
class ShareBagButton extends StatelessWidget {
  const ShareBagButton({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([store, ShareBagUi.dragging, ShareBagUi.hover]),
      builder: (context, _) {
        final n = store.bagBooks.length;
        final drag = ShareBagUi.dragging.value, over = drag && ShareBagUi.hover.value;
        final show = drag || n > 0;
        return AnimatedAlign(
          alignment: drag ? Alignment.bottomCenter : Alignment.bottomRight,
          duration: const Duration(milliseconds: 260),
          curve: ease,
          child: IgnorePointer(
            ignoring: !show || drag,
            child: AnimatedOpacity(
              opacity: show ? 1 : 0,
              duration: const Duration(milliseconds: 200),
              child: AnimatedScale(
                scale: !show ? .6 : (over ? 1.2 : 1),
                duration: const Duration(milliseconds: 220),
                curve: popCurve,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 180),
                      child: drag
                          ? Container(
                              key: ValueKey(over),
                              margin: const EdgeInsets.only(bottom: 6),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: over ? C.brown : const Color(0xF22B1D10),
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: const [BoxShadow(color: Color.fromRGBO(0, 0, 0, .3), blurRadius: 10, offset: Offset(0, 3))],
                              ),
                              child: Text(over ? 'Let go to add a copy' : 'Drop here to share', style: nu(12.5, FontWeight.w800, Colors.white)),
                            )
                          : const SizedBox.shrink(),
                    ),
                    Semantics(
                      button: true,
                      label: 'Share bag, ${plural(n, 'book')}',
                      child: Pressable(
                        onTap: openShareBag,
                        scale: .9,
                        child: SizedBox(
                          key: ShareBagUi._key,
                          width: 70,
                          height: 76,
                          child: CustomPaint(
                            painter: _BagPainter(count: n, open: over, glow: drag),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// A kraft-paper shopping bag with the number of books on its front.
class _BagPainter extends CustomPainter {
  final int count;
  final bool open, glow;
  _BagPainter({required this.count, required this.open, required this.glow});

  @override
  void paint(Canvas c, Size s) {
    final w = s.width, h = s.height;
    if (glow) {
      c.drawOval(
        Rect.fromCenter(center: Offset(w / 2, h * .66), width: w * 1.3, height: h * .9),
        Paint()
          ..color = (open ? C.orange : C.brown).withValues(alpha: open ? .45 : .25)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14),
      );
    }
    Paint handle(Color col) => Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..color = col;
    final lift = open ? h * .02 : h * .1;
    // back handle
    c.drawPath(
      Path()
        ..moveTo(w * .38, h * .34)
        ..cubicTo(w * .38, lift, w * .66, lift, w * .66, h * .34),
      handle(const Color(0xFF6B3F1B)),
    );
    final body = Path()
      ..moveTo(w * .14, h * .32)
      ..lineTo(w * .86, h * .32)
      ..lineTo(w * .95, h * .93)
      ..quadraticBezierTo(w * .96, h, w * .89, h)
      ..lineTo(w * .11, h)
      ..quadraticBezierTo(w * .04, h, w * .05, h * .93)
      ..close();
    c.drawShadow(body, Colors.black, 5, false);
    c.drawPath(
      body,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFDDA766), Color(0xFFB9783C)],
        ).createShader(Offset.zero & s),
    );
    // folded top band
    c.save();
    c.clipPath(body);
    c.drawRect(Rect.fromLTRB(0, h * .32, w, h * .42), Paint()..color = const Color(0x22000000));
    c.restore();
    if (open) {
      c.drawOval(Rect.fromLTRB(w * .16, h * .28, w * .84, h * .37), Paint()..color = const Color(0xFF4A2A10));
    }
    // front handle
    c.drawPath(
      Path()
        ..moveTo(w * .32, h * .36)
        ..cubicTo(w * .32, lift + h * .04, w * .6, lift + h * .04, w * .6, h * .36),
      handle(const Color(0xFF8A5528)),
    );
    final tp = TextPainter(
      text: TextSpan(
        text: count > 0 ? '$count' : '+',
        style: nu(count > 9 ? 20 : 24, FontWeight.w900, Colors.white).copyWith(
          shadows: const [Shadow(color: Color(0x66000000), offset: Offset(0, 1.5), blurRadius: 2)],
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(c, Offset((w - tp.width) / 2, h * .68 - tp.height / 2));
  }

  @override
  bool shouldRepaint(_BagPainter o) => o.count != count || o.open != open || o.glow != glow;
}

String get _sender => store.profile.name.trim().isEmpty ? store.profile.first : store.profile.name.trim();

/// The bag's contents, with a way to take books out and share them as a QR.
void openShareBag() {
  Buzz.tick();
  openDialog(
    (ctx) => ListenableBuilder(
      listenable: store,
      builder: (ctx, _) {
        final books = store.bagBooks;
        return AppDialog(
          title: '🛍️ Share bag',
          maxWidth: 380,
          children: [
            Text(
              books.isEmpty
                  ? 'Your bag is empty. On Home, press and hold a book, then drop it on the bag. The book stays on your shelf; the bag only carries a copy of its details.'
                  : '${plural(books.length, 'book')} ready to share. Tap Share as QR to turn them into one picture you can send or save.',
              style: nu(13.5, FontWeight.w600, C.muted, 1.4),
            ),
            const SizedBox(height: 12),
            for (final b in books) _bagRow(b),
          ],
          actions: [
            if (books.isNotEmpty)
              Btn(
                'Empty',
                kind: Kind.dng,
                onTap: () {
                  store.clearBag();
                  toast('Share bag emptied');
                  return true;
                },
              ),
            const Btn('Close'),
            if (books.isNotEmpty) Btn('Share as QR', kind: Kind.pri, then: () => openBagQr(books)),
          ],
        );
      },
    ),
  );
}

Widget _bagRow(Item b) => Padding(
  padding: const EdgeInsets.only(bottom: 8),
  child: Container(
    padding: const EdgeInsets.fromLTRB(8, 8, 6, 8),
    decoration: BoxDecoration(
      color: C.chip,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: C.line),
    ),
    child: Row(
      children: [
        BookCover(b, w: 34, h: 48, titleSize: 5.5, authorSize: 4, radius: 3),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(b.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: nu(14, FontWeight.w800, C.ink)),
              if (b.author.isNotEmpty) Text(b.author, maxLines: 1, overflow: TextOverflow.ellipsis, style: nu(12, FontWeight.w700, C.muted)),
            ],
          ),
        ),
        Semantics(
          button: true,
          label: 'Take ${b.title} out of the bag',
          child: Pressable(
            onTap: () {
              Buzz.tick();
              store.removeFromBag(b);
            },
            scale: .85,
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Icon(Icons.close_rounded, size: 20, color: C.muted),
            ),
          ),
        ),
      ],
    ),
  ),
);

/// Shows [books] as one QR code, with Share (any app) and Save (Photos).
void openBagQr(List<Item> books) {
  final from = _sender;
  final data = encodeBooks(from, books);
  if (data == null) {
    toast('Too many books for one QR code. Take a few out of the bag and try again.');
    return;
  }
  final key = GlobalKey();
  Sfx.play('pop');
  final stamp = DateTime.now().millisecondsSinceEpoch;
  openDialog(
    (ctx) => AppDialog(
      title: 'Share as QR',
      maxWidth: 360,
      children: [
        Center(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: RepaintBoundary(
              key: key,
              child: _QrCard(data: data, from: from, books: books),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Share this code. The other person can save the picture.',
          textAlign: TextAlign.center,
          style: nu(12.5, FontWeight.w600, C.muted, 1.4),
        ),
      ],
      actions: [
        const Btn('Close'),
        Btn(
          'Save',
          onTap: () async {
            await saveCard(key, name: 'shelfwise-books-$stamp');
            return false;
          },
        ),
        Btn(
          'Share',
          kind: Kind.pri,
          onTap: () async {
            await shareCard(
              key,
              name: 'shelfwise-books-$stamp',
              text: '${plural(books.length, 'book')} from $from on Shelfwise.',
            );
            return false;
          },
        ),
      ],
    ),
  );
}

/// The shareable card: always light, so the code scans well in any theme.
class _QrCard extends StatelessWidget {
  final String data, from;
  final List<Item> books;
  const _QrCard({required this.data, required this.from, required this.books});

  static const _ink = Color(0xFF2B1D10), _soft = Color(0xFF8A6A4E);

  @override
  Widget build(BuildContext context) {
    final shown = books.take(5).toList();
    return Container(
      width: 300,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF6EA),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0x22000000)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('🦉', style: TextStyle(fontSize: 20)),
              const SizedBox(width: 6),
              Expanded(child: Text('Shelfwise', style: nu(17, FontWeight.w900, _ink))),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: const Color(0xFFF2DFC6), borderRadius: BorderRadius.circular(20)),
                child: Text('📚 ${plural(books.length, 'book')}', style: nu(12, FontWeight.w800, _ink)),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text('Shared by $from', maxLines: 1, overflow: TextOverflow.ellipsis, style: nu(12.5, FontWeight.w700, _soft)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
            child: QrImageView(
              data: data,
              version: QrVersions.auto,
              errorCorrectionLevel: QrErrorCorrectLevel.L,
              size: 240,
              padding: EdgeInsets.zero,
              backgroundColor: Colors.white,
              eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: _ink),
              dataModuleStyle: const QrDataModuleStyle(dataModuleShape: QrDataModuleShape.square, color: _ink),
            ),
          ),
          const SizedBox(height: 12),
          for (final b in shown)
            Padding(
              padding: const EdgeInsets.only(bottom: 3),
              child: Text(
                '• ${b.title}${b.author.isNotEmpty ? ' · ${b.author}' : ''}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: nu(12.5, FontWeight.w700, _ink),
              ),
            ),
          if (books.length > shown.length) Text('+ ${books.length - shown.length} more', style: nu(12, FontWeight.w700, _soft)),
        ],
      ),
    );
  }
}
