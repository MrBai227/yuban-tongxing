import 'package:flutter/material.dart';

enum NiceButtonVariant { primary, outline, tonal }
enum NiceButtonSize { sm, md, lg }

class NiceActionButton extends StatelessWidget {
  const NiceActionButton({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.variant = NiceButtonVariant.primary,
    this.size = NiceButtonSize.md,
    this.block = false,
    this.isLoading = false,
  });

  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final NiceButtonVariant variant;
  final NiceButtonSize size;
  final bool block;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final padding = switch (size) {
      NiceButtonSize.sm => const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      NiceButtonSize.md => const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      NiceButtonSize.lg => const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
    };

    final spinner = SizedBox(
      width: 16,
      height: 16,
      child: CircularProgressIndicator(
        strokeWidth: 2,
        valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.onPrimary),
      ),
    );

    final labelWidget = Text(label);

    Widget buildContent(Color? iconColor) {
      final iconWidget = icon == null ? null : Icon(icon, color: iconColor);
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isLoading) spinner,
          if (isLoading) const SizedBox(width: 8),
          if (!isLoading && iconWidget != null) iconWidget,
          if (!isLoading && iconWidget != null) const SizedBox(width: 8),
          labelWidget,
        ],
      );
    }

    switch (variant) {
      case NiceButtonVariant.primary:
        final btn = ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: ElevatedButton.styleFrom(padding: padding),
          child: buildContent(null),
        );
        return block ? SizedBox(width: double.infinity, child: btn) : btn;
      case NiceButtonVariant.outline:
        final btn = OutlinedButton(
          onPressed: isLoading ? null : onPressed,
          style: OutlinedButton.styleFrom(padding: padding),
          child: buildContent(null),
        );
        return block ? SizedBox(width: double.infinity, child: btn) : btn;
      case NiceButtonVariant.tonal:
        final btn = FilledButton.tonal(
          onPressed: isLoading ? null : onPressed,
          style: FilledButton.styleFrom(padding: padding),
          child: buildContent(null),
        );
        return block ? SizedBox(width: double.infinity, child: btn) : btn;
    }
  }
}

enum NiceCardVariant { elevated, outlined, filled }

class NiceCard extends StatelessWidget {
  const NiceCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.variant = NiceCardVariant.elevated,
    this.onTap,
  });
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final NiceCardVariant variant;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final radius = const BorderRadius.all(Radius.circular(16));

    switch (variant) {
      case NiceCardVariant.elevated:
        final card = Card(
          margin: margin,
          child: Padding(padding: padding ?? const EdgeInsets.all(16), child: child),
        );
        if (onTap == null) return card;
        return InkWell(borderRadius: radius, onTap: onTap, child: card);
      case NiceCardVariant.outlined:
        final container = Container(
          margin: margin,
          decoration: BoxDecoration(
            borderRadius: radius,
            border: Border.all(color: cs.outlineVariant, width: 1),
            color: cs.surface,
          ),
          child: Padding(padding: padding ?? const EdgeInsets.all(16), child: child),
        );
        if (onTap == null) return container;
        return Material(color: Colors.transparent, child: InkWell(borderRadius: radius, onTap: onTap, child: container));
      case NiceCardVariant.filled:
        final container = Container(
          margin: margin,
          decoration: BoxDecoration(
            borderRadius: radius,
            color: cs.surfaceVariant,
          ),
          child: Padding(padding: padding ?? const EdgeInsets.all(16), child: child),
        );
        if (onTap == null) return container;
        return Material(color: Colors.transparent, child: InkWell(borderRadius: radius, onTap: onTap, child: container));
    }
  }
}

class NiceSectionHeader extends StatelessWidget {
  const NiceSectionHeader({super.key, required this.title, this.trailing});
  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(color: cs.onSurfaceVariant, fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              if (trailing != null) trailing!,
            ],
          ),
        ),
        Container(height: 1, color: cs.outlineVariant),
      ],
    );
  }
}

/// Badge
class NiceBadge extends StatelessWidget {
  const NiceBadge({
    super.key,
    required this.child,
    required this.count,
    this.maxCount = 99,
    this.color,
    this.textColor,
    this.offset = const Offset(-6, -6),
  });
  final Widget child;
  final int count;
  final int maxCount;
  final Color? color;
  final Color? textColor;
  final Offset offset;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    if (count <= 0) return child;
    final bg = color ?? Colors.red;
    final fg = textColor ?? Colors.white;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        Positioned(
          right: offset.dx,
          top: offset.dy,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
            decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
            constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
            child: Center(
              child: Text(count > maxCount ? '$maxCount+' : '$count', style: TextStyle(color: fg, fontSize: 10)),
            ),
          ),
        ),
      ],
    );
  }
}

/// Avatar
class NiceAvatar extends StatelessWidget {
  const NiceAvatar({super.key, this.imageUrl, this.initials, this.size = 36, this.onTap});
  final String? imageUrl;
  final String? initials;
  final double size;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final avatar = CircleAvatar(
      radius: size / 2,
      backgroundImage: imageUrl != null && imageUrl!.isNotEmpty ? NetworkImage(imageUrl!) : null,
      child: (imageUrl == null || imageUrl!.isEmpty) && (initials != null)
          ? Text(initials!, style: TextStyle(fontSize: size * 0.4))
          : null,
    );
    if (onTap == null) return avatar;
    return InkWell(borderRadius: BorderRadius.circular(size / 2), onTap: onTap, child: avatar);
  }
}

/// List Item
class NiceListItem extends StatelessWidget {
  const NiceListItem({
    super.key,
    required this.title,
    this.subtitleText,
    this.subtitle,
    this.leading,
    this.trailing,
    this.onTap,
  });
  final String title;
  final String? subtitleText;
  final Widget? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: leading,
      title: Text(title),
      subtitle: subtitle ?? (subtitleText == null ? null : Text(subtitleText!)),
      trailing: trailing,
      onTap: onTap,
    );
  }
}

/// Chip
class NiceChip extends StatelessWidget {
  const NiceChip({super.key, required this.label, this.selected = false, this.onSelected});
  final String label;
  final bool selected;
  final ValueChanged<bool>? onSelected;

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: onSelected,
    );
  }
}

/// Skeleton
class NiceSkeleton extends StatelessWidget {
  const NiceSkeleton({super.key, this.width, this.height = 16, this.borderRadius = const BorderRadius.all(Radius.circular(12))});
  final double? width;
  final double? height;
  final BorderRadius borderRadius;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.3, end: 0.7),
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeInOut,
      builder: (context, value, child) {
        return Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            borderRadius: borderRadius,
            color: cs.surfaceVariant.withOpacity(value),
          ),
        );
      },
      onEnd: () {},
    );
  }
}

/// Modal helpers
class NiceModal {
  static Future<bool?> confirm(BuildContext context, {required String title, String? content, String okText = '确定', String cancelText = '取消'}) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: content == null ? null : Text(content),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(cancelText)),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(okText)),
        ],
      ),
    );
  }

  static Future<T?> bottomSheet<T>(BuildContext context, {required Widget child}) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: child,
      ),
    );
  }
}