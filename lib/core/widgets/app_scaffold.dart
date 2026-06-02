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
  });

  final String? title;
  final List<Widget>? actions;
  final Widget body;
  final Widget? floatingActionButton;
  final Widget? bottomNavigationBar;
  final bool showBackButton;
  final bool padding;

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
        constraints: const BoxConstraints(maxWidth: AppConstants.maxContentWidth),
        child: content,
      ),
    );

    return Scaffold(
      appBar: title != null
          ? AppBar(
              title: Text(title!),
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
