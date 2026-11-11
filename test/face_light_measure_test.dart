/// §7.3 — the frame measurement that feeds the light gate.
library;

import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
// ignore: implementation_imports
import 'package:trydos_wallet/src/utils/face_light_gate.dart';

void main() {
  /// A frame with a flat [frame] background and a flat [centre] square in the
  /// middle 50%, encoded as the JPEG a camera would hand over.
  Uint8List frameWith({
    required int centre,
    required int frame,
    bool noisyCentre = false,
  }) {
    final image = img.Image(width: 200, height: 200);
    img.fill(image, color: img.ColorRgb8(frame, frame, frame));

    for (var y = 50; y < 150; y++) {
      for (var x = 50; x < 150; x++) {
        // Alternating pixels give the Sobel pass something to find, which is
        // what "in focus" looks like to this measurement.
        final value = noisyCentre && ((x + y) % 2 == 0)
            ? (centre + 60).clamp(0, 255)
            : centre;
        image.setPixelRgb(x, y, value, value, value);
      }
    }
    return Uint8List.fromList(img.encodeJpg(image, quality: 95));
  }

  test('يقرأ سطوع المركز والإطار منفصلين', () {
    final sample = measureFaceLight(frameWith(centre: 120, frame: 40));
    expect(sample, isNotNull);
    // Centre box is the middle 50%, so it reads the bright square.
    expect(sample!.centreLuminance, closeTo(120, 12));
    // The frame mean mixes both and lands between them.
    expect(sample.frameLuminance, lessThan(sample.centreLuminance));
  });

  test('إطار مسطّح = حدّة شبه صفرية فيُرفض كضبابي', () {
    final sample = measureFaceLight(frameWith(centre: 120, frame: 120));
    expect(sample, isNotNull);
    expect(sample!.sharpness, lessThan(8));

    final gate = FaceLightGate();
    gate.accept(sample);
    expect(gate.verdict, FaceLightVerdict.tooBlurry);
  });

  test('إطار فيه تفاصيل يجتاز الحدّة', () {
    final sample = measureFaceLight(
      frameWith(centre: 120, frame: 120, noisyCentre: true),
    );
    expect(sample, isNotNull);
    expect(sample!.sharpness, greaterThan(8));

    final gate = FaceLightGate();
    gate.accept(sample);
    expect(gate.verdict, FaceLightVerdict.ok);
  });

  test('وجه مظلم أمام خلفية مضيئة يُقرأ إضاءة خلفية', () {
    final sample = measureFaceLight(frameWith(centre: 25, frame: 230));
    expect(sample, isNotNull);

    final gate = FaceLightGate();
    gate.accept(sample!);
    expect(gate.verdict, FaceLightVerdict.backlit);
  });

  test('غرفة مظلمة تُقرأ ظلاماً لا إضاءة خلفية', () {
    final sample = measureFaceLight(frameWith(centre: 25, frame: 30));
    final gate = FaceLightGate();
    gate.accept(sample!);
    expect(gate.verdict, FaceLightVerdict.tooDark);
  });

  test('إضاءة قوية جداً', () {
    final sample = measureFaceLight(frameWith(centre: 250, frame: 250));
    final gate = FaceLightGate();
    gate.accept(sample!);
    expect(gate.verdict, FaceLightVerdict.tooBright);
  });

  test('بايتات غير قابلة للفك تُعيد null فتُعفى البوابة', () {
    // The screen waives the gate on a null rather than stranding a user whose
    // camera will not give a reading.
    expect(measureFaceLight(Uint8List.fromList([1, 2, 3, 4])), isNull);
    expect(measureFaceLight(Uint8List(0)), isNull);
  });
}
