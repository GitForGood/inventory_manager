import 'package:flutter/material.dart';
import 'package:inventory_manager/themes/nixie_theme.dart';

/// A Card widget that uses the outlined card variant from the theme
///
/// This widget automatically applies the outlined card styling defined
/// in the CardVariants theme extension, providing a consistent outlined
/// card appearance across the app.
class OutlinedCard extends StatelessWidget {
  final Widget? child;
  final EdgeInsetsGeometry? margin;
  final Clip? clipBehavior;
  final Color? color;
  final Color? shadowColor;
  final Color? surfaceTintColor;
  final double? elevation;
  final ShapeBorder? shape;
  final bool borderOnForeground;
  final EdgeInsetsGeometry? padding;

  const OutlinedCard({
    super.key,
    this.child,
    this.margin,
    this.clipBehavior,
    this.color,
    this.shadowColor,
    this.surfaceTintColor,
    this.elevation,
    this.shape,
    this.borderOnForeground = true,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final cardVariants = CardVariants.of(context);
    final outlinedTheme = cardVariants?.outlinedCard;

    return Card(
      margin: margin ?? outlinedTheme?.margin,
      clipBehavior: clipBehavior,
      color: color ?? outlinedTheme?.color,
      shadowColor: shadowColor ?? outlinedTheme?.shadowColor,
      surfaceTintColor: surfaceTintColor,
      elevation: elevation ?? outlinedTheme?.elevation,
      shape: shape ?? outlinedTheme?.shape,
      borderOnForeground: borderOnForeground,
      child: padding != null && child != null
          ? Padding(padding: padding!, child: child)
          : child,
    );
  }
}
