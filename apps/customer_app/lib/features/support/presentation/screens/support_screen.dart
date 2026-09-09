import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/popups/loaders.dart';
import '../../../../core/widgets/buttons/app_button.dart';
import '../../../../core/widgets/inputs/app_text_field.dart';
import '../../data/support_repository.dart';

class SupportScreen extends ConsumerStatefulWidget {
  const SupportScreen({super.key, this.orderId});

  final String? orderId;

  @override
  ConsumerState<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends ConsumerState<SupportScreen> {
  final _formKey = GlobalKey<FormState>();
  final _subjectController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _type = 'COMPLAINT';
  bool _submitting = false;

  @override
  void dispose() {
    _subjectController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (widget.orderId == null) {
      AppLoaders.warningSnackBar(
        context,
        title: 'Order required',
        message: 'Open support from an order detail page.',
      );
      return;
    }
    if (!_formKey.currentState!.validate()) return;

    setState(() => _submitting = true);
    try {
      await ref.read(supportRepositoryProvider).createComplaint({
        'orderId': widget.orderId,
        'type': _type,
        'subject': _subjectController.text.trim(),
        'description': _descriptionController.text.trim(),
      });
      if (mounted) {
        AppLoaders.successSnackBar(
          context,
          title: 'Submitted',
          message: 'We will get back to you soon.',
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        AppLoaders.errorSnackBar(context, title: 'Failed', message: '$e');
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Help & support')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (widget.orderId != null)
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  ),
                  child: Text(
                    'Order ID: ${widget.orderId}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
              const SizedBox(height: 20),
              DropdownButtonFormField<String>(
                initialValue: _type,
                decoration: const InputDecoration(labelText: 'Issue type'),
                items: const [
                  DropdownMenuItem(value: 'COMPLAINT', child: Text('Complaint')),
                  DropdownMenuItem(
                    value: 'REFUND_REQUEST',
                    child: Text('Refund request'),
                  ),
                ],
                onChanged: (v) {
                  if (v != null) setState(() => _type = v);
                },
              ),
              const SizedBox(height: 16),
              AppTextField(
                controller: _subjectController,
                label: 'Subject',
                validator: (v) =>
                    v == null || v.trim().length < 3 ? 'Min 3 characters' : null,
              ),
              const SizedBox(height: 16),
              AppTextField(
                controller: _descriptionController,
                label: 'Description',
                maxLines: 5,
                validator: (v) =>
                    v == null || v.trim().length < 10 ? 'Min 10 characters' : null,
              ),
              const SizedBox(height: 24),
              AppButton(
                label: 'Submit',
                isLoading: _submitting,
                onPressed: _submitting ? null : _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
