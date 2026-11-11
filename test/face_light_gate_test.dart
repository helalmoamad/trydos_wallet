/// §7.3 / §13 — the light gate run before an AWS liveness session is opened.
library;

import 'package:flutter_test/flutter_test.dart';
// ignore: implementation_imports
import 'package:trydos_wallet/src/utils/face_light_gate.dart';

void main() {
  FaceLightSample sample({
    double centre = 120,
    double frame = 120,
    double sharpness = 20,
  }) {
    return FaceLightSample(
      centreLuminance: centre,
      frameLuminance: frame,
      sharpness: sharpness,
    );
  }

  final t0 = DateTime(2026, 11, 10, 12);

  test('إضاءة جيدة تفتح البوابة بعد ٧٠٠ مللي ثانية لا قبلها', () {
    final gate = FaceLightGate();
    expect(gate.accept(sample(), now: t0), isFalse);
    expect(
      gate.accept(sample(), now: t0.add(const Duration(milliseconds: 650))),
      isFalse,
    );
    expect(
      gate.accept(sample(), now: t0.add(const Duration(milliseconds: 700))),
      isTrue,
    );
    expect(gate.verdict, FaceLightVerdict.ok);
  });

  test('إطار سيئ واحد يُصفّر العدّاد', () {
    // A gate that opened on one lucky frame between two bad ones would send
    // the user into a billed AWS session that is going to fail.
    final gate = FaceLightGate();
    gate.accept(sample(), now: t0);
    gate.accept(
      sample(centre: 10, frame: 12),
      now: t0.add(const Duration(milliseconds: 300)),
    );
    expect(
      gate.accept(sample(), now: t0.add(const Duration(milliseconds: 800))),
      isFalse,
    );
    expect(
      gate.accept(sample(), now: t0.add(const Duration(milliseconds: 1500))),
      isTrue,
    );
  });

  test('حدود السطوع ٥٥ و ٢١٥', () {
    final gate = FaceLightGate();
    gate.accept(sample(centre: 216, frame: 216), now: t0);
    expect(gate.verdict, FaceLightVerdict.tooBright);

    gate.accept(sample(centre: 54, frame: 60), now: t0);
    expect(gate.verdict, FaceLightVerdict.tooDark);

    gate.accept(sample(centre: 55), now: t0);
    expect(gate.verdict, FaceLightVerdict.ok);

    gate.accept(sample(centre: 215), now: t0);
    expect(gate.verdict, FaceLightVerdict.ok);
  });

  test('الإضاءة الخلفية تُميَّز عن الظلام — نسبة ١.٦', () {
    final gate = FaceLightGate();
    // Dark face, bright frame: 100 / 50 = 2.0 ⇒ backlit, turn around.
    gate.accept(sample(centre: 50, frame: 100), now: t0);
    expect(gate.verdict, FaceLightVerdict.backlit);

    // Dark face, dark frame: 60 / 50 = 1.2 ⇒ just a dark room.
    gate.accept(sample(centre: 50, frame: 60), now: t0);
    expect(gate.verdict, FaceLightVerdict.tooDark);

    // Exactly at the ratio counts as backlit.
    gate.accept(sample(centre: 50, frame: 80), now: t0);
    expect(gate.verdict, FaceLightVerdict.backlit);
  });

  test('مركز أسود تماماً لا يقسم على صفر', () {
    final gate = FaceLightGate();
    expect(
      () => gate.accept(sample(centre: 0, frame: 100), now: t0),
      returnsNormally,
    );
    expect(gate.verdict, FaceLightVerdict.backlit);
  });

  test('الحدّة تُفحص بعد السطوع', () {
    final gate = FaceLightGate();
    gate.accept(sample(sharpness: 7.9), now: t0);
    expect(gate.verdict, FaceLightVerdict.tooBlurry);

    gate.accept(sample(sharpness: 8), now: t0);
    expect(gate.verdict, FaceLightVerdict.ok);

    // Too dark AND blurry reports the light first — it is the actionable one.
    gate.accept(sample(centre: 20, frame: 22, sharpness: 1), now: t0);
    expect(gate.verdict, FaceLightVerdict.tooDark);
  });

  test('reset ينسى سلسلة الإطارات الجيدة', () {
    final gate = FaceLightGate();
    gate.accept(sample(), now: t0);
    gate.reset();
    expect(
      gate.accept(sample(), now: t0.add(const Duration(milliseconds: 900))),
      isFalse,
    );
  });
}
