import 'dart:io';
import 'dart:math' as math;
import 'package:image/image.dart' as img;

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shimmer/shimmer.dart';
import 'package:trydos_wallet/src/constent/assets.dart';
import 'package:trydos_wallet/src/constent/build_context.dart';
import 'package:trydos_wallet/src/constent/rdb_loading.dart';
import 'package:trydos_wallet/src/constent/styles.dart';
import 'package:trydos_wallet/src/constent/theme/typography.dart';
import 'package:trydos_wallet/src/services/users_api_service.dart';
import 'package:trydos_wallet/trydos_wallet.dart';

class ProfilePhotoPage extends StatefulWidget {
  const ProfilePhotoPage({
    super.key,
    required this.languageCode,
    this.initialImagePath,
  });

  final String languageCode;
  final String? initialImagePath;

  @override
  State<ProfilePhotoPage> createState() => _ProfilePhotoPageState();
}

class _ProfilePhotoPageState extends State<ProfilePhotoPage> {
  final MediaApiService _mediaApi = MediaApiService();
  final UsersApiService _usersApi = UsersApiService();
  String? _savedImagePath;
  String? _draftImagePath;
  bool _draftRemove = false;
  bool _showActions = false;
  bool _isProcessingImage = false;
  bool _isSaving = false;

  bool get _isRtl => widget.languageCode == 'ar' || widget.languageCode == 'ku';

  @override
  void initState() {
    super.initState();
    final initial = widget.initialImagePath?.trim();
    _savedImagePath = (initial == null || initial.isEmpty) ? null : initial;
  }

  String? get _displayImagePath {
    if (_draftRemove) return null;
    return _draftImagePath ?? _savedImagePath;
  }

  bool get _hasImage => _displayImagePath != null;

  bool get _hasUnsavedChanges => _draftRemove || _draftImagePath != null;

  bool _isRemoteImageSource(String path) {
    final value = path.trim().toLowerCase();
    return value.startsWith('http://') || value.startsWith('https://');
  }

  Widget _buildProfileImage(String imageSource) {
    if (_isRemoteImageSource(imageSource)) {
      return Image.network(
        imageSource,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return const _GrayAvatarLoadingPlaceholder();
        },
        errorBuilder: (_, __, ___) => _GrayAvatarPlaceholder(),
      );
    }

    return Image.file(
      File(imageSource),
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      errorBuilder: (_, __, ___) => _GrayAvatarPlaceholder(),
    );
  }

  Future<bool> _ensurePermission(ImageSource source) async {
    if (source == ImageSource.camera) {
      final status = await Permission.camera.request();
      return status.isGranted;
    }

    return true;
  }

  Future<void> _openPickerSlider(ImageSource source) async {
    if (_isProcessingImage) return;
    _isProcessingImage = true;

    try {
      final hasPermission = await _ensurePermission(source);
      if (!hasPermission) {
        if (mounted) {
          _showPermissionMessage(source);
        }
        return;
      }

      String? selectedPath;
      if (source == ImageSource.camera) {
        selectedPath = await _openCameraSlider();
      } else {
        final pickedImage = await ImagePicker().pickImage(
          source: ImageSource.gallery,
          imageQuality: 95,
        );
        selectedPath = pickedImage?.path;
      }

      if (selectedPath == null || selectedPath.isEmpty) return;

      final previewPath = await _openPreviewCropSlider(selectedPath);
      if (previewPath == null || previewPath.isEmpty) return;

      if (!mounted) return;
      setState(() {
        _draftImagePath = previewPath;
        _draftRemove = false;
        _showActions = false;
      });
    } finally {
      _isProcessingImage = false;
    }
  }

  Future<String?> _openPreviewCropSlider(String imagePath) async {
    if (!mounted) return null;
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final height = MediaQuery.of(context).size.height * 0.90;
        return SizedBox(
          height: height,
          child: _PreviewCropSheet(
            languageCode: widget.languageCode,
            initialPath: imagePath,
          ),
        );
      },
    );
  }

  Future<String?> _openCameraSlider() async {
    if (!mounted) return null;
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final height = MediaQuery.of(context).size.height * 0.90;
        return SizedBox(
          height: height,
          child: _CameraCaptureSheet(languageCode: widget.languageCode),
        );
      },
    );
  }

  void _markRemove() {
    setState(() {
      _draftRemove = true;
      _draftImagePath = null;
      _showActions = false;
    });
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _showPermissionMessage(ImageSource source) {
    final message = AppStrings.get(
      widget.languageCode,
      source == ImageSource.camera
          ? 'permission_camera_required'
          : 'permission_gallery_required',
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        action: SnackBarAction(
          label: AppStrings.get(widget.languageCode, 'open_settings'),
          onPressed: openAppSettings,
        ),
      ),
    );
  }

  Future<bool> _updateProfilePictureOnBackend(String profilePictureUrl) async {
    final result = await _usersApi.updateMyProfile(
      firstName: TrydosWallet.config.firstName,
      lastName: TrydosWallet.config.lastName,
      profilePictureURL: profilePictureUrl,
    );

    if (result.isFailure) {
      if (!mounted) return false;
      _showErrorMessage(
        result.errorMessage ?? AppStrings.get(widget.languageCode, 'error'),
      );
      return false;
    }

    return true;
  }

  Future<void> _saveChanges() async {
    if (_isSaving) return;

    setState(() {
      _isSaving = true;
    });

    try {
      if (_draftRemove) {
        final deleteSucceeded = await _updateProfilePictureOnBackend('');
        if (!deleteSucceeded) return;

        TrydosWallet.updateUserInfo(profileImageUrl: '');

        if (!mounted) return;
        setState(() {
          _savedImagePath = null;
          _draftImagePath = null;
          _draftRemove = false;
          _showActions = false;
        });
        return;
      }

      final draftPath = _draftImagePath?.trim();
      if (draftPath == null || draftPath.isEmpty) return;

      final uploadResult = await _mediaApi.uploadDirect(
        filePath: draftPath,
        type: 'image',
        metadata: {'purpose': 'profile_photo'},
      );

      if (uploadResult.isFailure || uploadResult.data == null) {
        if (!mounted) return;
        _showErrorMessage(
          uploadResult.errorMessage ??
              AppStrings.get(widget.languageCode, 'error'),
        );
        return;
      }

      final uploadedUrl = uploadResult.data!.url.trim();
      final updateSucceeded = await _updateProfilePictureOnBackend(uploadedUrl);
      if (!updateSucceeded) return;

      TrydosWallet.updateUserInfo(profileImageUrl: uploadedUrl);

      if (!mounted) return;
      setState(() {
        _savedImagePath = uploadedUrl.isEmpty ? null : uploadedUrl;
        _draftImagePath = null;
        _draftRemove = false;
        _showActions = false;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: _isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: const Color(0xFFFFFFFF),
        body: SafeArea(
          child: Column(
            children: [
              SizedBox(
                height: 50.h,
                width: 1.sw,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 10.w),
                      child: InkWell(
                        onTap: () => Navigator.of(context).pop(),
                        child: SvgPicture.asset(
                          TrydosWalletAssets.back,
                          package: TrydosWalletStyles.packageName,
                          height: 20.h,
                          matchTextDirection: true,
                        ),
                      ),
                    ),

                    const Spacer(),
                    !_hasUnsavedChanges
                        ? SizedBox.shrink()
                        : SizedBox(width: 40.w),
                    Text(
                      AppStrings.get(widget.languageCode, 'profile_photo'),
                      textAlign: TextAlign.center,
                      style: context.textTheme.bodyMedium?.mq.copyWith(
                        fontSize: 16.sp,
                        height: 1.1,
                        color: const Color(0xFF1D1D1D),
                      ),
                    ),
                    _hasUnsavedChanges
                        ? SizedBox.shrink()
                        : SizedBox(
                            width: 20.w,
                          ), // Placeholder for centering title
                    const Spacer(),
                    _hasUnsavedChanges
                        ? Padding(
                            padding: EdgeInsets.symmetric(horizontal: 10.w),
                            child: SizedBox(
                              width: 40.w,
                              child: InkWell(
                                onTap: _isSaving ? null : _saveChanges,
                                borderRadius: BorderRadius.circular(8.r),
                                child: _isSaving
                                    ? SizedBox(
                                        width: 40.w,
                                        height: 30.h,
                                        child: RDBLoader(
                                          size: 22.h,
                                          color: const Color(0xff1D1D1D),
                                        ),
                                      )
                                    : Text(
                                        AppStrings.get(
                                          widget.languageCode,
                                          'save',
                                        ),
                                        textAlign: TextAlign.end,
                                        style: context.textTheme.bodyMedium?.mq
                                            .copyWith(
                                              color: const Color(0xFF388CFF),
                                              fontSize: 16.sp,
                                              height: 1.1,
                                            ),
                                      ),
                              ),
                            ),
                          )
                        : const SizedBox.shrink(),
                  ],
                ),
              ),
              SizedBox(height: 20.h),
              Container(
                margin: EdgeInsets.symmetric(horizontal: 40.w),
                width: 1.sw,
                height: 350.h,
                decoration: BoxDecoration(
                  color: const Color(0xFFFCFCFC),
                  borderRadius: BorderRadius.circular(30.r),
                  border: Border.all(
                    color: (!_hasImage)
                        ? const Color(0xffC3C3C3)
                        : const Color(0xFFFFFFFF),
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(30.r),
                        child: Container(
                          color: const Color(0xFFFCFCFC),
                          alignment: Alignment.center,
                          child: _hasImage
                              ? _buildProfileImage(_displayImagePath!)
                              : _GrayAvatarPlaceholder(),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            _showActions = true;
                          });
                        },
                        child: Container(
                          height: 35.h,
                          width: 1.sw - 80.w,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: const Color(0xFF404040),
                            borderRadius: BorderRadius.only(
                              bottomLeft: Radius.circular(30.r),
                              bottomRight: Radius.circular(30.r),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              SvgPicture.asset(
                                TrydosWalletAssets.addPhoto,
                                package: TrydosWalletStyles.packageName,
                                height: 14.h,
                              ),
                              SizedBox(width: 5.w),
                              Text(
                                AppStrings.get(
                                  widget.languageCode,
                                  _hasImage
                                      ? 'edit_profile_photo'
                                      : 'add_profile_photo',
                                ),
                                style: context.textTheme.bodySmall?.rq.copyWith(
                                  color: const Color(0xFFFCFCFC),
                                  fontSize: 14.sp,
                                  height: 1.1,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (_showActions) ...[
                SizedBox(height: 20.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _ActionIcon(
                      label: AppStrings.get(widget.languageCode, 'choose'),
                      assetPath: TrydosWalletAssets.gallary,
                      onTap: _isProcessingImage
                          ? () {}
                          : () => _openPickerSlider(ImageSource.gallery),
                    ),
                    SizedBox(width: 40.w),
                    _ActionIcon(
                      label: AppStrings.get(widget.languageCode, 'take_photo'),
                      assetPath: TrydosWalletAssets.takePhoto,
                      onTap: _isProcessingImage
                          ? () {}
                          : () => _openPickerSlider(ImageSource.camera),
                    ),
                    if (_hasImage) ...[
                      SizedBox(width: 40.w),
                      _ActionIcon(
                        label: AppStrings.get(widget.languageCode, 'remove'),
                        assetPath: TrydosWalletAssets.delete,
                        onTap: _markRemove,
                      ),
                    ],
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _CameraCaptureSheet extends StatefulWidget {
  const _CameraCaptureSheet({required this.languageCode});

  final String languageCode;

  @override
  State<_CameraCaptureSheet> createState() => _CameraCaptureSheetState();
}

class _CameraCaptureSheetState extends State<_CameraCaptureSheet> {
  List<CameraDescription> _cameras = [];
  CameraController? _controller;
  int _index = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera([int? preferredIndex]) async {
    setState(() => _loading = true);

    _cameras = await availableCameras();
    if (_cameras.isEmpty) {
      if (!mounted) return;
      setState(() => _loading = false);
      return;
    }

    if (preferredIndex != null) {
      _index = preferredIndex;
    } else {
      final front = _cameras.indexWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
      );
      _index = front >= 0 ? front : 0;
    }

    await _controller?.dispose();
    _controller = CameraController(
      _cameras[_index],
      ResolutionPreset.high,
      enableAudio: false,
    );

    await _controller!.initialize();

    if (!mounted) return;
    setState(() => _loading = false);
  }

  Future<void> _switchCamera() async {
    if (_cameras.length < 2) return;
    final next = (_index + 1) % _cameras.length;
    await _initCamera(next);
  }

  Future<void> _capture() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;

    final file = await controller.takePicture();
    final savedPath = await _normalizeCapturedPhoto(file);
    if (!mounted) return;
    Navigator.of(context).pop(savedPath);
  }

  Future<String> _normalizeCapturedPhoto(XFile file) async {
    final camera = _cameras[_index];
    if (camera.lensDirection != CameraLensDirection.front) {
      return file.path;
    }

    try {
      final bytes = await file.readAsBytes();
      final decoded = img.decodeImage(bytes);
      if (decoded == null) {
        return file.path;
      }

      final mirrored = img.flipHorizontal(decoded);
      final outBytes = img.encodeJpg(mirrored, quality: 95);
      final outPath =
          '${Directory.systemTemp.path}/front_camera_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final outFile = File(outPath);
      await outFile.writeAsBytes(outBytes, flush: true);
      return outFile.path;
    } catch (_) {
      return file.path;
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFF5F5F5),
      borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            SizedBox(height: 10.h),
            Container(
              width: 44.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: const Color(0xFFD3D3D3),
                borderRadius: BorderRadius.circular(100.r),
              ),
            ),
            SizedBox(height: 12.h),
            Text(
              AppStrings.get(widget.languageCode, 'take_photo'),
              style: context.textTheme.bodyMedium?.mq.copyWith(
                fontSize: 16.sp,
                height: 1.1,
                color: const Color(0xFF1D1D1D),
              ),
            ),
            SizedBox(height: 14.h),
            Container(
              margin: EdgeInsets.symmetric(horizontal: 12.w),
              height: 500.h,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(20.r),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20.r),
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : (_controller != null && _controller!.value.isInitialized)
                    ? SizedBox.expand(
                        child: FittedBox(
                          fit: BoxFit.cover,
                          child: SizedBox(
                            width: _controller!.value.previewSize!.height,
                            height: _controller!.value.previewSize!.width,
                            child: CameraPreview(_controller!),
                          ),
                        ),
                      )
                    : Center(
                        child: Text(
                          AppStrings.get(
                            widget.languageCode,
                            'camera_unavailable',
                          ),
                          style: const TextStyle(
                            color: Colors.white,
                            height: 1.1,
                          ),
                        ),
                      ),
              ),
            ),
            SizedBox(height: 14.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                InkWell(
                  onTap: _switchCamera,
                  borderRadius: BorderRadius.circular(100.r),
                  child: Container(
                    width: 46.w,
                    height: 46.h,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: const Color(0xFF404040),
                      borderRadius: BorderRadius.circular(100.r),
                    ),
                    child: const Icon(
                      Icons.flip_camera_android_rounded,
                      color: Colors.white,
                    ),
                  ),
                ),
                SizedBox(width: 24.w),
                InkWell(
                  onTap: _capture,
                  borderRadius: BorderRadius.circular(100.r),
                  child: Container(
                    width: 64.w,
                    height: 64.h,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFF404040),
                        width: 4,
                      ),
                      color: Colors.white,
                    ),
                    child: const Icon(Icons.camera_alt_rounded),
                  ),
                ),
              ],
            ),
            SizedBox(height: 18.h),
          ],
        ),
      ),
    );
  }
}

class _PreviewCropSheet extends StatefulWidget {
  const _PreviewCropSheet({
    required this.languageCode,
    required this.initialPath,
  });

  final String languageCode;
  final String initialPath;

  @override
  State<_PreviewCropSheet> createState() => _PreviewCropSheetState();
}

class _PreviewCropSheetState extends State<_PreviewCropSheet> {
  late String _currentPath;
  bool _isCropping = false;
  bool _isLoadingImage = true;
  img.Image? _decodedImage;
  Rect? _cropRect;
  Size? _viewportSize;

  @override
  void initState() {
    super.initState();
    _currentPath = widget.initialPath;
    _loadImage(_currentPath);
  }

  Future<void> _loadImage(String path) async {
    setState(() => _isLoadingImage = true);
    try {
      final bytes = await File(path).readAsBytes();
      final decoded = img.decodeImage(bytes);
      if (!mounted) return;
      setState(() {
        _decodedImage = decoded;
        _cropRect = null;
        _isLoadingImage = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _decodedImage = null;
        _cropRect = null;
        _isLoadingImage = false;
      });
    }
  }

  Size _fittedSize(Size viewport, img.Image image) {
    final imageW = image.width.toDouble();
    final imageH = image.height.toDouble();
    final fit = math.min(viewport.width / imageW, viewport.height / imageH);
    return Size(imageW * fit, imageH * fit);
  }

  Rect _imageDisplayRect(Size viewport, img.Image image) {
    final fitted = _fittedSize(viewport, image);
    return Rect.fromLTWH(
      (viewport.width - fitted.width) / 2,
      (viewport.height - fitted.height) / 2,
      fitted.width,
      fitted.height,
    );
  }

  Size _previewViewportSize(Size available, img.Image image) {
    return _fittedSize(available, image);
  }

  double get _profileFrameAspectRatio => (1.sw - 80.w) / 350.h;

  Rect _defaultCropRect(Size viewport, img.Image image) {
    final imageRect = _imageDisplayRect(viewport, image);
    final aspectRatio = _profileFrameAspectRatio;

    var width = imageRect.width;
    var height = width / aspectRatio;

    if (height > imageRect.height) {
      height = imageRect.height;
      width = height * aspectRatio;
    }

    return Rect.fromLTWH(
      imageRect.left + (imageRect.width - width) / 2,
      imageRect.top + (imageRect.height - height) / 2,
      width,
      height,
    );
  }

  Rect _resolvedCropRect({required Size viewport, required img.Image image}) {
    final imageRect = _imageDisplayRect(viewport, image);
    final aspectRatio = _profileFrameAspectRatio;
    final base = _cropRect ?? _defaultCropRect(viewport, image);

    var minWidth = math.min(110.0, imageRect.width);
    var minHeight = minWidth / aspectRatio;
    if (minHeight > imageRect.height) {
      minHeight = imageRect.height;
      minWidth = minHeight * aspectRatio;
    }

    final maxWidth = math.min(imageRect.width, imageRect.height * aspectRatio);
    final width = base.width.clamp(minWidth, maxWidth).toDouble();
    final height = (width / aspectRatio)
        .clamp(minHeight, imageRect.height)
        .toDouble();
    final left = base.left
        .clamp(imageRect.left, imageRect.right - width)
        .toDouble();
    final top = base.top
        .clamp(imageRect.top, imageRect.bottom - height)
        .toDouble();
    return Rect.fromLTWH(left, top, width, height);
  }

  void _moveCropRect(Offset delta) {
    final viewport = _viewportSize;
    final image = _decodedImage;
    if (viewport == null || image == null) return;
    final bounds = _imageDisplayRect(viewport, image);
    final rect = _resolvedCropRect(viewport: viewport, image: image);
    final moved = Rect.fromLTWH(
      rect.left + delta.dx,
      rect.top + delta.dy,
      rect.width,
      rect.height,
    );
    setState(() {
      _cropRect = Rect.fromLTWH(
        moved.left.clamp(bounds.left, bounds.right - moved.width),
        moved.top.clamp(bounds.top, bounds.bottom - moved.height),
        moved.width,
        moved.height,
      );
    });
  }

  void _resizeCropRect(Offset delta) {
    final viewport = _viewportSize;
    final image = _decodedImage;
    if (viewport == null || image == null) return;
    final bounds = _imageDisplayRect(viewport, image);
    final rect = _resolvedCropRect(viewport: viewport, image: image);
    final aspectRatio = _profileFrameAspectRatio;
    var minWidth = math.min(110.0, bounds.width);
    var minHeight = minWidth / aspectRatio;
    if (minHeight > bounds.height) {
      minHeight = bounds.height;
      minWidth = minHeight * aspectRatio;
    }

    final maxWidth = math.min(
      bounds.right - rect.left,
      (bounds.bottom - rect.top) * aspectRatio,
    );
    final widthDelta = (delta.dx + (delta.dy * aspectRatio)) / 2;
    final nextWidth = (rect.width + widthDelta)
        .clamp(minWidth, maxWidth)
        .toDouble();
    final nextHeight = nextWidth / aspectRatio;
    setState(() {
      _cropRect = Rect.fromLTWH(rect.left, rect.top, nextWidth, nextHeight);
    });
  }

  Future<void> _cropCurrent() async {
    if (_isCropping) return;
    setState(() => _isCropping = true);

    try {
      final image = _decodedImage;
      final viewport = _viewportSize;
      if (image == null || viewport == null) return;
      final cropRect = _resolvedCropRect(viewport: viewport, image: image);
      final imageRect = _imageDisplayRect(viewport, image);

      var cropX =
          ((cropRect.left - imageRect.left) / imageRect.width * image.width)
              .round();
      var cropY =
          ((cropRect.top - imageRect.top) / imageRect.height * image.height)
              .round();
      var cropW = (cropRect.width / imageRect.width * image.width).round();
      var cropH = (cropRect.height / imageRect.height * image.height).round();

      cropX = cropX.clamp(0, image.width - 1);
      cropY = cropY.clamp(0, image.height - 1);
      cropW = cropW.clamp(1, image.width - cropX);
      cropH = cropH.clamp(1, image.height - cropY);

      final cropped = img.copyCrop(
        image,
        x: cropX,
        y: cropY,
        width: cropW,
        height: cropH,
      );

      final outBytes = img.encodeJpg(cropped, quality: 95);
      final outPath =
          '${Directory.systemTemp.path}/profile_crop_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final outFile = File(outPath);
      await outFile.writeAsBytes(outBytes, flush: true);

      if (!mounted) return;
      _currentPath = outPath;
      await _loadImage(outPath);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.get(widget.languageCode, 'error'))),
      );
    } finally {
      if (mounted) {
        setState(() => _isCropping = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFF5F5F5),
      borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            SizedBox(height: 10.h),
            Container(
              width: 44.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: const Color(0xFFD3D3D3),
                borderRadius: BorderRadius.circular(100.r),
              ),
            ),
            SizedBox(height: 12.h),
            Text(
              AppStrings.get(widget.languageCode, 'preview_crop'),
              style: context.textTheme.bodyMedium?.mq.copyWith(
                fontSize: 16.sp,
                height: 1.1,
                color: const Color(0xFF1D1D1D),
              ),
            ),
            SizedBox(height: 14.h),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final image = _decodedImage;
                  final availableSize = Size(
                    constraints.maxWidth - 40.w,
                    constraints.maxHeight,
                  );
                  final viewport = image == null
                      ? availableSize
                      : _previewViewportSize(availableSize, image);
                  _viewportSize = viewport;
                  final imageRect = image == null
                      ? null
                      : _imageDisplayRect(viewport, image);
                  final cropRect = image == null
                      ? null
                      : _resolvedCropRect(viewport: viewport, image: image);

                  if (cropRect != null) {
                    _cropRect = cropRect;
                  }

                  return Container(
                    margin: EdgeInsets.symmetric(horizontal: 20.w),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F5F5),
                      borderRadius: BorderRadius.circular(20.r),
                    ),
                    child: Center(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20.r),
                        child: SizedBox(
                          width: viewport.width,
                          height: viewport.height,
                          child: _isLoadingImage
                              ? const Center(child: CircularProgressIndicator())
                              : image == null
                              ? const SizedBox.shrink()
                              : Stack(
                                  children: [
                                    Positioned.fromRect(
                                      rect: imageRect!,
                                      child: Image.file(
                                        File(_currentPath),
                                        fit: BoxFit.fill,
                                      ),
                                    ),
                                    IgnorePointer(
                                      child: Stack(
                                        children: [
                                          Positioned(
                                            left: 0,
                                            right: 0,
                                            top: 0,
                                            height: cropRect!.top,
                                            child: Container(
                                              color: Colors.black54,
                                            ),
                                          ),
                                          Positioned(
                                            left: 0,
                                            right: 0,
                                            top: cropRect.bottom,
                                            bottom: 0,
                                            child: Container(
                                              color: Colors.black54,
                                            ),
                                          ),
                                          Positioned(
                                            left: 0,
                                            top: cropRect.top,
                                            width: cropRect.left,
                                            height: cropRect.height,
                                            child: Container(
                                              color: Colors.black54,
                                            ),
                                          ),
                                          Positioned(
                                            left: cropRect.right,
                                            right: 0,
                                            top: cropRect.top,
                                            height: cropRect.height,
                                            child: Container(
                                              color: Colors.black54,
                                            ),
                                          ),
                                          Positioned.fromRect(
                                            rect: cropRect,
                                            child: Container(
                                              decoration: BoxDecoration(
                                                border: Border.all(
                                                  color: const Color(
                                                    0xFF388CFF,
                                                  ),
                                                  width: 2,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Positioned.fromRect(
                                      rect: cropRect,
                                      child: GestureDetector(
                                        onPanUpdate: (details) =>
                                            _moveCropRect(details.delta),
                                        child: Container(
                                          color: Colors.transparent,
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      left: cropRect.right - 16,
                                      top: cropRect.bottom - 16,
                                      child: GestureDetector(
                                        onPanUpdate: (details) =>
                                            _resizeCropRect(details.delta),
                                        child: Container(
                                          width: 28,
                                          height: 28,
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF388CFF),
                                            borderRadius: BorderRadius.circular(
                                              14,
                                            ),
                                            border: Border.all(
                                              color: Colors.white,
                                              width: 2,
                                            ),
                                          ),
                                          child: const Icon(
                                            Icons.open_in_full,
                                            size: 14,
                                            color: Colors.white,
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
              ),
            ),
            SizedBox(height: 14.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                InkWell(
                  onTap: _isCropping ? null : _cropCurrent,
                  borderRadius: BorderRadius.circular(12.r),
                  child: Container(
                    height: 42.h,
                    width: 120.w,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFFFFF),
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(color: const Color(0xFF404040)),
                    ),
                    child: _isCropping
                        ? SizedBox(
                            width: 16.w,
                            height: 16.h,
                            child: const CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            AppStrings.get(widget.languageCode, 'crop'),
                            style: context.textTheme.bodyMedium?.mq.copyWith(
                              color: const Color(0xFF1D1D1D),
                              fontSize: 13.sp,
                              height: 1.1,
                            ),
                          ),
                  ),
                ),
                SizedBox(width: 14.w),
                InkWell(
                  onTap: _isCropping
                      ? null
                      : () => Navigator.of(context).pop(_currentPath),
                  borderRadius: BorderRadius.circular(12.r),
                  child: Container(
                    height: 42.h,
                    width: 140.w,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: const Color(0xFF404040),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Text(
                      AppStrings.get(widget.languageCode, 'use_photo'),
                      style: context.textTheme.bodyMedium?.mq.copyWith(
                        color: Colors.white,
                        fontSize: 13.sp,
                        height: 1.1,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 18.h),
          ],
        ),
      ),
    );
  }
}

class _ActionIcon extends StatelessWidget {
  const _ActionIcon({
    required this.label,
    required this.assetPath,
    required this.onTap,
  });

  final String label;
  final String assetPath;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: SizedBox(
        width: 62.w,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SvgPicture.asset(
              assetPath,
              package: TrydosWalletStyles.packageName,
              width: 20.w,
            ),
            SizedBox(height: 6.h),
            Text(
              label,
              style: context.textTheme.bodySmall?.rq.copyWith(
                color: const Color(0xff1D1D1D),
                fontSize: 11.sp,
                height: 1.1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GrayAvatarPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFFCFCFC),
      alignment: Alignment.center,
      child: SvgPicture.asset(
        TrydosWalletAssets.personHide,
        height: 250.h,
        package: TrydosWalletStyles.packageName,
      ),
    );
  }
}

class _GrayAvatarLoadingPlaceholder extends StatelessWidget {
  const _GrayAvatarLoadingPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: const Color(0xFFE4E4E4),
      highlightColor: const Color(0xFFF3F3F3),
      child: Container(
        color: const Color(0xFFE4E4E4),
        width: double.infinity,
        height: double.infinity,
      ),
    );
  }
}
