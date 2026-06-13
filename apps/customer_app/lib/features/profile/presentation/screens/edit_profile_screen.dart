import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/popups/loaders.dart';
import '../../../../core/utils/validators/validation.dart';
import '../../../../core/widgets/buttons/app_button.dart';
import '../../../../core/widgets/inputs/app_text_field.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/profile_repository.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _emailController;
  bool _saving = false;
  bool _uploadingAvatar = false;
  String? _avatarUrl;

  @override
  void initState() {
    super.initState();
    final user = ref.read(currentUserProvider);
    _nameController = TextEditingController(text: user?.fullName ?? '');
    _phoneController = TextEditingController();
    _emailController = TextEditingController(text: user?.email ?? '');
    _avatarUrl = user?.avatarUrl;
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    try {
      final user = await ref.read(profileRepositoryProvider).getMe();
      if (!mounted) return;
      _nameController.text = user.fullName ?? '';
      _emailController.text = user.email ?? '';
      setState(() => _avatarUrl = user.avatarUrl);
      ref.read(currentUserProvider.notifier).state = user.toEntity();
    } catch (_) {}
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadAvatar() async {
    if (_uploadingAvatar) return;
    final picker = ImagePicker();
    final file = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );
    if (file == null) return;

    setState(() => _uploadingAvatar = true);
    try {
      final url = await ref
          .read(profileRepositoryProvider)
          .uploadAvatar(File(file.path));
      final user = await ref.read(profileRepositoryProvider).updateProfile(
            fullName: _nameController.text.trim(),
            avatarUrl: url,
          );
      ref.read(currentUserProvider.notifier).state = user.toEntity();
      if (mounted) {
        setState(() => _avatarUrl = url);
        AppLoaders.successSnackBar(
          context,
          title: 'Photo updated',
          message: 'Your profile photo was saved.',
        );
      }
    } catch (e) {
      if (mounted) {
        AppLoaders.errorSnackBar(
          context,
          title: 'Upload failed',
          message: '$e',
        );
      }
    } finally {
      if (mounted) setState(() => _uploadingAvatar = false);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final user = await ref.read(profileRepositoryProvider).updateProfile(
            fullName: _nameController.text.trim(),
            phone: _phoneController.text.trim().isEmpty
                ? null
                : _phoneController.text.trim(),
            avatarUrl: _avatarUrl,
          );
      ref.read(currentUserProvider.notifier).state = user.toEntity();
      if (mounted) {
        AppLoaders.successSnackBar(context, title: 'Saved', message: 'Profile updated');
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        AppLoaders.errorSnackBar(context, title: 'Update failed', message: '$e');
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final initial = (user?.fullName ?? user?.email ?? 'U').substring(0, 1).toUpperCase();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Iconsax.arrow_left_2, color: Colors.black),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Edit Profile',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.primary.withValues(alpha: 0.2), width: 2),
                        ),
                        child: CircleAvatar(
                          radius: 54,
                          backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                          backgroundImage: _avatarUrl != null && _avatarUrl!.isNotEmpty
                              ? CachedNetworkImageProvider(_avatarUrl!)
                              : null,
                          child: _avatarUrl != null && _avatarUrl!.isNotEmpty
                              ? null
                              : Text(
                                  initial,
                                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                        ),
                      ),
                      GestureDetector(
                        onTap: _uploadingAvatar ? null : _pickAndUploadAvatar,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 3),
                          ),
                          child: _uploadingAvatar
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Iconsax.camera, color: Colors.white, size: 18),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
                AppTextField(
                  controller: _nameController,
                  label: 'Full Name',
                  prefixIcon: const Icon(Iconsax.user, size: 20, color: AppColors.textSecondary),
                  validator: (v) => AppValidator.validateEmptyText('Name', v),
                ),
                const SizedBox(height: 20),
                AppTextField(
                  controller: _emailController,
                  label: 'Email Address',
                  readOnly: true,
                  prefixIcon: const Icon(Iconsax.sms, size: 20, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 20),
                AppTextField(
                  controller: _phoneController,
                  label: 'Phone Number',
                  keyboardType: TextInputType.phone,
                  prefixIcon: const Icon(Iconsax.call, size: 20, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 48),
                AppButton(
                  label: 'Save Changes',
                  isLoading: _saving,
                  onPressed: _saving ? null : _save,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
