import 'package:flutter/material.dart';

import '../../../core/icons/usta_icon.dart';
import '../../../core/icons/usta_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/models/provider_application.dart';
import '../../../data/models/service_price.dart';

/// Text controllers of one price line.
class PriceRowData {
  final name = TextEditingController();
  final min = TextEditingController();
  final max = TextEditingController();

  void dispose() {
    name.dispose();
    min.dispose();
    max.dispose();
  }

  bool get isEmpty =>
      name.text.trim().isEmpty &&
      min.text.trim().isEmpty &&
      max.text.trim().isEmpty;
}

double? _num(String s) => ServicePrice.parseRange(s.trim()).$1;

/// The filled-in lines as [ServicePrice]s (blank lines are skipped).
List<ServicePrice> collectPrices(List<PriceRowData> rows) => [
  for (final r in rows)
    if (!r.isEmpty)
      ServicePrice(
        serviceName: r.name.text.trim(),
        minPrice: _num(r.min.text),
        maxPrice: _num(r.max.text),
      ),
];

/// Optional price list: "Hizmet · min · maks" lines the usta can add or remove.
/// Lives inside a [Form]; each line validates itself.
class PriceListEditor extends StatefulWidget {
  const PriceListEditor({super.key, required this.rows});

  final List<PriceRowData> rows;

  @override
  State<PriceListEditor> createState() => _PriceListEditorState();
}

class _PriceListEditorState extends State<PriceListEditor> {
  @override
  Widget build(BuildContext context) {
    final rows = widget.rows;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < rows.length; i++)
          _PriceRowEditor(
            key: ObjectKey(rows[i]),
            row: rows[i],
            onRemove: rows.length > 1
                ? () => setState(() => rows.removeAt(i).dispose())
                : null,
          ),
        if (rows.length < 10)
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              icon: const UstaIcon(UstaIcons.plus, size: 20),
              label: const Text('Hizmet ekle'),
              onPressed: () => setState(() => rows.add(PriceRowData())),
            ),
          ),
      ],
    );
  }
}

class _PriceRowEditor extends StatelessWidget {
  const _PriceRowEditor({super.key, required this.row, this.onRemove});

  final PriceRowData row;
  final VoidCallback? onRemove;

  String? _validate() {
    if (row.isEmpty) return null; // empty lines are ignored
    final name = row.name.text.trim();
    final min = _num(row.min.text);
    final max = _num(row.max.text);
    if (name.isEmpty) return 'Hizmetin adını yaz.';
    return validatePriceRange(min, max);
  }

  @override
  Widget build(BuildContext context) {
    return FormField<String>(
      validator: (_) => _validate(),
      builder: (field) => Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: row.name,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      labelText: 'Hizmet',
                      hintText: 'Örn. Musluk değişimi',
                    ),
                    onChanged: (_) => field.didChange(null),
                  ),
                ),
                if (onRemove != null)
                  IconButton(
                    tooltip: 'Satırı sil',
                    icon: const UstaIcon(UstaIcons.trash, size: 22),
                    onPressed: onRemove,
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: row.min,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'En az (₺)'),
                    onChanged: (_) => field.didChange(null),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: TextField(
                    controller: row.max,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'En çok (₺)'),
                    onChanged: (_) => field.didChange(null),
                  ),
                ),
              ],
            ),
            if (field.errorText != null)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.xs),
                child: Text(
                  field.errorText!,
                  style: AppTypography.bodySm.copyWith(color: AppColors.danger),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
