import 'package:flutter/material.dart';

/// Phone-sized frame centered on wide screens, locked to one screen height.
class MobileViewport extends StatelessWidget {
  const MobileViewport({
    super.key,
    required this.child,
    this.maxWidth = 430,
  });

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final width = size.width < maxWidth ? size.width : maxWidth;

    return Center(
      child: SizedBox(
        width: width,
        height: size.height,
        child: child,
      ),
    );
  }
}

/// Fixed viewport shell: header + middle panel + pinned bottom controls.
class MobileStoryShell extends StatelessWidget {
  const MobileStoryShell({
    super.key,
    required this.header,
    required this.body,
    this.bottomBar,
    this.topSlot,
  });

  final Widget header;
  final Widget body;
  final Widget? bottomBar;
  final Widget? topSlot;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        header,
        if (topSlot != null) topSlot!,
        Expanded(
          child: ClipRect(
            child: body,
          ),
        ),
        if (bottomBar != null)
          DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.95),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.07),
                  blurRadius: 12,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(0, 8, 0, 8),
              child: bottomBar!,
            ),
          ),
      ],
    );
  }
}

/// Bordered panel that fills height and scrolls inside its bounds only.
class ScrollPanel extends StatelessWidget {
  const ScrollPanel({
    super.key,
    required this.child,
    this.margin = const EdgeInsets.fromLTRB(16, 0, 16, 8),
    this.padding = EdgeInsets.zero,
  });

  final Widget child;
  final EdgeInsets margin;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          height: constraints.maxHeight,
          margin: margin,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xFF6F2BC2).withValues(alpha: 0.12),
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(19),
            child: Padding(
              padding: padding,
              child: child,
            ),
          ),
        );
      },
    );
  }
}
