import 'dart:io';
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:trydos_wallet/src/constent/assets.dart';
import 'package:trydos_wallet/src/constent/build_context.dart';
import 'package:trydos_wallet/src/constent/styles.dart';
import 'package:trydos_wallet/src/constent/theme/typography.dart';
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
  String? _savedImagePath;
  String? _draftImagePath;
  bool _draftRemove = false;
  bool _showActions = false;

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

  Future<bool> _ensurePermission(ImageSource source) async {
    if (source == ImageSource.camera) {
      final status = await Permission.camera.request();
      if (status.isGranted) return true;
      if (!mounted) return false;
      _showPermissionError('permission_camera_required');
      return false;
    }

    if (Platform.isIOS) {
      final status = await Permission.photos.request();
      if (status.isGranted || status.isLimited) return true;
      if (!mounted) return false;
      _showPermissionError('permission_gallery_required');
      return false;
    }

    // Android 13+ usually uses photos permission; lower versions may still require storage.
    final photosStatus = await Permission.photos.request();
    if (photosStatus.isGranted || photosStatus.isLimited) return true;

    final storageStatus = await Permission.storage.request();
    if (storageStatus.isGranted) return true;

    if (!mounted) return false;
    _showPermissionError('permission_gallery_required');
    return false;
  }

  void _showPermissionError(String key) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppStrings.get(widget.languageCode, key))),
    );
  }

  Future<void> _openPickerSlider(ImageSource source) async {
    final hasPermission = await _ensurePermission(source);
    if (!hasPermission) return;

    String? selectedPath;
    if (source == ImageSource.camera) {
      selectedPath = await _openCameraSlider();
    } else {
      selectedPath = await _openGallerySlider();
    }

    if (selectedPath == null || selectedPath.isEmpty) return;

    final cropped = await _openPreviewCropSlider(selectedPath);
    if (cropped == null || cropped.isEmpty) return;

    if (!mounted) return;
    setState(() {
      _draftImagePath = cropped;
      _draftRemove = false;
      _showActions = false;
    });
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

  Future<String?> _openGallerySlider() async {
    if (!mounted) return null;
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final height = MediaQuery.of(context).size.height * 0.90;
        return SizedBox(
          height: height,
          child: _GallerySheet(languageCode: widget.languageCode),
        );
      },
    );
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

  void _markRemove() {
    setState(() {
      _draftRemove = true;
      _draftImagePath = null;
      _showActions = false;
    });
  }

  void _saveChanges() {
    final updatedPath = _draftRemove
        ? ''
        : (_draftImagePath ?? _savedImagePath ?? '');

    TrydosWallet.updateUserInfo(profileImageUrl: updatedPath);

    setState(() {
      _savedImagePath = updatedPath.isEmpty ? null : updatedPath;
      _draftImagePath = null;
      _draftRemove = false;
      _showActions = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                  InkWell(
                    onTap: () => Navigator.of(context).pop(),
                    child: SvgPicture.asset(
                      TrydosWalletAssets.back,
                      package: TrydosWalletStyles.packageName,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    AppStrings.get(widget.languageCode, 'profile_photo'),
                    textAlign: TextAlign.center,
                    style: context.textTheme.bodyMedium?.mq.copyWith(
                      fontSize: 16.sp,
                      color: const Color(0xFF1D1D1D),
                    ),
                  ),
                  const Spacer(),
                  _hasUnsavedChanges
                      ? SizedBox(
                          width: 42.w,
                          child: InkWell(
                            onTap: _saveChanges,
                            borderRadius: BorderRadius.circular(8.r),
                            child: Text(
                              AppStrings.get(widget.languageCode, 'save'),
                              textAlign: TextAlign.end,
                              style: context.textTheme.bodyMedium?.mq.copyWith(
                                color: const Color(0xFF388CFF),
                                fontSize: 16.sp,
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
                      child: _hasImage
                          ? Image.file(
                              File(_displayImagePath!),
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  _GrayAvatarPlaceholder(),
                            )
                          : _GrayAvatarPlaceholder(),
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
                    onTap: () => _openPickerSlider(ImageSource.gallery),
                  ),
                  SizedBox(width: 40.w),
                  _ActionIcon(
                    label: AppStrings.get(widget.languageCode, 'take_photo'),
                    assetPath: TrydosWalletAssets.takePhoto,
                    onTap: () => _openPickerSlider(ImageSource.camera),
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
    if (!mounted) return;
    Navigator.of(context).pop(file.path);
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
                color: const Color(0xFF1D1D1D),
              ),
            ),
            SizedBox(height: 14.h),
            Container(
              margin: EdgeInsets.symmetric(horizontal: 20.w),
              height: 500.h,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(20.r),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20.r),
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : (_controller != null && _controller!.value.isInitialized)
                    ? CameraPreview(_controller!)
                    : Center(
                        child: Text(
                          AppStrings.get(
                            widget.languageCode,
                            'camera_unavailable',
                          ),
                          style: const TextStyle(color: Colors.white),
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

  @override
  void initState() {
    super.initState();
    _currentPath = widget.initialPath;
  }

  Future<void> _cropCurrent() async {
    final cropped = await ImageCropper().cropImage(
      sourcePath: _currentPath,
      aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Crop',
          lockAspectRatio: true,
          hideBottomControls: false,
        ),
        IOSUiSettings(
          title: 'Crop',
          aspectRatioLockEnabled: true,
          resetAspectRatioEnabled: false,
        ),
      ],
    );

    if (cropped == null) return;

    if (!mounted) return;
    setState(() {
      _currentPath = cropped.path;
    });
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
                color: const Color(0xFF1D1D1D),
              ),
            ),
            SizedBox(height: 14.h),
            Expanded(
              child: Container(
                margin: EdgeInsets.symmetric(horizontal: 20.w),
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(20.r),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20.r),
                  child: Image.file(
                    File(_currentPath),
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                  ),
                ),
              ),
            ),
            SizedBox(height: 14.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                InkWell(
                  onTap: _cropCurrent,
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
                    child: Text(
                      AppStrings.get(widget.languageCode, 'crop'),
                      style: context.textTheme.bodyMedium?.mq.copyWith(
                        color: const Color(0xFF1D1D1D),
                        fontSize: 13.sp,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 14.w),
                InkWell(
                  onTap: () => Navigator.of(context).pop(_currentPath),
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

class _GallerySheet extends StatefulWidget {
  const _GallerySheet({required this.languageCode});

  final String languageCode;

  @override
  State<_GallerySheet> createState() => _GallerySheetState();
}

class _GallerySheetState extends State<_GallerySheet> {
  List<AssetEntity> _assets = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadAssets();
  }

  Future<void> _loadAssets() async {
    setState(() => _loading = true);

    try {
      final albums = await PhotoManager.getAssetPathList(
        onlyAll: true,
        type: RequestType.image,
      );

      if (albums.isEmpty) {
        setState(() => _loading = false);
        return;
      }

      final recentAssets = await albums[0].getAssetListRange(
        start: 0,
        end: 1000,
      );

      if (!mounted) return;
      setState(() {
        _assets = recentAssets;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _selectAsset(AssetEntity asset) async {
    final file = await asset.file;
    if (file == null) return;
    if (!mounted) return;
    Navigator.of(context).pop(file.path);
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
              AppStrings.get(widget.languageCode, 'choose'),
              style: context.textTheme.bodyMedium?.mq.copyWith(
                fontSize: 16.sp,
                color: const Color(0xFF1D1D1D),
              ),
            ),
            SizedBox(height: 14.h),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : (_assets.isEmpty
                        ? Center(
                            child: Text(
                              AppStrings.get(widget.languageCode, 'no_photos'),
                              style: const TextStyle(color: Color(0xFF808080)),
                            ),
                          )
                        : GridView.builder(
                            padding: EdgeInsets.all(12.w),
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 3,
                                  crossAxisSpacing: 8.w,
                                  mainAxisSpacing: 8.w,
                                ),
                            itemCount: _assets.length,
                            itemBuilder: (context, index) {
                              final asset = _assets[index];
                              return GestureDetector(
                                onTap: () => _selectAsset(asset),
                                child: FutureBuilder<Uint8List?>(
                                  future: asset.thumbnailDataWithSize(
                                    const ThumbnailSize(200, 200),
                                  ),
                                  builder: (context, snapshot) {
                                    if (snapshot.connectionState ==
                                        ConnectionState.done) {
                                      if (snapshot.data != null) {
                                        return ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            12.r,
                                          ),
                                          child: Image.memory(
                                            snapshot.data!,
                                            fit: BoxFit.cover,
                                          ),
                                        );
                                      }
                                    }
                                    return ClipRRect(
                                      borderRadius: BorderRadius.circular(12.r),
                                      child: Container(
                                        color: const Color(0xFFE8E8E8),
                                        child: const Center(
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              );
                            },
                          )),
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
