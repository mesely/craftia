import 'package:flutter/painting.dart';

import 'app_colors.dart';

abstract final class AppBorders {
  static BorderSide get hairline => BorderSide(color: AppColors.border);
  static BorderSide get strong =>
      BorderSide(color: AppColors.borderStrong, width: 1.5);
  static BorderSide get selected =>
      BorderSide(color: AppColors.primary, width: 2);
}
