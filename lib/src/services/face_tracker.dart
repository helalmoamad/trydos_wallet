import 'dart:ui';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

import '../utils/face_framing_guide.dart';

/// One frame's reading: where the face is, and the points to draw on it.
class FaceTrackingResult {
  const FaceTrackingResult({
    required this.frame,
    required this.contours,
    required this.sourceSize,
  });

  /// Null when no face was found.
  final FaceFrame? frame;

  /// One polyline per facial contour — the oval, brows, eyes, nose, lips —
  /// in [sourceSize]'s coordinate space. Empty when no face.
  ///
  /// Kept grouped rather than flattened: which contour a point belongs to is
  /// what makes the overlay a face mesh instead of a spray of lines.
  final List<List<Offset>> contours;

  /// Every contour point, for callers that only need the cloud.
  List<Offset> get meshPoints => [for (final c in contours) ...c];

  /// Size of the analysed image, so the overlay can map the points.
  final Size sourceSize;

  static const FaceTrackingResult none = FaceTrackingResult(
    frame: null,
    contours: [],
    sourceSize: Size.zero,
  );
}

/// Follows one face through the camera stream.
///
/// Contours rather than a 468-point mesh: ML Kit's face-mesh API exists only
/// on Android, and this ships on both platforms. The ~130 contour points are
/// enough to draw a web that tracks the face and to measure how it is framed.
class FaceTracker {
  FaceTracker({FaceDetector? detector})
    : _detector =
          detector ??
          FaceDetector(
            options: FaceDetectorOptions(
              // Contours are what the overlay draws; without them a face is
              // just a box and there is no web.
              enableContours: true,
              // Tracking keeps the same face across frames, so the steadiness
              // measurement follows one person rather than whichever face the
              // detector happened to rank first.
              enableTracking: true,
              performanceMode: FaceDetectorMode.fast,
            ),
          );

  final FaceDetector _detector;

  /// True while a frame is in flight. The camera stream outruns the detector,
  /// and queuing frames would show a web lagging seconds behind the face.
  bool _busy = false;
  bool _closed = false;

  /// Analyses one camera frame. Returns null when the frame was skipped
  /// because the previous one is still being processed.
  Future<FaceTrackingResult?> process(
    CameraImage image,
    CameraDescription camera,
    int deviceOrientationDegrees,
  ) async {
    if (_busy || _closed) return null;
    _busy = true;

    try {
      final input = _toInputImage(image, camera, deviceOrientationDegrees);
      if (input == null) return FaceTrackingResult.none;

      final faces = await _detector.processImage(input);
      if (_closed) return null;

      // ML Kit rotates the frame internally and reports coordinates in that
      // rotated space. Handing the raw size on would scale every point by the
      // wrong ratio and throw the whole mesh off the face.
      final rotated =
          camera.sensorOrientation == 90 || camera.sensorOrientation == 270;
      final sourceSize = rotated
          ? Size(image.height.toDouble(), image.width.toDouble())
          : Size(image.width.toDouble(), image.height.toDouble());

      if (faces.isEmpty) {
        return FaceTrackingResult(
          frame: null,
          contours: const [],
          sourceSize: sourceSize,
        );
      }

      // The largest face: in a crowd the subject is the one holding the
      // phone, and picking by area is steadier than picking the first.
      final face = faces.reduce(
        (a, b) =>
            a.boundingBox.width * a.boundingBox.height >=
                b.boundingBox.width * b.boundingBox.height
            ? a
            : b,
      );

      return FaceTrackingResult(
        frame: FaceFrame(
          centreX: face.boundingBox.center.dx,
          centreY: face.boundingBox.center.dy,
          width: face.boundingBox.width,
          height: face.boundingBox.height,
          frameWidth: sourceSize.width,
          frameHeight: sourceSize.height,
        ),
        contours: _contours(face),
        sourceSize: sourceSize,
      );
    } catch (e) {
      // A frame the detector cannot read is not an error worth surfacing —
      // the next one is 30 ms away.
      if (kDebugMode) debugPrint('[FaceTracker] dropped a frame: $e');
      return FaceTrackingResult.none;
    } finally {
      _busy = false;
    }
  }

  /// The detector's contours, each kept as its own polyline.
  ///
  /// The face oval comes first when present, because the overlay uses it as
  /// the boundary it weaves the rest of the mesh inside.
  List<List<Offset>> _contours(Face face) {
    final oval = <List<Offset>>[];
    final rest = <List<Offset>>[];

    face.contours.forEach((type, contour) {
      if (contour == null || contour.points.length < 2) return;
      final points = [
        for (final p in contour.points) Offset(p.x.toDouble(), p.y.toDouble()),
      ];
      if (type == FaceContourType.face) {
        oval.add(points);
      } else {
        rest.add(points);
      }
    });

    return [...oval, ...rest];
  }

  InputImage? _toInputImage(
    CameraImage image,
    CameraDescription camera,
    int deviceOrientationDegrees,
  ) {
    final rotation = _rotation(camera, deviceOrientationDegrees);
    if (rotation == null) return null;

    final format = InputImageFormatValue.fromRawValue(image.format.raw);
    if (format == null) return null;
    // Single-plane formats only — nv21 on Android, bgra8888 on iOS, which is
    // what the camera is configured for. A multi-plane frame would need
    // stitching, and silently feeding the first plane gives the detector
    // half an image.
    if (image.planes.length != 1) return null;

    return InputImage.fromBytes(
      bytes: image.planes.first.bytes,
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation,
        format: format,
        bytesPerRow: image.planes.first.bytesPerRow,
      ),
    );
  }

  /// Combines the sensor's mounting angle with how the user is holding the
  /// phone. Get this wrong and the detector looks for sideways faces.
  InputImageRotation? _rotation(
    CameraDescription camera,
    int deviceOrientationDegrees,
  ) {
    final sensor = camera.sensorOrientation;
    final int degrees;
    if (camera.lensDirection == CameraLensDirection.front) {
      degrees = (sensor + deviceOrientationDegrees) % 360;
    } else {
      degrees = (sensor - deviceOrientationDegrees + 360) % 360;
    }
    return InputImageRotationValue.fromRawValue(degrees);
  }

  Future<void> close() async {
    _closed = true;
    await _detector.close();
  }
}
