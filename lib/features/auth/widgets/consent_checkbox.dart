import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/accessibility/ui_scale.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';

/// "Kullanıcı Sözleşmesi ve KVKK metnini okudum": required to register.
/// Spells out, in the sentence itself, that messages are recorded for disputes.
class ConsentCheckbox extends StatelessWidget {
  const ConsentCheckbox({
    super.key,
    required this.value,
    required this.onChanged,
    this.errorText,
  });

  final bool value;
  final ValueChanged<bool> onChanged;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    final linkStyle = AppTypography.bodySm.copyWith(
      color: AppColors.primary,
      fontWeight: FontWeight.w600,
      decoration: TextDecoration.underline,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          container: true,
          checked: value,
          label: 'Kullanıcı sözleşmesini ve KVKK aydınlatma metnini kabul ediyorum',
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => onChanged(!value),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: context.ui.tapTarget),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ExcludeSemantics(
                    child: SizedBox.square(
                      dimension: context.ui.tapTarget,
                      child: Checkbox(
                        value: value,
                        onChanged: (v) => onChanged(v ?? false),
                        materialTapTargetSize: MaterialTapTargetSize.padded,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.md),
                      child: Text.rich(
                        TextSpan(
                          style: AppTypography.bodySm.copyWith(
                            color: AppColors.ink,
                          ),
                          children: [
                            const TextSpan(text: 'Okudum ve kabul ediyorum: '),
                            _link(
                              context,
                              'Kullanıcı Sözleşmesi',
                              'agreement',
                              linkStyle,
                            ),
                            const TextSpan(text: ', '),
                            _link(
                              context,
                              'KVKK Aydınlatma Metni',
                              'kvkk',
                              linkStyle,
                            ),
                            const TextSpan(text: ' ve '),
                            _link(
                              context,
                              'Sorumluluk Reddi',
                              'disclaimer',
                              linkStyle,
                            ),
                            const TextSpan(
                              text: '. Mesajlaşmalarımın, anlaşmazlık ve güvenlik süreçleri için kayıt altında tutulacağını biliyorum.',
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (errorText != null)
          Padding(
            padding: const EdgeInsets.only(left: AppSpacing.sm),
            child: Text(
              errorText!,
              style: AppTypography.bodySm.copyWith(color: AppColors.danger),
            ),
          ),
      ],
    );
  }

  InlineSpan _link(
    BuildContext context,
    String text,
    String doc,
    TextStyle style,
  ) => WidgetSpan(
    alignment: PlaceholderAlignment.baseline,
    baseline: TextBaseline.alphabetic,
    child: GestureDetector(
      onTap: () => context.push('/legal/$doc'),
      child: Text(text, style: style),
    ),
  );
}
