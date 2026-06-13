import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_theme_extension.dart';
import '../theme/tokens/app_tokens.dart';

/// A standardized modal dialog consuming the design token system.
///
/// Structure (top to bottom):
/// - **Header**: a title (text lg, weight w600), an optional subtitle (text sm,
///   secondary color), and a trailing close icon button.
/// - **Content**: caller-provided body. Becomes scrollable when it would
///   otherwise overflow the available viewport height, while the header and
///   footer stay fixed.
/// - **Footer**: right-aligned [actions] (typically `WButton`s) separated by a
///   12px gap. Hidden entirely when [actions] is empty.
///
/// The card has a maximum width of 560px, an `xl` border radius (12px), and a
/// consistent 24px internal padding on every region. All colors, radii,
/// typography, and spacing are sourced from [AppTokens]; no hardcoded visual
/// values are used.
///
/// Use [WDialog.show] to present the dialog with the correct backdrop and
/// fade-in / fade-out animations.
class WDialog extends StatefulWidget {
  /// Header title text. Rendered at [TypographyTokens.lg] with weight w600.
  final String title;

  /// Optional header subtitle. Rendered at [TypographyTokens.sm] in the
  /// secondary text color beneath the [title].
  final String? subtitle;

  /// The body of the dialog. Placed in a scrollable region so the header and
  /// footer remain fixed when the content overflows.
  final Widget content;

  /// Right-aligned footer actions, separated by a 12px gap. When empty, the
  /// footer is omitted.
  final List<Widget> actions;

  /// Invoked when the close icon button is tapped. Defaults to popping the
  /// current route when `null`.
  final VoidCallback? onClose;

  /// Fixed maximum width of the dialog card, per the component spec.
  static const double maxWidth = 560;

  /// Fade-in animation duration applied when the dialog is opened.
  static const Duration fadeInDuration = Duration(milliseconds: 200);

  /// Fade-out animation duration applied when the dialog is dismissed.
  static const Duration fadeOutDuration = Duration(milliseconds: 150);

  /// Backdrop color: black at 40% alpha.
  static final Color barrierColor = Colors.black.withValues(alpha: 0.4);

  const WDialog({
    super.key,
    required this.title,
    this.subtitle,
    required this.content,
    this.actions = const [],
    this.onClose,
  });

  /// Presents a [WDialog] using a [PopupRoute] with distinct enter/exit
  /// durations.
  ///
  /// Applies the standardized backdrop (black at 40% alpha), a fade-in of
  /// [fadeInDuration] (200ms) and fade-out of [fadeOutDuration] (150ms), both
  /// with an `easeInOut` curve. The backdrop is dismissible by default
  /// ([barrierDismissible]); tapping it or the close icon button dismisses the
  /// dialog. Content that exceeds the viewport height becomes scrollable.
  ///
  /// Returns the value the dialog was popped with, if any.
  static Future<T?> show<T>({
    required BuildContext context,
    required String title,
    required Widget content,
    String? subtitle,
    List<Widget> actions = const [],
    bool barrierDismissible = true,
  }) {
    return Navigator.of(context).push<T>(
      _WDialogRoute<T>(
        barrierDismissible: barrierDismissible,
        barrierDismissLabel:
            MaterialLocalizations.of(context).modalBarrierDismissLabel,
        builder: (dialogContext) => WDialog(
          title: title,
          subtitle: subtitle,
          content: content,
          actions: actions,
          onClose: () => Navigator.of(dialogContext).pop(),
        ),
      ),
    );
  }

  @override
  State<WDialog> createState() => _WDialogState();
}

class _WDialogState extends State<WDialog> {
  /// Scope node that constrains keyboard Tab traversal to the dialog's
  /// focusable descendants (Requirement 20.6 — focus trap). `_WDialogRoute`
  /// (a [PopupRoute]) restores focus to the triggering element on close.
  final FocusScopeNode _scopeNode = FocusScopeNode(debugLabel: 'WDialog');

  @override
  void dispose() {
    _scopeNode.dispose();
    super.dispose();
  }

  void _handleClose() {
    if (widget.onClose != null) {
      widget.onClose!();
    } else {
      Navigator.of(context).maybePop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typography = context.tokens.typography;

    // Requirement 20.2 & 20.6: Escape closes the dialog, and Tab cycling is
    // constrained to the dialog content. `FocusScope.autofocus` moves focus to
    // the first focusable element inside the dialog when it opens.
    return Shortcuts(
      shortcuts: const <ShortcutActivator, Intent>{
        SingleActivator(LogicalKeyboardKey.escape): DismissIntent(),
      },
      child: Actions(
        actions: <Type, Action<Intent>>{
          DismissIntent: CallbackAction<DismissIntent>(
            onInvoke: (_) {
              _handleClose();
              return null;
            },
          ),
        },
        child: FocusScope(
          node: _scopeNode,
          autofocus: true,
          child: Center(
            child: Padding(
              // Keep the card clear of the viewport edges on small screens.
              padding: const EdgeInsets.all(SpacingTokens.xxl),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: WDialog.maxWidth),
                child: Material(
                  color: colors.surface,
                  borderRadius: RadiusTokens.borderRadiusXl,
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildHeader(context, colors, typography),
                      // Fixed header/footer with a scrollable content region.
                      Flexible(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(
                            horizontal: SpacingTokens.xxl,
                          ),
                          child: widget.content,
                        ),
                      ),
                      if (widget.actions.isNotEmpty) _buildFooter(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Builds the fixed header: title + optional subtitle on the left, close
  /// icon button on the right.
  Widget _buildHeader(
    BuildContext context,
    ColorTokens colors,
    TypographyTokens typography,
  ) {
    return Padding(
      padding: const EdgeInsets.all(SpacingTokens.xxl),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Requirement 20.5/20.6: expose the title as the dialog's
                // accessible heading (namesRoute) so screen readers announce it
                // when the dialog opens.
                Semantics(
                  header: true,
                  namesRoute: true,
                  child: Text(
                    widget.title,
                    style: typography.style(
                      size: TypographyTokens.lg,
                      weight: TypographyTokens.semibold,
                      color: colors.textPrimary,
                    ),
                  ),
                ),
                if (widget.subtitle != null) ...[
                  const SizedBox(height: SpacingTokens.xs),
                  Text(
                    widget.subtitle!,
                    style: typography.style(
                      size: TypographyTokens.sm,
                      color: colors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: SpacingTokens.sm),
          IconButton(
            onPressed: _handleClose,
            icon: const Icon(Icons.close),
            iconSize: 20,
            color: colors.textSecondary,
            tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
            // Keep a 44x44 hit target for the close affordance (Req 20.3).
            constraints: const BoxConstraints(
              minWidth: 44,
              minHeight: 44,
            ),
            splashRadius: 22,
          ),
        ],
      ),
    );
  }

  /// Builds the fixed footer: right-aligned [WDialog.actions] separated by a
  /// 12px gap.
  Widget _buildFooter() {
    return Padding(
      padding: const EdgeInsets.all(SpacingTokens.xxl),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: _withGaps(widget.actions, SpacingTokens.md),
      ),
    );
  }

  /// Interleaves a horizontal gap of [gap] logical pixels between [children].
  List<Widget> _withGaps(List<Widget> children, double gap) {
    if (children.length <= 1) return children;
    return [
      for (var i = 0; i < children.length; i++) ...[
        if (i > 0) SizedBox(width: gap),
        children[i],
      ],
    ];
  }
}

/// A [PopupRoute] for [WDialog] that supports distinct enter/exit durations.
///
/// Unlike `showGeneralDialog`/`RawDialogRoute` (whose
/// `reverseTransitionDuration` is locked to `transitionDuration`), this route
/// overrides both [transitionDuration] (fade-in, 200ms) and
/// [reverseTransitionDuration] (fade-out, 150ms) independently, and applies a
/// fade transition with an `easeInOut` curve over the standardized backdrop.
class _WDialogRoute<T> extends PopupRoute<T> {
  _WDialogRoute({
    required this.builder,
    required bool barrierDismissible,
    required String barrierDismissLabel,
  })  : _barrierDismissible = barrierDismissible,
        _barrierLabel = barrierDismissLabel;

  final WidgetBuilder builder;
  final bool _barrierDismissible;
  final String _barrierLabel;

  @override
  Color get barrierColor => WDialog.barrierColor;

  @override
  bool get barrierDismissible => _barrierDismissible;

  @override
  String get barrierLabel => _barrierLabel;

  @override
  Duration get transitionDuration => WDialog.fadeInDuration;

  @override
  Duration get reverseTransitionDuration => WDialog.fadeOutDuration;

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    return Semantics(
      scopesRoute: true,
      explicitChildNodes: true,
      child: builder(context),
    );
  }

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return FadeTransition(
      opacity: CurvedAnimation(parent: animation, curve: Curves.easeInOut),
      child: child,
    );
  }
}
