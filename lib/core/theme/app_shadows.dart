import 'package:flutter/widgets.dart';

import 'app_colors.dart';

abstract final class AppShadows {
  static const card = [
    BoxShadow(color: AppColors.shadow, blurRadius: 12, offset: Offset(0, 2)),
  ];
  static const raised = [
    BoxShadow(color: AppColors.shadow, blurRadius: 24, offset: Offset(0, 8)),
  ];
}
