import 'package:flutter/material.dart';
import 'package:snapstudy/core/constants/app_constants.dart';

/// Responsive scaffold with max content width for tablets.
class AppScaffold extends StatelessWidget {
  const AppScaffold({
    super.key,
    this.title,
    this.actions,
    required this.body,
    this.floatingActionButton,
    this.bottomNavigationBar,
    this.showBackButton = false,
    this.padding = true,
    this.centerTitle = false,
  });

  final String? title;
  final List<Widget>? actions;
  final Widget body;
  final Widget? floatingActionButton;
  final Widget? bottomNavigationBar;
  final bool showBackButton;
  final bool padding;
  final bool centerTitle;

  @override
  Widget build(BuildContext context) {
    Widget content = body;

    if (padding) {
      content = Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: content,
      );
    }

    content = Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: AppConstants.maxContentWidth,
        ),
        child: content,
      ),
    );

    return Scaffold(
      appBar: title != null
          ? AppBar(
              title: Text(title!),
              centerTitle: centerTitle,
              actions: actions,
              automaticallyImplyLeading: showBackButton,
            )
          : null,
      body: SafeArea(child: content),
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: bottomNavigationBar,
    );
  }
}

/// Section header used across dashboard and detail pages.
class AppSectionHeader extends StatelessWidget {
  const AppSectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleLarge),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(
                  subtitle!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        ),
        ?trailing,
      ],
    );
  }
}

/// Academic-style card with subtle shadow.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
    this.color,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final card = Container(
      decoration: BoxDecoration(
        color: color ?? colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppConstants.defaultRadius),
        border: Border.all(color: colors.outline.withValues(alpha: 0.5)),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: colors.shadow.withValues(alpha: 0.06),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Padding(padding: padding, child: child),
    );

    if (onTap == null) return card;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppConstants.defaultRadius),
        child: card,
      ),
    );
  }
}
