import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../look.dart';
import '../services/book_qr.dart';
import '../services/sfx.dart';
import '../theme.dart';
import '../widgets/common.dart';

/// Opens the camera to scan a friend's Shelfwise book QR (or pick a saved
/// image of one from the gallery). Returns the books, or null.
Future<BookList?> scanBookQr() {
  dropFocus();
  return navKey.currentState!.push<BookList>(PageRouteBuilder(
    transitionDuration: const Duration(milliseconds: 380),
    pageBuilder: (_, _, _) => const QrScanScreen(),
    transitionsBuilder: (_, a, _, c) => FadeTransition(opacity: a, child: c),
  ));
}

class QrScanScreen extends StatefulWidget {
  const QrScanScreen({super.key});
  @override
  State<QrScanScreen> createState() => _QrScanScreenState();
}

class _QrScanScreenState extends State<QrScanScreen> with SingleTickerProviderStateMixin {
  final _ctl = MobileScannerController(formats: const [BarcodeFormat.qrCode], detectionSpeed: DetectionSpeed.normal);
  late final AnimationController _line = AnimationController(vsync: this, duration: const Duration(milliseconds: 1700))..repeat(reverse: true);
  bool _done = false, _torch = false, _picking = false;
  String _hint = 'Point at a Shelfwise QR code';

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);
  }

  @override
  void dispose() {
    Look.overlay();
    _line.dispose();
    _ctl.dispose();
    super.dispose();
  }

  /// True when [cap] held a Shelfwise code (and the screen is closing).
  bool _take(BarcodeCapture? cap) {
    if (_done || cap == null) return false;
    for (final b in cap.barcodes) {
      final list = decodeBooks(b.rawValue ?? '');
      if (list != null) {
        _done = true;
        Buzz.medium();
        Sfx.play('check');
        Navigator.of(context).pop(list);
        return true;
      }
    }
    return false;
  }

  void _found(BarcodeCapture cap) {
    if (_picking || _take(cap)) return;
    if (cap.barcodes.isNotEmpty && _hint.startsWith('Point')) {
      setState(() => _hint = 'That QR code isn’t a Shelfwise book list.');
    }
  }

  Future<void> _gallery() async {
    _picking = true; // don't let the camera act while the picker is open
    try {
      final img = await ImagePicker().pickImage(source: ImageSource.gallery);
      if (img == null || !mounted) return;
      setState(() => _hint = 'Reading the picture…');
      final cap = await _ctl.analyzeImage(img.path, formats: const [BarcodeFormat.qrCode]);
      if (!mounted || _take(cap)) return;
      setState(() => _hint = (cap?.barcodes.isEmpty ?? true)
          ? 'No QR code found in that picture. Try a clearer screenshot.'
          : 'That QR code isn’t a Shelfwise book list.');
    } catch (_) {
      if (mounted) setState(() => _hint = 'Couldn’t read that picture. Try another one.');
    } finally {
      _picking = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final w = min(mq.size.width - 80, 300.0);
    final window = Rect.fromCenter(center: Offset(mq.size.width / 2, mq.size.height * .42), width: w, height: w);
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(children: [
        Positioned.fill(
          child: MobileScanner(
            controller: _ctl,
            onDetect: _found,
            scanWindow: window,
            errorBuilder: (_, e) => Center(
              child: Padding(
                padding: const EdgeInsets.all(30),
                child: Text(
                  e.errorCode == MobileScannerErrorCode.permissionDenied
                      ? 'Shelfwise needs the camera to scan QR codes. Allow it in Android settings, or pick a saved QR image instead.'
                      : 'The camera couldn’t start. You can pick a saved QR image instead.',
                  textAlign: TextAlign.center,
                  style: nu(15, FontWeight.w700, Colors.white, 1.4),
                ),
              ),
            ),
          ),
        ),
        Positioned.fill(
          child: IgnorePointer(
            child: AnimatedBuilder(
              animation: _line,
              builder: (_, _) => CustomPaint(painter: _Overlay(window, Curves.easeInOut.transform(_line.value))),
            ),
          ),
        ),
        Positioned(
          left: 24,
          right: 24,
          top: window.bottom + 24,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: Text(_hint, key: ValueKey(_hint), textAlign: TextAlign.center, style: nu(15, FontWeight.w700, Colors.white, 1.4)),
          ),
        ),
        Positioned(
          top: mq.padding.top + 10,
          left: 12,
          right: 12,
          child: Row(children: [
            _round(Icons.arrow_back_rounded, 'Close scanner', () => Navigator.of(context).pop()),
            const SizedBox(width: 12),
            Expanded(child: Text('Scan shared books', style: nu(18, FontWeight.w800, Colors.white))),
            _round(_torch ? Icons.flash_on_rounded : Icons.flash_off_rounded, 'Torch', () {
              _ctl.toggleTorch();
              setState(() => _torch = !_torch);
            }),
          ]),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: mq.padding.bottom + 30,
          child: Center(
            child: Pill('Pick a QR image from the gallery', kind: Kind.normal, icon: const Icon(Icons.photo_library_rounded, size: 18), onTap: _gallery),
          ),
        ),
      ]),
    );
  }

  Widget _round(IconData i, String label, VoidCallback onTap) => Semantics(
        button: true,
        label: label,
        child: Pressable(
          onTap: onTap,
          scale: .88,
          child: Container(
            width: 42,
            height: 42,
            decoration: const BoxDecoration(color: Color(0x33FFFFFF), shape: BoxShape.circle),
            alignment: Alignment.center,
            child: Icon(i, color: Colors.white, size: 22),
          ),
        ),
      );
}

class _Overlay extends CustomPainter {
  final Rect r;
  final double t;
  _Overlay(this.r, this.t);
  @override
  void paint(Canvas c, Size s) {
    final rr = RRect.fromRectAndRadius(r, const Radius.circular(24));
    c.drawPath(
      Path()
        ..fillType = PathFillType.evenOdd
        ..addRect(Offset.zero & s)
        ..addRRect(rr),
      Paint()..color = const Color(0x99000000),
    );
    final corner = Paint()
      ..color = C.orange
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;
    const k = 34.0;
    for (final (x, y, dx, dy) in [(r.left, r.top, 1.0, 1.0), (r.right, r.top, -1.0, 1.0), (r.left, r.bottom, 1.0, -1.0), (r.right, r.bottom, -1.0, -1.0)]) {
      c.drawPath(
        Path()
          ..moveTo(x, y + dy * k)
          ..lineTo(x, y + dy * 12)
          ..quadraticBezierTo(x, y, x + dx * 12, y)
          ..lineTo(x + dx * k, y),
        corner,
      );
    }
    final y = r.top + 16 + (r.height - 32) * t;
    c.drawLine(
      Offset(r.left + 20, y),
      Offset(r.right - 20, y),
      Paint()
        ..shader = LinearGradient(colors: [C.orange.withValues(alpha: 0), C.orange, C.orange.withValues(alpha: 0)])
            .createShader(Rect.fromLTWH(r.left, y - 2, r.width, 4))
        ..strokeWidth = 3,
    );
  }

  @override
  bool shouldRepaint(_Overlay o) => o.t != t || o.r != r;
}
