import 'package:flutter/painting.dart';

import 'app_colors.dart';

abstract final class AppBorders {
  static const hairline = BorderSide(color: AppColors.border);
  static const strong = BorderSide(color: AppColors.borderStrong, width: 1.5);
  static const selected = BorderSide(color: AppColors.primary, width: 2);
}
