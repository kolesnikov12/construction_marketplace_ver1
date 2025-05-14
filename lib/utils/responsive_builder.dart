import 'package:flutter/material.dart';
import 'responsive_helper.dart';

class ResponsiveBuilder extends StatelessWidget {
  final Widget Function(BuildContext context, bool isMobile, bool isTablet, bool isDesktop) builder;

  const ResponsiveBuilder({
    Key? key,
    required this.builder,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveHelper.isMobile(context);
    final isTablet = ResponsiveHelper.isTablet(context);
    final isDesktop = ResponsiveHelper.isDesktop(context);

    return builder(context, isMobile, isTablet, isDesktop);
  }
}

class ResponsiveLayout extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget? desktop;

  const ResponsiveLayout({
    Key? key,
    required this.mobile,
    this.tablet,
    this.desktop,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= ResponsiveHelper.desktopBreakpoint) {
          return desktop ?? tablet ?? mobile;
        } else if (constraints.maxWidth >= ResponsiveHelper.mobileBreakpoint) {
          return tablet ?? mobile;
        } else {
          return mobile;
        }
      },
    );
  }
}

class ResponsiveRow extends StatelessWidget {
  final List<Widget> children;
  final MainAxisAlignment mainAxisAlignment;
  final CrossAxisAlignment crossAxisAlignment;
  final int mobileColumns;
  final int tabletColumns;
  final int desktopColumns;
  final double spacing;

  const ResponsiveRow({
    Key? key,
    required this.children,
    this.mainAxisAlignment = MainAxisAlignment.start,
    this.crossAxisAlignment = CrossAxisAlignment.start,
    this.mobileColumns = 1,
    this.tabletColumns = 2,
    this.desktopColumns = 3,
    this.spacing = 16,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ResponsiveBuilder(
      builder: (context, isMobile, isTablet, isDesktop) {
        final columns = isDesktop
            ? desktopColumns
            : (isTablet ? tabletColumns : mobileColumns);

        if (columns == 1) {
          return Column(
            mainAxisAlignment: mainAxisAlignment,
            crossAxisAlignment: crossAxisAlignment,
            children: children.map((child) =>
                Padding(
                  padding: EdgeInsets.only(bottom: spacing),
                  child: child,
                )
            ).toList(),
          );
        }

        final rows = <Widget>[];
        for (int i = 0; i < children.length; i += columns) {
          final rowChildren = <Widget>[];
          for (int j = 0; j < columns && i + j < children.length; j++) {
            rowChildren.add(
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    left: j > 0 ? spacing / 2 : 0,
                    right: j < columns - 1 ? spacing / 2 : 0,
                  ),
                  child: children[i + j],
                ),
              ),
            );
          }

          // If the last row is not complete, add empty expanded widgets
          if (rowChildren.length < columns && i + columns > children.length) {
            final emptySpaces = columns - rowChildren.length;
            for (int k = 0; k < emptySpaces; k++) {
              rowChildren.add(Expanded(child: Container()));
            }
          }

          rows.add(
            Padding(
              padding: EdgeInsets.only(bottom: spacing),
              child: Row(
                mainAxisAlignment: mainAxisAlignment,
                crossAxisAlignment: crossAxisAlignment,
                children: rowChildren,
              ),
            ),
          );
        }

        return Column(children: rows);
      },
    );
  }
}