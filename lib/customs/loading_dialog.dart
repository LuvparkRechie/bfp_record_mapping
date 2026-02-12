import 'package:bfp_record_mapping/screens/app_theme.dart';
import 'package:flutter/material.dart';

class LuvDialog extends StatefulWidget {
  // Core properties
  final String title;
  final String? subtitle;
  final Widget? icon;
  final Widget? logo;
  final Color? headerColor;
  final Color? backgroundColor;
  final Color? confirmButtonColor;
  final Color? cancelButtonColor;
  final double borderRadius;
  final EdgeInsets margin;

  // Content
  final List<DialogDetailItem> details;
  final Widget? customContent;

  // Actions
  final String confirmButtonText;
  final String cancelButtonText;
  final VoidCallback? onConfirm;
  final VoidCallback? onCancel;
  final bool showConfirmButton;
  final bool showCancelButton;
  final Widget? customActionButtons;

  // Animation
  final Duration animationDuration;
  final Curve animationCurve;
  final bool? canPop;

  const LuvDialog({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    this.logo,
    this.headerColor,
    this.backgroundColor = Colors.white,
    this.confirmButtonColor,
    this.cancelButtonColor,
    this.borderRadius = 20.0,
    this.margin = const EdgeInsets.all(20.0),
    this.details = const [],
    this.customContent,
    this.confirmButtonText = 'Confirm',
    this.cancelButtonText = 'Cancel',
    this.onConfirm,
    this.onCancel,
    this.showConfirmButton = true,
    this.showCancelButton = true,
    this.customActionButtons,
    this.animationDuration = const Duration(milliseconds: 500),
    this.animationCurve = Curves.easeOutBack,
    this.canPop,
  });

  @override
  State<LuvDialog> createState() => _LuvDialogState();
}

class DialogDetailItem {
  final String title;
  final String value;
  final Widget? customValue;

  DialogDetailItem({
    required this.title,
    required this.value,
    this.customValue,
  });
}

class _LuvDialogState extends State<LuvDialog> with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: widget.animationCurve),
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final headerColor = widget.headerColor ?? theme.primaryColor;
    final confirmButtonColor = widget.confirmButtonColor ?? headerColor;
    final cancelButtonColor = widget.cancelButtonColor ?? theme.disabledColor;

    return PopScope(
      canPop: widget.canPop ?? true,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Opacity(
            opacity: _fadeAnimation.value,
            child: Transform.scale(scale: _scaleAnimation.value, child: child),
          );
        },
        child: Container(
          margin: widget.margin,
          decoration: BoxDecoration(
            color: widget.backgroundColor,
            borderRadius: BorderRadius.circular(widget.borderRadius),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header Section
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: headerColor,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(widget.borderRadius),
                    topRight: Radius.circular(widget.borderRadius),
                  ),
                ),
                child: Column(
                  children: [
                    // Logo (if provided)
                    if (widget.logo != null) ...[
                      widget.logo!,
                      const SizedBox(height: 16),
                    ],

                    // Icon (if provided, defaults to check icon)
                    widget.icon ??
                        Icon(
                          Icons.check_circle_rounded,
                          color: Colors.white,
                          size: 48,
                        ),
                    const SizedBox(height: 16),

                    // Title
                    Text(
                      widget.title,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    // Subtitle (if provided)
                    if (widget.subtitle != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        widget.subtitle!,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.white70,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ],
                ),
              ),

              // Content Section
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    // Custom content or details list
                    if (widget.customContent != null)
                      widget.customContent!
                    else if (widget.details.isNotEmpty)
                      ...widget.details
                          .map(
                            (detail) => _buildDetailRow(
                              detail.title,
                              detail.value,
                              detail.customValue,
                            ),
                          )
                          .toList(),

                    const SizedBox(height: 24),

                    // Action buttons
                    if (widget.customActionButtons != null)
                      widget.customActionButtons!
                    else
                      _buildActionButtons(
                        confirmButtonColor,
                        cancelButtonColor,
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String title, String value, Widget? customValue) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.grey,
            ),
          ),
          if (customValue != null)
            customValue
          else
            Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(Color confirmColor, Color cancelColor) {
    return Row(
      children: [
        // Cancel Button
        if (widget.showCancelButton && widget.onCancel != null) ...[
          Expanded(
            child: OutlinedButton(
              onPressed: widget.onCancel,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                side: BorderSide(color: cancelColor),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                widget.cancelButtonText,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: cancelColor,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
        ],

        // Confirm Button
        if (widget.showConfirmButton && widget.onConfirm != null)
          Expanded(
            child: Material(
              borderRadius: BorderRadius.circular(10),
              color: confirmColor,
              child: InkWell(
                onTap: widget.onConfirm,
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: confirmColor.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      widget.confirmButtonText,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// -------------------Loading Dialog ------------------
class LoadingDialog {
  // Show loading dialog

  static void show({
    String title = 'Loading',
    String message = 'Please wait...',
    bool canPop = true,
    BuildContext? context,
  }) {
    showDialog(
      context: context!,
      builder: (context) {
        return PopScope(
          canPop: true,
          child: Dialog(
            backgroundColor: Colors.transparent,
            elevation: 0,
            child: _LoadingContent(title: title, message: message),
          ),
        );
      },
    );
  }
}

class _LoadingContent extends StatefulWidget {
  final String title;
  final String message;

  const _LoadingContent({required this.title, required this.message});

  @override
  State<_LoadingContent> createState() => __LoadingContentState();
}

class __LoadingContentState extends State<_LoadingContent>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();

    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.linear));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Rotating Spinner
          AnimatedBuilder(
            animation: _rotationAnimation,
            builder: (context, child) {
              return Transform.rotate(
                angle: _rotationAnimation.value * 2 * 3.14159,
                child: child,
              );
            },
            child: Container(
              width: 60,
              height: 60,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.primaryRed.withOpacity(0.2),
                  width: 3,
                ),
              ),
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryRed),
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Title
          Text(
            widget.title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),

            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 8),

          // Message
          Text(
            widget.message,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.black54,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
