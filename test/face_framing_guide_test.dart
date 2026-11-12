/// The steadying stage: what the user is told, and when the challenge starts.
library;

import 'package:flutter_test/flutter_test.dart';
// ignore: implementation_imports
import 'package:trydos_wallet/src/utils/face_framing_guide.dart';

void main() {
  const frameWidth = 400.0;
  const frameHeight = 600.0;

  /// A face centred in the frame, spanning [fill] of its width.
  FaceFrame face({double fill = 0.6, double dx = 0, double dy = 0}) {
    final width = frameWidth * fill;
    return FaceFrame(
      centreX: frameWidth / 2 + dx,
      centreY: frameHeight / 2 + dy,
      width: width,
      height: width * 1.3,
      frameWidth: frameWidth,
      frameHeight: frameHeight,
    );
  }

  final t0 = DateTime(2026, 11, 11, 10);
  DateTime at(int ms) => t0.add(Duration(milliseconds: ms));

  group('التعليمة المعروضة', () {
    test('لا وجه', () {
      final guide = FaceFramingGuide();
      expect(guide.accept(null, now: t0), isFalse);
      expect(guide.hint, FaceFramingHint.noFace);
    });

    test('وجه صغير = اقترب قليلاً', () {
      final guide = FaceFramingGuide();
      guide.accept(face(fill: 0.30), now: t0);
      expect(guide.hint, FaceFramingHint.moveCloser);
    });

    test('وجه كبير = ابتعد قليلاً', () {
      final guide = FaceFramingGuide();
      guide.accept(face(fill: 0.90), now: t0);
      expect(guide.hint, FaceFramingHint.moveBack);
    });

    test('وجه خارج المركز = وسّط وجهك', () {
      final guide = FaceFramingGuide();
      guide.accept(face(dx: 120), now: t0);
      expect(guide.hint, FaceFramingHint.centreFace);
    });

    test('مؤطَّر لكن يتحرك = ثبّت', () {
      final guide = FaceFramingGuide();
      guide.accept(face(), now: t0);
      expect(guide.hint, FaceFramingHint.holdSteady);
    });
  });

  group('الثبات', () {
    test('يصبح جاهزاً بعد المدة لا قبلها', () {
      final guide = FaceFramingGuide();
      expect(guide.accept(face(), now: at(0)), isFalse);
      expect(guide.accept(face(), now: at(300)), isFalse);
      expect(guide.accept(face(), now: at(850)), isFalse);
      expect(guide.accept(face(), now: at(900)), isTrue);
      expect(guide.hint, FaceFramingHint.ready);
    });

    test('حركة كبيرة تُصفّر العدّاد', () {
      final guide = FaceFramingGuide();
      guide.accept(face(), now: at(0));
      guide.accept(face(), now: at(300));
      // A 40 px jump on a 400 px frame is 10% — well past the 4% allowance.
      guide.accept(face(dx: 40), now: at(400));
      expect(guide.hint, FaceFramingHint.holdSteady);
      expect(guide.accept(face(dx: 40), now: at(900)), isFalse);
      expect(guide.accept(face(dx: 40), now: at(1400)), isTrue);
    });

    test('الاقتراب حركة أيضاً وإن بقي المركز ثابتاً', () {
      // Leaning in keeps the centre put but changes the size; a guide that
      // only watched the centre would call that still.
      final guide = FaceFramingGuide();
      guide.accept(face(fill: 0.50), now: at(0));
      guide.accept(face(fill: 0.50), now: at(300));
      guide.accept(face(fill: 0.62), now: at(400));
      expect(guide.accept(face(fill: 0.62), now: at(900)), isFalse);
    });

    test('ارتعاش طفيف مقبول', () {
      // Nobody holds perfectly still; 1% of the frame must not reset it.
      final guide = FaceFramingGuide();
      guide.accept(face(), now: at(0));
      guide.accept(face(dx: 4), now: at(300));
      guide.accept(face(dx: -4), now: at(600));
      expect(guide.accept(face(dx: 2), now: at(900)), isTrue);
    });

    test('اختفاء الوجه يُصفّر', () {
      final guide = FaceFramingGuide();
      guide.accept(face(), now: at(0));
      guide.accept(null, now: at(300));
      expect(guide.accept(face(), now: at(900)), isFalse);
      expect(guide.accept(face(), now: at(1800)), isTrue);
    });

    test('reset ينسى السلسلة', () {
      final guide = FaceFramingGuide();
      guide.accept(face(), now: at(0));
      guide.reset();
      expect(guide.hint, FaceFramingHint.noFace);
      expect(guide.accept(face(), now: at(1000)), isFalse);
    });
  });

  group('التقدّم', () {
    test('صفر قبل أي إطار مؤطَّر', () {
      final guide = FaceFramingGuide();
      expect(guide.progress, 0);
      guide.accept(face(fill: 0.2), now: t0);
      expect(guide.progress, 0);
    });

    test('محصور بين صفر وواحد', () {
      final guide = FaceFramingGuide();
      guide.accept(face(), now: DateTime.now());
      expect(guide.progress, inInclusiveRange(0, 1));
    });
  });

  group('هندسة الإطار', () {
    test('fill نسبة عرض الوجه للإطار', () {
      expect(face(fill: 0.5).fill, closeTo(0.5, 0.001));
    });

    test('centreOffset صفر في المنتصف', () {
      expect(face().centreOffset, closeTo(0, 0.001));
    });

    test('centreOffset يأخذ الأسوأ من المحورين', () {
      // 100 px off a 200 px half-width is 0.5; vertically it is 100/300.
      expect(face(dx: 100, dy: 100).centreOffset, closeTo(0.5, 0.001));
    });

    test('إطار بلا أبعاد لا يقسم على صفر', () {
      const degenerate = FaceFrame(
        centreX: 0,
        centreY: 0,
        width: 10,
        height: 10,
        frameWidth: 0,
        frameHeight: 0,
      );
      expect(degenerate.fill, 0);
      expect(degenerate.centreOffset, 1);
    });
  });
}
