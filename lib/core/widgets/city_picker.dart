import 'package:flutter/material.dart';

import '../accessibility/ui_scale.dart';
import '../constants/cities.dart';
import '../icons/usta_icon.dart';
import '../icons/usta_icons.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import 'app_sheet.dart';

/// A searchable list of Turkish cities in a bottom sheet; returns the chosen one (or null).
Future<String?> pickCity(BuildContext context, {String? selected}) =>
    showAppSheet<String>(
      context,
      builder: (_) => _CityPicker(selected: selected),
    );

class _CityPicker extends StatefulWidget {
  const _CityPicker({this.selected});

  final String? selected;

  @override
  State<_CityPicker> createState() => _CityPickerState();
}

class _CityPickerState extends State<_CityPicker> {
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final needle = _search.trim().toLowerCase();
    final cities = needle.isEmpty
        ? kTurkishCities
        : kTurkishCities
              .where((c) => c.toLowerCase().contains(needle))
              .toList(growable: false);
    final gutter = context.ui.gutter;
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.85,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SheetTitle('İlini seç'),
          Padding(
            padding: EdgeInsets.fromLTRB(gutter, 0, gutter, AppSpacing.md),
            child: TextField(
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'İl ara',
                prefixIcon: Padding(
                  padding: EdgeInsets.all(AppSpacing.md + 2),
                  child: UstaIcon(
                    UstaIcons.search,
                    size: 24,
                    color: AppColors.inkMuted,
                  ),
                ),
              ),
              onChanged: (v) => setState(() => _search = v),
            ),
          ),
          Flexible(
            child: ListView.builder(
              padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
              itemCount: cities.length,
              itemBuilder: (context, i) {
                final city = cities[i];
                final selected = city == widget.selected;
                return ListTile(
                  title: Text(
                    city,
                    style: AppTypography.body.copyWith(
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                    ),
                  ),
                  trailing: selected
                      ? UstaIcon(
                          UstaIcons.check,
                          color: AppColors.primary,
                          size: 24,
                        )
                      : null,
                  onTap: () => Navigator.of(context).pop(city),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
