import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';

const kNavyGradient = LinearGradient(
  colors: [Color(0xFF142B4A), Color(0xFF1E3F6F)],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);
const kTealGradient = LinearGradient(
  colors: [Color(0xFF0D9488), Color(0xFF12B8A6)],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);
const kHeroGradient = LinearGradient(
  colors: [Color(0xFF142B4A), Color(0xFF0D9488)],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);

/// Soft page background used behind the dashboard screens.
const kPageGradient = LinearGradient(
  colors: [Color(0xFFF3F8FC), Color(0xFFEAF4F3)],
  begin: Alignment.topCenter,
  end: Alignment.bottomCenter,
);

/// Subtle card gradient (white → faint teal) for highlighted cards.
const kCardGradient = LinearGradient(
  colors: [Color(0xFFFFFFFF), Color(0xFFF1FAF9)],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);

/// Height of every screen header (below the status bar). All headers share it
/// and never grow, shrink or move while the page scrolls.
const double kHeaderHeight = 68;
const double kHeaderRadius = 24;

/// Breathing room between a form header and the content below it.
const double kHeaderGap = 10;

const _headerShadow = [
  BoxShadow(color: Color(0x22142B4A), blurRadius: 14, offset: Offset(0, 5)),
];

/// Fixed, pinned, rounded gradient header used at the top of every main screen.
class AppSliverHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? leading;
  final List<Widget> actions;
  final Gradient gradient;
  final bool showBack;
  final VoidCallback? onBackOverride;

  /// Where the back arrow goes when there is nothing to pop (e.g. the page
  /// was opened from a shared link). Null hides the arrow in that case.
  final String? fallbackRoute;

  const AppSliverHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.actions = const [],
    this.gradient = kNavyGradient,
    this.showBack = false,
    this.onBackOverride,
    this.fallbackRoute,
  });

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    return SliverPersistentHeader(
      pinned: true,
      delegate: _HeaderDelegate(
        header: this,
        topPadding: top,
        canPop: showBack && (onBackOverride != null || Navigator.of(context).canPop() || fallbackRoute != null),
      ),
    );
  }
}

class _HeaderDelegate extends SliverPersistentHeaderDelegate {
  final AppSliverHeader header;
  final double topPadding;
  final bool canPop;

  _HeaderDelegate({required this.header, required this.topPadding, required this.canPop});

  @override
  double get minExtent => kHeaderHeight + topPadding;

  @override
  double get maxExtent => kHeaderHeight + topPadding;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    final h = header;
    return SizedBox.expand(
      child: _HeaderSurface(
        gradient: h.gradient,
        topPadding: topPadding,
        child: Row(children: [
          if (canPop) _BackButton(fallbackRoute: h.fallbackRoute, onOverride: h.onBackOverride) else const SizedBox(width: 14),
          if (h.leading != null) ...[
            SizedBox(
              height: 40,
              width: 40,
              child: FittedBox(fit: BoxFit.contain, child: h.leading),
            ),
            const SizedBox(width: 10),
          ],
          Expanded(child: _HeaderTitle(title: h.title, subtitle: h.subtitle)),
          ...h.actions,
          const SizedBox(width: 6),
        ]),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _HeaderDelegate old) =>
      old.header != header || old.topPadding != topPadding || old.canPop != canPop;
}

/// Same header for screens that use a regular [Scaffold.appBar] (forms, editors).
class GradientAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final String? subtitle;
  final List<Widget> actions;
  final Gradient gradient;

  /// Optional extra row under the title (e.g. a step indicator). Adds [bottomHeight].
  final Widget? bottom;
  final double bottomHeight;

  const GradientAppBar({
    super.key,
    required this.title,
    this.subtitle,
    this.actions = const [],
    this.gradient = kNavyGradient,
    this.bottom,
    this.bottomHeight = 0,
  });

  @override
  Size get preferredSize => Size.fromHeight(kHeaderHeight + (bottom == null ? 0 : bottomHeight) + kHeaderGap);

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    final canPop = Navigator.of(context).canPop();
    return Padding(
      padding: const EdgeInsets.only(bottom: kHeaderGap),
      child: _HeaderSurface(
        gradient: gradient,
        topPadding: top,
        child: Column(children: [
          SizedBox(
            height: kHeaderHeight,
            child: Row(children: [
              if (canPop) const _BackButton() else const SizedBox(width: 14),
              Expanded(child: _HeaderTitle(title: title, subtitle: subtitle)),
              ...actions,
              const SizedBox(width: 6),
            ]),
          ),
          if (bottom != null) SizedBox(height: bottomHeight, child: bottom),
        ]),
      ),
    );
  }
}

class _HeaderSurface extends StatelessWidget {
  final Gradient gradient;
  final double topPadding;
  final Widget child;
  const _HeaderSurface({required this.gradient, required this.topPadding, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(kHeaderRadius)),
        boxShadow: _headerShadow,
      ),
      child: Stack(children: [
        // Soft highlight for depth.
        Positioned(
          right: -40,
          top: -60,
          child: IgnorePointer(
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient:
                    RadialGradient(colors: [Colors.white.withValues(alpha: 0.12), Colors.white.withValues(alpha: 0)]),
              ),
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.only(top: topPadding),
          child: Theme(
            data: Theme.of(context).copyWith(
              iconTheme: const IconThemeData(color: AppColors.white),
              iconButtonTheme: IconButtonThemeData(style: IconButton.styleFrom(foregroundColor: AppColors.white)),
            ),
            child: child,
          ),
        ),
      ]),
    );
  }
}

class _HeaderTitle extends StatelessWidget {
  final String title;
  final String? subtitle;
  const _HeaderTitle({required this.title, this.subtitle});

  @override
  Widget build(BuildContext context) {
    final hasSub = subtitle != null && subtitle!.isNotEmpty;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style:
              const TextStyle(color: AppColors.white, fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: -0.2),
        ),
        if (hasSub)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(subtitle!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white70, fontSize: 12.5)),
          ),
      ],
    );
  }
}

class _BackButton extends StatelessWidget {
  final String? fallbackRoute;
  final VoidCallback? onOverride;
  const _BackButton({this.fallbackRoute, this.onOverride});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back_rounded, color: AppColors.white),
      tooltip: MaterialLocalizations.of(context).backButtonTooltip,
      onPressed: () {
        if (onOverride != null) {
          onOverride!();
          return;
        }
        final nav = Navigator.of(context);
        if (nav.canPop()) {
          nav.pop();
        } else if (fallbackRoute != null) {
          GoRouter.of(context).go(fallbackRoute!);
        }
      },
    );
  }
}

/// Small rounded icon tile used as a header leading widget.
class HeaderIcon extends StatelessWidget {
  final IconData icon;
  const HeaderIcon(this.icon, {super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(9),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: AppColors.white, size: 22),
    );
  }
}
