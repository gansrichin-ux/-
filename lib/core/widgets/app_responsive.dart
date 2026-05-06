import 'package:flutter/material.dart';
import '../theme/app_breakpoints.dart';

class AppResponsiveScaffold extends StatelessWidget {
  final Widget? sidebar;
  final Widget? bottomNavigation;
  final PreferredSizeWidget? appBar;
  final Widget body;
  final Color? backgroundColor;
  final Widget? floatingActionButton;

  const AppResponsiveScaffold({
    super.key,
    this.sidebar,
    this.bottomNavigation,
    this.appBar,
    required this.body,
    this.backgroundColor,
    this.floatingActionButton,
  });

  @override
  Widget build(BuildContext context) {
    final isDesktop = Responsive.isDesktop(context);

    return Scaffold(
      backgroundColor: backgroundColor ?? Theme.of(context).scaffoldBackgroundColor,
      appBar: !isDesktop ? appBar : null,
      bottomNavigationBar: !isDesktop ? bottomNavigation : null,
      floatingActionButton: floatingActionButton,
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isDesktop && sidebar != null) sidebar!,
          Expanded(
            child: Column(
              children: [
                if (isDesktop && appBar != null) appBar!,
                Expanded(child: body),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class AppResponsiveGrid extends StatelessWidget {
  final List<Widget> children;
  final double crossAxisSpacing;
  final double mainAxisSpacing;
  final int mobileCrossAxisCount;
  final int tabletCrossAxisCount;
  final int desktopCrossAxisCount;

  const AppResponsiveGrid({
    super.key,
    required this.children,
    this.crossAxisSpacing = 16,
    this.mainAxisSpacing = 16,
    this.mobileCrossAxisCount = 1,
    this.tabletCrossAxisCount = 2,
    this.desktopCrossAxisCount = 3,
  });

  @override
  Widget build(BuildContext context) {
    int crossAxisCount = mobileCrossAxisCount;
    if (Responsive.isDesktop(context)) {
      crossAxisCount = desktopCrossAxisCount;
    } else if (Responsive.isTablet(context)) {
      crossAxisCount = tabletCrossAxisCount;
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: crossAxisSpacing,
        mainAxisSpacing: mainAxisSpacing,
        mainAxisExtent: 140, // Let caller define this if needed, for stat cards it's usually fixed
      ),
      itemCount: children.length,
      itemBuilder: (context, index) => children[index],
    );
  }
}

class AppResponsiveList extends StatelessWidget {
  final List<Widget> children;
  final double spacing;

  const AppResponsiveList({
    super.key,
    required this.children,
    this.spacing = 16,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: children.length,
      separatorBuilder: (context, index) => SizedBox(height: spacing),
      itemBuilder: (context, index) => children[index],
    );
  }
}
