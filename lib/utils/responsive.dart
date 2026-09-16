import 'package:flutter/widgets.dart';

/// Points de rupture partagés par tout l'écran (voir cahier des charges §24).
/// Aucune dimension fixe : tout se calcule depuis la largeur disponible.
class Breakpoints {
  Breakpoints._();

  static const double tablet = 700;
  static const double desktop = 1100;
}

enum ScreenSize { mobile, tablet, desktop }

ScreenSize screenSizeOf(BuildContext context) {
  final width = MediaQuery.sizeOf(context).width;
  if (width >= Breakpoints.desktop) return ScreenSize.desktop;
  if (width >= Breakpoints.tablet) return ScreenSize.tablet;
  return ScreenSize.mobile;
}

/// Construit un layout différent selon la largeur, en se rebranchant
/// automatiquement quand la fenêtre est redimensionnée (web/desktop).
class ResponsiveBuilder extends StatelessWidget {
  final Widget Function(BuildContext context, ScreenSize size, BoxConstraints constraints) builder;

  const ResponsiveBuilder({super.key, required this.builder});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final ScreenSize size;
        if (constraints.maxWidth >= Breakpoints.desktop) {
          size = ScreenSize.desktop;
        } else if (constraints.maxWidth >= Breakpoints.tablet) {
          size = ScreenSize.tablet;
        } else {
          size = ScreenSize.mobile;
        }
        return builder(context, size, constraints);
      },
    );
  }
}

/// Centre le contenu et limite sa largeur sur grand écran, pour éviter
/// des lignes de texte ou des formulaires trop étirés sur desktop/web.
class MaxWidthCenter extends StatelessWidget {
  final Widget child;
  final double maxWidth;

  const MaxWidthCenter({super.key, required this.child, this.maxWidth = 1200});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}
