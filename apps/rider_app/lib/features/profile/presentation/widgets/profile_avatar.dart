import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/widgets/feedback/success_snack.dart';
import '../../data/rider_profile_repository.dart';
import '../providers/rider_profile_provider.dart';

/// Tappable rider avatar with optional online dot and camera badge.
class ProfileAvatar extends ConsumerStatefulWidget {
  const ProfileAvatar({
    super.key,
    required this.fullName,
    this.avatarUrl,
    this.radius = 32,
    this.showOnlineDot = false,
    this.isOnline = false,
    this.showCameraBadge = true,
    this.onPhotoUpdated,
  });

  final String fullName;
  final String? avatarUrl;
  final double radius;
  final bool showOnlineDot;
  final bool isOnline;
  final bool showCameraBadge;
  final VoidCallback? onPhotoUpdated;

  @override
  ConsumerState<ProfileAvatar> createState() => _ProfileAvatarState();
}

class _ProfileAvatarState extends ConsumerState<ProfileAvatar> {
  bool _uploading = false;
  String? _localPreviewPath;

  String get _initial {
    final parts = widget.fullName.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return 'R';
    return parts.first.characters.first.toUpperCase();
  }

  String? get _remoteUrl {
    final url = widget.avatarUrl;
    if (url == null || url.isEmpty) return null;
    return url;
  }

  bool get _hasPhoto =>
      (_localPreviewPath != null && _localPreviewPath!.isNotEmpty) ||
      _remoteUrl != null;

  @override
  void didUpdateWidget(covariant ProfileAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.avatarUrl != widget.avatarUrl && !_uploading) {
      _localPreviewPath = null;
    }
  }

  Future<void> _pickAndUpload(ImageSource source) async {
    if (_uploading) return;

    final picked = await ImagePicker().pickImage(
      source: source,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );
    if (picked == null || !mounted) return;

    setState(() {
      _uploading = true;
      _localPreviewPath = picked.path;
    });

    try {
      await ref.read(riderProfileRepositoryProvider).updateProfilePhoto(
            filePath: picked.path,
            fileName: picked.name,
          );
      ref.invalidate(riderProfileProvider);
      if (!mounted) return;
      setState(() => _localPreviewPath = null);
      SuccessSnack.show(context, 'Profile photo updated');
      widget.onPhotoUpdated?.call();
    } catch (e) {
      if (mounted) {
        setState(() => _localPreviewPath = null);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: AppColors.offline,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _removePhoto() async {
    if (_uploading) return;
    setState(() => _uploading = true);
    try {
      await ref.read(riderProfileRepositoryProvider).removeProfilePhoto();
      ref.invalidate(riderProfileProvider);
      if (!mounted) return;
      setState(() => _localPreviewPath = null);
      SuccessSnack.show(context, 'Profile photo removed');
      widget.onPhotoUpdated?.call();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: AppColors.offline,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _showPhotoOptions() async {
    await showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xxl)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screen,
            AppSpacing.lg,
            AppSpacing.screen,
            AppSpacing.lg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Profile photo',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: AppSpacing.md),
              ListTile(
                leading: const Icon(LucideIcons.camera, color: AppColors.primary),
                title: const Text('Take photo'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _pickAndUpload(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(LucideIcons.image, color: AppColors.primary),
                title: const Text('Choose from gallery'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _pickAndUpload(ImageSource.gallery);
                },
              ),
              if (_hasPhoto)
                ListTile(
                  leading: const Icon(LucideIcons.trash2, color: AppColors.offline),
                  title: const Text('Remove photo'),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _removePhoto();
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatarContent(TextTheme textTheme) {
    if (_localPreviewPath != null) {
      return Image.file(
        File(_localPreviewPath!),
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
      );
    }
    final remote = _remoteUrl;
    if (remote != null) {
      return Image.network(
        remote,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return const Center(
            child: SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) => _initialsFallback(textTheme),
      );
    }
    return _initialsFallback(textTheme);
  }

  Widget _initialsFallback(TextTheme textTheme) {
    return Center(
      child: Text(
        _initial,
        style: textTheme.headlineSmall?.copyWith(
          color: AppColors.primary,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final diameter = widget.radius * 2;

    return GestureDetector(
      onTap: widget.showCameraBadge ? _showPhotoOptions : null,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: diameter,
            height: diameter,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primaryLight,
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
            ),
            clipBehavior: Clip.antiAlias,
            child: _buildAvatarContent(textTheme),
          ),
          if (_uploading)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.35),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          if (widget.showOnlineDot && widget.isOnline)
            Positioned(
              left: 0,
              bottom: 0,
              child: Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: AppColors.online,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.surfaceLight, width: 2),
                ),
              ),
            ),
          if (widget.showCameraBadge && !_uploading)
            Positioned(
              right: -2,
              bottom: -2,
              child: Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.surfaceLight, width: 2),
                ),
                child: const Icon(
                  LucideIcons.camera,
                  size: 13,
                  color: Colors.white,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
