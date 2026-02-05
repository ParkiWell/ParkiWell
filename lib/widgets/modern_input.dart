import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';

/// Modern text input field with animations
class ModernTextField extends StatefulWidget {
  final String? label;
  final String? hint;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final TextInputType? keyboardType;
  final bool obscureText;
  final IconData? prefixIcon;
  final Widget? suffix;
  final String? errorText;
  final int? maxLines;
  final List<TextInputFormatter>? inputFormatters;
  final FocusNode? focusNode;
  final bool autofocus;

  const ModernTextField({
    super.key,
    this.label,
    this.hint,
    this.controller,
    this.onChanged,
    this.keyboardType,
    this.obscureText = false,
    this.prefixIcon,
    this.suffix,
    this.errorText,
    this.maxLines = 1,
    this.inputFormatters,
    this.focusNode,
    this.autofocus = false,
  });

  @override
  State<ModernTextField> createState() => _ModernTextFieldState();
}

class _ModernTextFieldState extends State<ModernTextField> {
  late FocusNode _focusNode;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
    _focusNode.addListener(_handleFocusChange);
  }

  @override
  void dispose() {
    if (widget.focusNode == null) {
      _focusNode.dispose();
    }
    super.dispose();
  }

  void _handleFocusChange() {
    setState(() {
      _isFocused = _focusNode.hasFocus;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: _isFocused
            ? [
                BoxShadow(
                  color: colors.primary.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: TextField(
        controller: widget.controller,
        focusNode: _focusNode,
        autofocus: widget.autofocus,
        onChanged: widget.onChanged,
        keyboardType: widget.keyboardType,
        obscureText: widget.obscureText,
        maxLines: widget.maxLines,
        inputFormatters: widget.inputFormatters,
        style: Theme.of(context).textTheme.bodyLarge,
        decoration: InputDecoration(
          labelText: widget.label,
          hintText: widget.hint,
          errorText: widget.errorText,
          prefixIcon: widget.prefixIcon != null
              ? Icon(
                  widget.prefixIcon,
                  color: _isFocused ? colors.primary : colors.textTertiary,
                )
              : null,
          suffix: widget.suffix,
        ),
      ),
    );
  }
}

/// Modern dropdown selector
class ModernDropdown<T> extends StatelessWidget {
  final T value;
  final List<T> items;
  final ValueChanged<T?> onChanged;
  final String Function(T) itemLabel;
  final String? label;
  final IconData? prefixIcon;

  const ModernDropdown({
    super.key,
    required this.value,
    required this.items,
    required this.onChanged,
    required this.itemLabel,
    this.label,
    this.prefixIcon,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Text(
            label!,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: colors.textSecondary,
                ),
          ),
          const SizedBox(height: 8),
        ],
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: colors.inputBackground,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: colors.inputBorder),
          ),
          child: Row(
            children: [
              if (prefixIcon != null) ...[
                Icon(
                  prefixIcon,
                  color: colors.textTertiary,
                  size: 20,
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<T>(
                    value: value,
                    isExpanded: true,
                    icon: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: colors.textSecondary,
                    ),
                    dropdownColor: colors.surface,
                    borderRadius: BorderRadius.circular(12),
                    style: Theme.of(context).textTheme.bodyLarge,
                    onChanged: onChanged,
                    items: items.map((item) {
                      return DropdownMenuItem<T>(
                        value: item,
                        child: Text(
                          itemLabel(item),
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Chip selector for multiple options
class ModernChipSelector extends StatelessWidget {
  final List<String> options;
  final List<String> selected;
  final ValueChanged<String> onToggle;
  final bool multiSelect;

  const ModernChipSelector({
    super.key,
    required this.options,
    required this.selected,
    required this.onToggle,
    this.multiSelect = true,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((option) {
        final isSelected = selected.contains(option);
        return GestureDetector(
          onTap: () => onToggle(option),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected ? colors.primary : colors.surfaceVariant,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected ? colors.primary : colors.border,
              ),
            ),
            child: Text(
              option,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: isSelected ? colors.textOnPrimary : colors.textPrimary,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
