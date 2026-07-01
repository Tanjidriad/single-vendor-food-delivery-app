import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';

/// Ticket-style coupon card (adapted from the Ionic Coupon App UI design)
/// themed to the app brand and driven by real backend coupon data.
///
/// Shows a vertical gradient "discount stub" with perforated notches, the
/// coupon code, a live savings / "spend more" line based on [subtotal], an
/// APPLY action, and an expandable MORE/LESS details section.
class CouponTicketCard extends StatefulWidget {
  const CouponTicketCard({
    super.key,
    required this.coupon,
    required this.subtotal,
    required this.isDark,
    this.isApplying = false,
    this.onApply,
  });

  /// Backend coupon map: code, description, discountType, discountValue,
  /// minOrderAmount, endsAt.
  final Map<String, dynamic> coupon;

  /// Current cart subtotal — used to compute savings and applicability.
  final double subtotal;
  final bool isDark;
  final bool isApplying;
  final VoidCallback? onApply;

  @override
  State<CouponTicketCard> createState() => _CouponTicketCardState();
}

class _CouponTicketCardState extends State<CouponTicketCard> {
  bool _expanded = false;

  static const double _stubWidth = 52;
  static const double _notchRadius = 9;

  @override
  Widget build(BuildContext context) {
    final coupon = widget.coupon;
    final code = coupon['code'] as String;
    final type = coupon['discountType'] as String;
    final value = (coupon['discountValue'] as num).toDouble();
    final minOrder = (coupon['minOrderAmount'] as num?)?.toDouble() ?? 0;
    final description = coupon['description'] as String?;
    final endsAt = coupon['endsAt'] as String?;

    final isPercent = type == 'PERCENT';
    final applicable = widget.subtotal >= minOrder;
    final savings = isPercent ? widget.subtotal * value / 100 : value;
    final shortfall = minOrder - widget.subtotal;

    final stubLabel =
        isPercent ? '${value.toInt()}% OFF' : '৳${value.toStringAsFixed(0)} OFF';

    // Colour the notch cut-outs to match the surface behind the card so they
    // read as holes punched through the ticket.
    final backdrop = widget.isDark ? AppColors.background : Colors.white;
    final cardSurface = widget.isDark ? AppColors.black400 : AppColors.surface;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // ── Card body ────────────────────────────────────────────────
        Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: cardSurface,
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            border: Border.all(
              color: widget.isDark
                  ? Colors.white.withValues(alpha: 0.1)
                  : AppColors.primary.withValues(alpha: 0.4),
              width: 1.5,
            ),
            boxShadow: [
              if (!widget.isDark)
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.06),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
            ],
          ),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildStub(stubLabel, applicable),
                Expanded(
                  child: _buildDetails(
                    context,
                    code: code,
                    applicable: applicable,
                    savings: savings,
                    shortfall: shortfall,
                    minOrder: minOrder,
                    description: description,
                    endsAt: endsAt,
                  ),
                ),
              ],
            ),
          ),
        ),

        // ── Perforated notches at the seam ───────────────────────────
        Positioned(
          left: _stubWidth - _notchRadius,
          top: -_notchRadius,
          child: _Notch(color: backdrop, radius: _notchRadius),
        ),
        Positioned(
          left: _stubWidth - _notchRadius,
          bottom: -_notchRadius,
          child: _Notch(color: backdrop, radius: _notchRadius),
        ),
      ],
    );
  }

  Widget _buildStub(String label, bool applicable) {
    return SizedBox(
      width: _stubWidth,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: applicable
              ? const LinearGradient(
                  colors: [AppColors.primary700, AppColors.primary500],
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                )
              : null,
          color: applicable ? null : AppColors.gray700,
        ),
        child: Center(
          child: RotatedBox(
            quarterTurns: 3,
            child: Text(
              label,
              maxLines: 1,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 14,
                letterSpacing: 1.1,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetails(
    BuildContext context, {
    required String code,
    required bool applicable,
    required double savings,
    required double shortfall,
    required double minOrder,
    required String? description,
    required String? endsAt,
  }) {
    final textTheme = Theme.of(context).textTheme;
    final hasDetails = (description != null && description.isNotEmpty) ||
        minOrder > 0 ||
        endsAt != null;

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      code,
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1,
                        color: widget.isDark ? Colors.white : AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      applicable
                          ? 'Save ৳${savings.toStringAsFixed(0)} on this order'
                          : 'Add ৳${shortfall.toStringAsFixed(0)} more to avail',
                      style: textTheme.bodySmall?.copyWith(
                        color: applicable
                            ? AppColors.success
                            : (widget.isDark ? Colors.white54 : Colors.black54),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              _buildApplyButton(applicable),
            ],
          ),
          if (hasDetails) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 10),
              child: _DashedLine(),
            ),
            if (description != null && description.isNotEmpty)
              Text(
                description,
                maxLines: _expanded ? null : 1,
                overflow: _expanded ? null : TextOverflow.ellipsis,
                style: textTheme.bodySmall?.copyWith(
                  color: widget.isDark ? AppColors.white700 : AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            if (_expanded) ...[
              if (minOrder > 0)
                _detailLine('Min. order ৳${minOrder.toStringAsFixed(0)}'),
              if (endsAt != null) _detailLine('Valid till ${_formatDate(endsAt)}'),
            ],
            const SizedBox(height: 6),
            InkWell(
              onTap: () => setState(() => _expanded = !_expanded),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _expanded ? Icons.remove : Icons.add,
                    size: 15,
                    color: widget.isDark ? Colors.white54 : Colors.black45,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _expanded ? 'LESS' : 'MORE',
                    style: TextStyle(
                      color: widget.isDark ? Colors.white54 : Colors.black45,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildApplyButton(bool applicable) {
    if (widget.isApplying) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 12),
        child: SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
        ),
      );
    }
    return TextButton(
      onPressed: applicable ? widget.onApply : null,
      style: TextButton.styleFrom(
        foregroundColor: AppColors.primary,
        disabledForegroundColor: widget.isDark ? Colors.white24 : AppColors.gray700,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        minimumSize: const Size(0, 36),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: const Text(
        'APPLY',
        style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 0.5),
      ),
    );
  }

  Widget _detailLine(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          color: widget.isDark ? Colors.white38 : Colors.black45,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  String _formatDate(String iso) {
    final d = DateTime.tryParse(iso);
    if (d == null) return iso;
    return '${d.day} ${_months[d.month - 1]} ${d.year}';
  }
}

/// A circular cut-out drawn over the ticket seam.
class _Notch extends StatelessWidget {
  const _Notch({required this.color, required this.radius});

  final Color color;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: radius * 2,
      height: radius * 2,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

/// A horizontal dashed divider that fills its available width.
class _DashedLine extends StatelessWidget {
  const _DashedLine();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const dashWidth = 5.0;
        const gap = 4.0;
        final count = (constraints.maxWidth / (dashWidth + gap)).floor();
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(
            count,
            (_) => Container(
              width: dashWidth,
              height: 1,
              color: Colors.grey.withValues(alpha: 0.45),
            ),
          ),
        );
      },
    );
  }
}
