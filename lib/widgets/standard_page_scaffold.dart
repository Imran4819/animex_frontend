import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';
import 'app_background.dart';

class StandardPageScaffold extends StatelessWidget {
  const StandardPageScaffold({
    super.key,
    required this.title,
    required this.body,
    this.actions,
    this.drawer,
    this.leading,
    this.floatingActionButton,
    this.bottomNavigationBar,
    this.centerTitle = false,
    this.extendBody = false,
    this.bodyPadding = const EdgeInsets.fromLTRB(16, 16, 16, 24),
  });

  final String title;
  final Widget body;
  final List<Widget>? actions;
  final Widget? drawer;
  final Widget? leading;
  final Widget? floatingActionButton;
  final Widget? bottomNavigationBar;
  final bool centerTitle;
  final bool extendBody;
  final EdgeInsetsGeometry bodyPadding;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? AppColors.navyDark
          : AppColors.background,
      drawer: drawer,
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: bottomNavigationBar,
      extendBody: extendBody,
      appBar: AppBar(
        title: Text(title),
        centerTitle: centerTitle,
        leading: leading,
        actions: actions,
        surfaceTintColor: Colors.transparent,
        backgroundColor: Colors.transparent,
      ),
      body: AppBackground(
        child: SafeArea(
          child: Padding(
            padding: bodyPadding,
            child: body,
          ),
        ),
      ),
    );
  }
}
