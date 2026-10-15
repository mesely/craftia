import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/accessibility/ui_scale.dart';
import '../../core/errors/app_failure.dart';
import '../../core/icons/usta_icon.dart';
import '../../core/icons/usta_icons.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/choice_tile.dart';
import '../../data/models/complaint.dart';
import '../../data/providers.dart';
import '../auth/auth_controller.dart';
import 'official_channels.dart';

/// "Şikayet et": pick a reason, add a few words. The complaint is recorded with a reference
/// number, and the next screen points to the official channels where disputes are decided.
class ComplaintScreen extends ConsumerStatefulWidget {
  const ComplaintScreen({super.key, required this.target});

  final ComplaintTarget target;

  @override
  ConsumerState<ComplaintScreen> createState() => _ComplaintScreenState();
}

class _ComplaintScreenState extends ConsumerState<ComplaintScreen> {
  final _details = TextEditingController();
  ComplaintReason? _reason;
  bool _busy = false;
  String? _error;
  ComplaintReceipt? _receipt;

  @override
  void dispose() {
    _details.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final account = ref.read(authProvider).account;
    if (account == null) return;
    if (_reason == null) {
      setState(() => _error = 'Lütfen şikayet nedenini seç.');
      return;
    }
    if (_reason == ComplaintReason.other && _details.text.trim().length < 10) {
      setState(() => _error = 'Lütfen şikayetini birkaç cümleyle anlat.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final receipt = await ref
          .read(complaintsRepositoryProvider)
          .submit(
            reporterId: account.id,
            target: widget.target,
            reason: _reason!,
            details: _details.text,
          );
      if (mounted) setState(() => _receipt = receipt);
    } catch (e) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = AppFailure.from(e).message;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final gutter = context.ui.gutter;
    final signedIn = ref.watch(authProvider.select((s) => s.signedIn));
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Geri',
          icon: const UstaIcon(UstaIcons.arrowLeft, size: 26),
          onPressed: () => context.canPop() ? context.pop() : context.go('/'),
        ),
      ),
      body: !signedIn
          ? Center(
              child: Padding(
                padding: EdgeInsets.all(gutter),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Şikayet etmek için giriş yapmalısın.',
                      style: AppTypography.titleSm,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    FilledButton(
                      onPressed: () => context.push('/login'),
                      child: const Text('Giriş yap'),
                    ),
                  ],
                ),
              ),
            )
          : _receipt != null
          ? _Receipt(receipt: _receipt!, gutter: gutter)
          : ListView(
              padding: EdgeInsets.fromLTRB(gutter, 0, gutter, AppSpacing.xxxl),
              children: [
                Semantics(
                  header: true,
                  child: Text('Şikayet et', style: AppTypography.display),
                ),
                if (widget.target.name.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    widget.target.name,
                    style: AppTypography.titleSm.copyWith(
                      color: AppColors.inkMuted,
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.xl),
                Text('Sorun nedir?', style: AppTypography.titleSm),
                const SizedBox(height: AppSpacing.sm),
                for (final r in ComplaintReason.values) ...[
                  ChoiceTile(
                    label: r.label,
                    caption: r.hint,
                    selected: _reason == r,
                    onTap: () => setState(() {
                      _reason = r;
                      _error = null;
                    }),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                ],
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: _details,
                  minLines: 4,
                  maxLines: 7,
                  maxLength: 1000,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Ne oldu? (isteğe bağlı)',
                    hintText: 'Tarih, konuşulan şeyler, istenen ücret…',
                  ),
                ),
                if (_error != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    _error!,
                    style: AppTypography.body.copyWith(color: AppColors.danger),
                  ),
                ],
                const SizedBox(height: AppSpacing.lg),
                FilledButton(
                  onPressed: _busy ? null : _submit,
                  child: _busy
                      ? SizedBox.square(
                          dimension: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: AppColors.onPrimary,
                          ),
                        )
                      : const Text('Şikayeti gönder'),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Şikayetin kayıt altına alınır. Usta bir ilan platformu olduğu için uyuşmazlığı çözen taraf değildir; bir sonraki ekranda resmi başvuru yollarını göreceksin.',
                  style: AppTypography.bodySm,
                ),
              ],
            ),
    );
  }
}

class _Receipt extends StatelessWidget {
  const _Receipt({required this.receipt, required this.gutter});

  final ComplaintReceipt receipt;
  final double gutter;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.fromLTRB(gutter, 0, gutter, AppSpacing.xxxl),
      children: [
        Center(
          child: UstaIcon(
            UstaIcons.checkCircle,
            size: 64,
            color: AppColors.success,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          'Şikayetin alındı',
          style: AppTypography.display,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Takip numaran: ${receipt.reference}',
          style: AppTypography.titleSm.copyWith(color: AppColors.primary),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          'Dolandırıcılık, tehdit ya da zarar söz konusuysa lütfen resmi mercilere de başvur. Gerekirse bu takip numarasını ve sohbet kayıtlarını kullanabilirsin (Ayarlar > Verilerimi indir).',
          style: AppTypography.body.copyWith(color: AppColors.inkMuted),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.xl),
        const OfficialChannels(),
        const SizedBox(height: AppSpacing.md),
        FilledButton(
          onPressed: () => context.canPop() ? context.pop() : context.go('/'),
          child: const Text('Tamam'),
        ),
      ],
    );
  }
}
