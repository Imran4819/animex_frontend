import 'package:flutter/widgets.dart';

class Responsive {
  static bool isCompact(BuildContext context) =>
      MediaQuery.sizeOf(context).width < 700;

  static bool isMedium(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return width >= 700 && width < 1100;
  }

  static bool isWide(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= 1100;

  static double maxContentWidth(BuildContext context) {
    if (isWide(context)) return 1240;
    if (isMedium(context)) return 1040;
    return double.infinity;
  }
}
