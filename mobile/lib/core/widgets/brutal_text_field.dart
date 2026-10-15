import 'package:flutter/material.dart';
import '../theme/brutal_colors.dart';
import '../theme/brutal_typography.dart';

class BrutalTextField extends StatefulWidget {
  final TextEditingController? controller;
  final String? label;
  final String? hintText;
  final String? errorText;
  final bool obscureText;
  final bool enablePasswordToggle;
  final TextInputType keyboardType;
  final TextInputAction textInputAction;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final ValueChanged<String>? onChanged;
  final FormFieldValidator<String>? validator;
  final bool readOnly;
  final VoidCallback? onTap;
  final int maxLines;

  const BrutalTextField({
    super.key,
    this.controller,
    this.label,
    this.hintText,
    this.errorText,
    this.obscureText = false,
    this.enablePasswordToggle = false,
    this.keyboardType = TextInputType.text,
    this.textInputAction = TextInputAction.next,
    this.prefixIcon,
    this.suffixIcon,
    this.onChanged,
    this.validator,
    this.readOnly = false,
    this.onTap,
    this.maxLines = 1,
  });

  @override
  State<BrutalTextField> createState() => _BrutalTextFieldState();
}

class _BrutalTextFieldState extends State<BrutalTextField> {
  late bool _obscured;

  @override
  void initState() {
    super.initState();
    _obscured = widget.obscureText;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label != null) ...[
          Text(
            widget.label!.toUpperCase(),
            style: BrutalTypography.label.copyWith(
              color: BrutalColors.textPrimary,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 8),
        ],
        Stack(
          clipBehavior: Clip.none,
          children: [
            // Shadow block
            Positioned(
              left: 4,
              top: 4,
              right: -4,
              bottom: -4,
              child: Container(
                color: widget.errorText != null ? BrutalColors.red : BrutalColors.border,
              ),
            ),
            TextFormField(
              controller: widget.controller,
              obscureText: widget.enablePasswordToggle ? _obscured : widget.obscureText,
              keyboardType: widget.keyboardType,
              textInputAction: widget.textInputAction,
              onChanged: widget.onChanged,
              validator: widget.validator,
              readOnly: widget.readOnly,
              onTap: widget.onTap,
              maxLines: widget.maxLines,
              style: BrutalTypography.bodyLarge.copyWith(color: BrutalColors.textPrimary),
              cursorColor: BrutalColors.primaryYellow,
              cursorWidth: 3.0,
              decoration: InputDecoration(
                hintText: widget.hintText,
                filled: true,
                fillColor: BrutalColors.surface,
                prefixIcon: widget.prefixIcon,
                suffixIcon: widget.enablePasswordToggle
                    ? IconButton(
                        icon: Icon(
                          _obscured ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                          color: BrutalColors.textPrimary,
                        ),
                        onPressed: () => setState(() => _obscured = !_obscured),
                      )
                    : widget.suffixIcon,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                enabledBorder: Border.all(
                  color: widget.errorText != null ? BrutalColors.red : BrutalColors.border,
                  width: 3.0,
                ).toOutlineInputBorder(),
                focusedBorder: Border.all(
                  color: widget.errorText != null ? BrutalColors.red : BrutalColors.primaryYellow,
                  width: 3.0,
                ).toOutlineInputBorder(),
                errorBorder: Border.all(
                  color: BrutalColors.red,
                  width: 3.0,
                ).toOutlineInputBorder(),
                focusedErrorBorder: Border.all(
                  color: BrutalColors.red,
                  width: 3.0,
                ).toOutlineInputBorder(),
              ),
            ),
          ],
        ),
        if (widget.errorText != null) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: BrutalColors.red,
              border: Border.all(color: BrutalColors.border, width: 2.0),
            ),
            child: Text(
              widget.errorText!,
              style: BrutalTypography.bodySmall.copyWith(
                color: BrutalColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

extension on Border {
  OutlineInputBorder toOutlineInputBorder() {
    return OutlineInputBorder(
      borderRadius: BorderRadius.zero,
      borderSide: top,
    );
  }
}
