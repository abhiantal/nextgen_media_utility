import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Visual style variants for [CustomTextField].
enum TextFieldVariant {
  /// Rounded outline border.
  outlined,

  /// Solid or tinted filled background.
  filled,

  /// Clean bottom border only.
  underline,

  /// Modern glassmorphic frosted appearance.
  glass,

  /// Minimal clean input with no border line.
  borderless,
}

/// A fully customizable, theme-responsive text field packed with built-in
/// clear buttons, password visibility toggles, glassmorphism, prefix/suffix widgets,
/// and factory presets for common workflows (email, password, search, multiline, phone).
class CustomTextField extends StatefulWidget {
  // Controllers & Focus
  final TextEditingController? controller;
  final FocusNode? focusNode;

  // Labels & Hints
  final String? label;
  final String? hintText;
  final String? hint; // Alias for hintText
  final String? helperText;
  final String? errorText;
  final String? prefixText;
  final String? suffixText;
  final String? counterText;

  // Icons & Custom Widgets
  final IconData? labelIcon;
  final IconData? prefixIcon;
  final IconData? suffixIcon;
  final Widget? prefix;
  final Widget? suffix;
  final VoidCallback? onSuffixIconTap;
  final VoidCallback? onPrefixIconTap;

  // Input Configuration
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final TextCapitalization textCapitalization;
  final TextDirection? textDirection;
  final TextAlign textAlign;
  final int? maxLines;
  final int? minLines;
  final int? maxLength;
  final bool obscureText;
  final bool autocorrect;
  final bool enableSuggestions;
  final bool readOnly;
  final bool enabled;
  final bool autofocus;
  final bool expands;

  // Validation & Formatting
  final List<TextInputFormatter>? inputFormatters;
  final String? Function(String?)? validator;
  final AutovalidateMode? autovalidateMode;

  // Callbacks
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onTap;
  final VoidCallback? onEditingComplete;

  // Visual Variant & Styling
  final TextFieldVariant variant;
  final TextStyle? style;
  final TextStyle? labelStyle;
  final TextStyle? hintStyle;
  final TextStyle? errorStyle;
  final TextStyle? helperStyle;
  final Color? fillColor;
  final Color? borderColor;
  final Color? focusedBorderColor;
  final Color? errorBorderColor;
  final Color? cursorColor;
  final double? cursorHeight;
  final double? cursorWidth;
  final Radius? cursorRadius;
  final EdgeInsetsGeometry? contentPadding;
  final BorderRadius? borderRadius;
  final double borderWidth;
  final double focusedBorderWidth;

  // Toggles & Flags
  final bool showBorder;
  final bool filled;
  final bool isDense;
  final bool showCounter;
  final bool required;
  final bool showClearButton;
  final bool showPasswordToggle;

  const CustomTextField({
    super.key,
    this.controller,
    this.focusNode,
    this.label,
    this.hintText,
    this.hint,
    this.helperText,
    this.errorText,
    this.prefixText,
    this.suffixText,
    this.counterText,
    this.labelIcon,
    this.prefixIcon,
    this.suffixIcon,
    this.prefix,
    this.suffix,
    this.onSuffixIconTap,
    this.onPrefixIconTap,
    this.keyboardType,
    this.textInputAction,
    this.textCapitalization = TextCapitalization.none,
    this.textDirection,
    this.textAlign = TextAlign.start,
    this.maxLines = 1,
    this.minLines,
    this.maxLength,
    this.obscureText = false,
    this.autocorrect = true,
    this.enableSuggestions = true,
    this.readOnly = false,
    this.enabled = true,
    this.autofocus = false,
    this.expands = false,
    this.inputFormatters,
    this.validator,
    this.autovalidateMode,
    this.onChanged,
    this.onSubmitted,
    this.onTap,
    this.onEditingComplete,
    this.variant = TextFieldVariant.outlined,
    this.style,
    this.labelStyle,
    this.hintStyle,
    this.errorStyle,
    this.helperStyle,
    this.fillColor,
    this.borderColor,
    this.focusedBorderColor,
    this.errorBorderColor,
    this.cursorColor,
    this.cursorHeight,
    this.cursorWidth,
    this.cursorRadius,
    this.contentPadding,
    this.borderRadius,
    this.borderWidth = 1.0,
    this.focusedBorderWidth = 2.0,
    this.showBorder = true,
    this.filled = false,
    this.isDense = false,
    this.showCounter = false,
    this.required = false,
    this.showClearButton = false,
    this.showPasswordToggle = false,
  });

  // --- FACTORY PRESETS ---

  /// Preset for email input with appropriate keyboard type, prefix icon, and autocapitalization.
  factory CustomTextField.email({
    Key? key,
    TextEditingController? controller,
    FocusNode? focusNode,
    String? label = 'Email Address',
    String? hintText = 'name@example.com',
    String? Function(String?)? validator,
    ValueChanged<String>? onChanged,
    ValueChanged<String>? onSubmitted,
    bool required = false,
    TextFieldVariant variant = TextFieldVariant.outlined,
  }) {
    return CustomTextField(
      key: key,
      controller: controller,
      focusNode: focusNode,
      label: label,
      hintText: hintText,
      prefixIcon: Icons.email_outlined,
      keyboardType: TextInputType.emailAddress,
      textInputAction: TextInputAction.next,
      autocorrect: false,
      enableSuggestions: true,
      textCapitalization: TextCapitalization.none,
      validator: validator,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      required: required,
      variant: variant,
    );
  }

  /// Preset for password input with eye visibility toggle.
  factory CustomTextField.password({
    Key? key,
    TextEditingController? controller,
    FocusNode? focusNode,
    String? label = 'Password',
    String? hintText = 'Enter password',
    String? Function(String?)? validator,
    ValueChanged<String>? onChanged,
    ValueChanged<String>? onSubmitted,
    bool required = false,
    TextFieldVariant variant = TextFieldVariant.outlined,
  }) {
    return CustomTextField(
      key: key,
      controller: controller,
      focusNode: focusNode,
      label: label,
      hintText: hintText,
      prefixIcon: Icons.lock_outline_rounded,
      obscureText: true,
      showPasswordToggle: true,
      maxLines: 1,
      textInputAction: TextInputAction.done,
      validator: validator,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      required: required,
      variant: variant,
    );
  }

  /// Preset for search input with clear button and magnifying glass.
  factory CustomTextField.search({
    Key? key,
    TextEditingController? controller,
    FocusNode? focusNode,
    String? hintText = 'Search...',
    ValueChanged<String>? onChanged,
    ValueChanged<String>? onSubmitted,
    VoidCallback? onClear,
    TextFieldVariant variant = TextFieldVariant.filled,
  }) {
    return CustomTextField(
      key: key,
      controller: controller,
      focusNode: focusNode,
      hintText: hintText,
      prefixIcon: Icons.search_rounded,
      showClearButton: true,
      filled: true,
      textInputAction: TextInputAction.search,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      variant: variant,
    );
  }

  /// Preset for multiline notes, comments, or descriptions.
  factory CustomTextField.multiline({
    Key? key,
    TextEditingController? controller,
    FocusNode? focusNode,
    String? label = 'Notes',
    String? hintText = 'Type your message...',
    int minLines = 3,
    int? maxLines = 6,
    int? maxLength,
    ValueChanged<String>? onChanged,
    TextFieldVariant variant = TextFieldVariant.outlined,
  }) {
    return CustomTextField(
      key: key,
      controller: controller,
      focusNode: focusNode,
      label: label,
      hintText: hintText,
      minLines: minLines,
      maxLines: maxLines,
      maxLength: maxLength,
      showCounter: maxLength != null,
      keyboardType: TextInputType.multiline,
      textCapitalization: TextCapitalization.sentences,
      onChanged: onChanged,
      variant: variant,
    );
  }

  /// Preset for phone number input with number pad.
  factory CustomTextField.phone({
    Key? key,
    TextEditingController? controller,
    FocusNode? focusNode,
    String? label = 'Phone Number',
    String? hintText = '+1 (555) 000-0000',
    String? Function(String?)? validator,
    ValueChanged<String>? onChanged,
    TextFieldVariant variant = TextFieldVariant.outlined,
  }) {
    return CustomTextField(
      key: key,
      controller: controller,
      focusNode: focusNode,
      label: label,
      hintText: hintText,
      prefixIcon: Icons.phone_outlined,
      keyboardType: TextInputType.phone,
      validator: validator,
      onChanged: onChanged,
      variant: variant,
    );
  }

  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
  late TextEditingController _controller;
  late FocusNode _focusNode;
  bool _isFocused = false;
  late bool _obscureText;
  bool _isInternalController = false;
  bool _isInternalFocusNode = false;

  @override
  void initState() {
    super.initState();
    _obscureText = widget.obscureText;

    if (widget.controller == null) {
      _controller = TextEditingController();
      _isInternalController = true;
    } else {
      _controller = widget.controller!;
    }

    if (widget.focusNode == null) {
      _focusNode = FocusNode();
      _isInternalFocusNode = true;
    } else {
      _focusNode = widget.focusNode!;
    }

    _focusNode.addListener(_handleFocusChange);
    _controller.addListener(_handleTextChange);
  }

  @override
  void didUpdateWidget(covariant CustomTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != oldWidget.controller) {
      if (_isInternalController) {
        _controller.dispose();
      }
      _controller = widget.controller ?? TextEditingController();
      _isInternalController = widget.controller == null;
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_handleFocusChange);
    _controller.removeListener(_handleTextChange);
    if (_isInternalController) _controller.dispose();
    if (_isInternalFocusNode) _focusNode.dispose();
    super.dispose();
  }

  void _handleFocusChange() {
    if (mounted) {
      setState(() => _isFocused = _focusNode.hasFocus);
    }
  }

  void _handleTextChange() {
    if (mounted && widget.showClearButton) {
      setState(() {});
    }
  }

  void _togglePasswordVisibility() {
    setState(() => _obscureText = !_obscureText);
  }

  void _clearText() {
    _controller.clear();
    widget.onChanged?.call('');
  }

  String? get _resolvedHint => widget.hintText ?? widget.hint;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final primaryColor = colorScheme.primary;

    Color effectiveFillColor;
    if (widget.fillColor != null) {
      effectiveFillColor = widget.fillColor!;
    } else {
      switch (widget.variant) {
        case TextFieldVariant.filled:
          effectiveFillColor = isDark
              ? colorScheme.surfaceContainerHighest
              : const Color(0xFFF1F5F9);
          break;
        case TextFieldVariant.glass:
          effectiveFillColor = isDark
              ? Colors.white.withValues(alpha: 0.06)
              : Colors.black.withValues(alpha: 0.04);
          break;
        default:
          effectiveFillColor = widget.filled
              ? colorScheme.surfaceContainerHighest
              : Colors.transparent;
      }
    }

    final isFilledEffective = widget.filled ||
        widget.variant == TextFieldVariant.filled ||
        widget.variant == TextFieldVariant.glass;

    return TextFormField(
      controller: _controller,
      focusNode: _focusNode,
      keyboardType: widget.keyboardType,
      textInputAction: widget.textInputAction,
      textCapitalization: widget.textCapitalization,
      textDirection: widget.textDirection ?? TextDirection.ltr,
      textAlign: widget.textAlign,
      maxLines: widget.obscureText ? 1 : widget.maxLines,
      minLines: widget.minLines,
      maxLength: widget.maxLength,
      obscureText: _obscureText,
      autocorrect: widget.autocorrect,
      enableSuggestions: widget.enableSuggestions,
      readOnly: widget.readOnly,
      enabled: widget.enabled,
      autofocus: widget.autofocus,
      expands: widget.expands,
      inputFormatters: widget.inputFormatters,
      validator: widget.validator,
      autovalidateMode: widget.autovalidateMode,
      onChanged: widget.onChanged,
      onFieldSubmitted: widget.onSubmitted,
      onTap: widget.onTap,
      onEditingComplete: widget.onEditingComplete,
      style: widget.style ??
          theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500),
      cursorColor: widget.cursorColor ?? primaryColor,
      cursorHeight: widget.cursorHeight,
      cursorWidth: widget.cursorWidth ?? 2.0,
      cursorRadius: widget.cursorRadius ?? const Radius.circular(2),

      decoration: InputDecoration(
        // Labels
        label: widget.labelIcon != null && widget.label != null
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(widget.labelIcon, size: 16),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      widget.required ? '${widget.label} *' : widget.label!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              )
            : null,
        labelText: widget.labelIcon == null
            ? (widget.required && widget.label != null
                ? '${widget.label} *'
                : widget.label)
            : null,
        labelStyle: widget.labelStyle ??
            theme.textTheme.bodyMedium?.copyWith(
              color: _isFocused ? primaryColor : colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
        floatingLabelStyle: widget.labelStyle ??
            theme.textTheme.bodyMedium?.copyWith(
              color: primaryColor,
              fontWeight: FontWeight.w600,
            ),

        // Hints & Helpers
        hintText: _resolvedHint,
        hintStyle: widget.hintStyle ??
            theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
              fontWeight: FontWeight.w400,
            ),
        helperText: widget.helperText,
        helperStyle: widget.helperStyle ??
            theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
        helperMaxLines: 2,

        // Errors
        errorText: widget.errorText,
        errorStyle: widget.errorStyle ??
            theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.error,
              fontWeight: FontWeight.w500,
            ),
        errorMaxLines: 2,

        // Counter
        counterText: widget.showCounter ? widget.counterText : '',

        // Prefix
        prefixText: widget.prefixText,
        prefixStyle: theme.textTheme.bodyLarge,
        prefix: widget.prefix,
        prefixIcon: widget.prefixIcon != null
            ? GestureDetector(
                onTap: widget.onPrefixIconTap,
                child: Icon(
                  widget.prefixIcon,
                  color: _isFocused ? primaryColor : colorScheme.onSurfaceVariant,
                ),
              )
            : null,

        // Suffix
        suffixText: widget.suffixText,
        suffixStyle: theme.textTheme.bodyLarge,
        suffix: widget.suffix,
        suffixIcon: _buildSuffixIcon(colorScheme),

        // Fill & Padding
        filled: isFilledEffective,
        fillColor: effectiveFillColor,
        contentPadding: widget.contentPadding ??
            EdgeInsets.symmetric(
              horizontal: 16,
              vertical: (widget.maxLines == null || widget.maxLines! > 1) ? 16 : 14,
            ),
        isDense: widget.isDense,

        // Borders
        border: _buildBorder(colorScheme.outline, widget.borderWidth),
        enabledBorder: _buildBorder(
          widget.borderColor ??
              (widget.variant == TextFieldVariant.glass
                  ? Colors.white.withValues(alpha: 0.15)
                  : colorScheme.outline.withValues(alpha: 0.6)),
          widget.borderWidth,
        ),
        focusedBorder: _buildBorder(
          widget.focusedBorderColor ?? primaryColor,
          widget.focusedBorderWidth,
        ),
        errorBorder: _buildBorder(
          widget.errorBorderColor ?? colorScheme.error,
          widget.borderWidth,
        ),
        focusedErrorBorder: _buildBorder(
          widget.errorBorderColor ?? colorScheme.error,
          widget.focusedBorderWidth,
        ),
        disabledBorder: _buildBorder(
          colorScheme.outline.withValues(alpha: 0.3),
          widget.borderWidth,
        ),
      ),
    );
  }

  Widget? _buildSuffixIcon(ColorScheme colorScheme) {
    final List<Widget> suffixes = [];

    // Password Toggle
    if (widget.showPasswordToggle && widget.obscureText) {
      return IconButton(
        icon: Icon(
          _obscureText ? Icons.visibility_off_rounded : Icons.visibility_rounded,
          color: _isFocused ? colorScheme.primary : colorScheme.onSurfaceVariant,
          size: 20,
        ),
        onPressed: _togglePasswordVisibility,
        tooltip: _obscureText ? 'Show password' : 'Hide password',
      );
    }

    // Clear Button
    if (widget.showClearButton && _controller.text.isNotEmpty) {
      suffixes.add(
        IconButton(
          icon: Icon(
            Icons.cancel_rounded,
            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
            size: 18,
          ),
          onPressed: _clearText,
          tooltip: 'Clear',
        ),
      );
    }

    // Custom Suffix Icon
    if (widget.suffixIcon != null) {
      suffixes.add(
        GestureDetector(
          onTap: widget.onSuffixIconTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Icon(
              widget.suffixIcon,
              color: _isFocused ? colorScheme.primary : colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      );
    }

    if (suffixes.isEmpty) return null;
    if (suffixes.length == 1) return suffixes.first;

    return Row(mainAxisSize: MainAxisSize.min, children: suffixes);
  }

  InputBorder _buildBorder(Color color, double width) {
    if (!widget.showBorder || widget.variant == TextFieldVariant.borderless) {
      return InputBorder.none;
    }

    final effRadius = widget.borderRadius ?? BorderRadius.circular(12);

    if (widget.variant == TextFieldVariant.underline) {
      return UnderlineInputBorder(
        borderSide: BorderSide(color: color, width: width),
      );
    }

    return OutlineInputBorder(
      borderRadius: effRadius,
      borderSide: BorderSide(color: color, width: width),
    );
  }
}
