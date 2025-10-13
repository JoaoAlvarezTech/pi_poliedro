import 'package:flutter/material.dart';

class ResponsiveWidget extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget? desktop;

  const ResponsiveWidget({
    super.key,
    required this.mobile,
    this.tablet,
    this.desktop,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 1200) {
          return desktop ?? tablet ?? mobile;
        } else if (constraints.maxWidth >= 800) {
          return tablet ?? mobile;
        } else {
          return mobile;
        }
      },
    );
  }
}

class ResponsiveBuilder extends StatelessWidget {
  final Widget Function(BuildContext context, ResponsiveBreakpoint breakpoint) builder;

  const ResponsiveBuilder({
    super.key,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        ResponsiveBreakpoint breakpoint;
        
        if (constraints.maxWidth >= 1200) {
          breakpoint = ResponsiveBreakpoint.desktop;
        } else if (constraints.maxWidth >= 800) {
          breakpoint = ResponsiveBreakpoint.tablet;
        } else {
          breakpoint = ResponsiveBreakpoint.mobile;
        }
        
        return builder(context, breakpoint);
      },
    );
  }
}

enum ResponsiveBreakpoint {
  mobile,
  tablet,
  desktop,
}

extension ResponsiveBreakpointExtension on ResponsiveBreakpoint {
  bool get isMobile => this == ResponsiveBreakpoint.mobile;
  bool get isTablet => this == ResponsiveBreakpoint.tablet;
  bool get isDesktop => this == ResponsiveBreakpoint.desktop;
  
  double get maxWidth {
    switch (this) {
      case ResponsiveBreakpoint.mobile:
        return 800;
      case ResponsiveBreakpoint.tablet:
        return 1200;
      case ResponsiveBreakpoint.desktop:
        return double.infinity;
    }
  }
}

class ResponsiveContainer extends StatelessWidget {
  final Widget child;
  final double? maxWidth;
  final EdgeInsetsGeometry? padding;

  const ResponsiveContainer({
    super.key,
    required this.child,
    this.maxWidth,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return ResponsiveBuilder(
      builder: (context, breakpoint) {
        double containerMaxWidth;
        EdgeInsetsGeometry containerPadding;

        switch (breakpoint) {
          case ResponsiveBreakpoint.mobile:
            containerMaxWidth = maxWidth ?? 600;
            containerPadding = padding ?? const EdgeInsets.symmetric(horizontal: 16);
            break;
          case ResponsiveBreakpoint.tablet:
            containerMaxWidth = maxWidth ?? 800;
            containerPadding = padding ?? const EdgeInsets.symmetric(horizontal: 24);
            break;
          case ResponsiveBreakpoint.desktop:
            containerMaxWidth = maxWidth ?? 1200;
            containerPadding = padding ?? const EdgeInsets.symmetric(horizontal: 32);
            break;
        }

        return Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: containerMaxWidth),
            child: Padding(
              padding: containerPadding,
              child: child,
            ),
          ),
        );
      },
    );
  }
}

class ResponsiveGrid extends StatelessWidget {
  final List<Widget> children;
  final int mobileColumns;
  final int? tabletColumns;
  final int? desktopColumns;
  final double spacing;
  final double runSpacing;

  const ResponsiveGrid({
    super.key,
    required this.children,
    this.mobileColumns = 1,
    this.tabletColumns,
    this.desktopColumns,
    this.spacing = 16,
    this.runSpacing = 16,
  });

  @override
  Widget build(BuildContext context) {
    return ResponsiveBuilder(
      builder: (context, breakpoint) {
        int columns;
        
        switch (breakpoint) {
          case ResponsiveBreakpoint.mobile:
            columns = mobileColumns;
            break;
          case ResponsiveBreakpoint.tablet:
            columns = tabletColumns ?? mobileColumns;
            break;
          case ResponsiveBreakpoint.desktop:
            columns = desktopColumns ?? tabletColumns ?? mobileColumns;
            break;
        }

        return Wrap(
          spacing: spacing,
          runSpacing: runSpacing,
          children: children.map((child) {
            return SizedBox(
              width: (MediaQuery.of(context).size.width - 
                     (spacing * (columns - 1)) - 
                     (breakpoint.isMobile ? 32 : breakpoint.isTablet ? 48 : 64)) / columns,
              child: child,
            );
          }).toList(),
        );
      },
    );
  }
}
