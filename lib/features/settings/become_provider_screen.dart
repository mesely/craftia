import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_glyphs/phosphor_glyphs.dart';

import '../../core/constants/cities.dart';
import '../../core/errors/app_failure.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/provider_application.dart';
import '../../data/models/service_price.dart';
import '../../data/models/usta.dart';
import '../../data/providers.dart';
import '../discovery/discovery_providers.dart';

class _PriceRow {
  final name = TextEditingController();
  final min = TextEditingController();
  final max = TextEditingController();

  void dispose() {
    name.dispose();
    min.dispose();
    max.dispose();
  }
}

/// "Hizmet Veren Ol": a compact application. Premium/verified are never client-controlled.
class BecomeProviderScreen extends ConsumerStatefulWidget {
  const BecomeProviderScreen({super.key});

  @override
  ConsumerState<BecomeProviderScreen> createState() =>
      _BecomeProviderScreenState();
}

class _BecomeProviderScreenState extends ConsumerState<BecomeProviderScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _district = TextEditingController();
  final _address = TextEditingController();
  final _about = TextEditingController();
  final _prices = <_PriceRow>[_PriceRow()];

  String? _mainType;
  String? _subType;
  String? _city;
  bool _sending = false;
  String? _error;
  Usta? _created;

  @override
  void dispose() {
    for (final c in [_name, _phone, _district, _address, _about]) {
      c.dispose();
    }
    for (final p in _prices) {
      p.dispose();
    }
    super.dispose();
  }

  double? _num(String s) => ServicePrice.parseRange(s.trim()).$1;

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    final prices = <ServicePrice>[];
    for (final p in _prices) {
      if (p.name.text.trim().isEmpty &&
          p.min.text.trim().isEmpty &&
          p.max.text.trim().isEmpty) {
        continue;
      }
      prices.add(
        ServicePrice(
          serviceName: p.name.text.trim(),
          minPrice: _num(p.min.text),
          maxPrice: _num(p.max.text),
        ),
      );
    }
    setState(() {
      _sending = true;
      _error = null;
    });
    try {
      final created = await ref
          .read(ustaRepositoryProvider)
          .apply(
            ProviderApplication(
              businessName: _name.text.trim(),
              phoneNumber: _phone.text.trim(),
              mainType: _mainType!,
              subType: _subType!,
              city: _city!,
              district: _district.text.trim(),
              address: _address.text.trim(),
              about: _about.text.trim(),
              priceList: prices,
            ),
          );
      if (mounted) setState(() => _created = created);
    } catch (e) {
      if (mounted) {
        setState(() {
          _sending = false;
          _error = AppFailure.from(e).message;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final categories = ref.watch(categoriesProvider);
    final subTypes =
        categories.where((c) => c.id == _mainType).firstOrNull?.subTypes ??
        const [];

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Geri',
          icon: const Icon(PhosphorIconsBold.arrowLeft),
          onPressed: () =>
              context.canPop() ? context.pop() : context.go('/profile'),
        ),
      ),
      body: _created != null
          ? _Success(usta: _created!)
          : Form(
              key: _form,
              child: ListView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.gutter,
                  0,
                  AppSpacing.gutter,
                  AppSpacing.xxxl,
                ),
                children: [
                  const Text('Hizmet veren ol', style: AppTypography.display),
                  const SizedBox(height: AppSpacing.xs),
                  const Text(
                    'Bilgilerini gir; profilin çevrendeki müşterilere görünsün.',
                    style: AppTypography.bodySm,
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                  TextFormField(
                    controller: _name,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'İşletme veya usta adı',
                    ),
                    validator: (v) => (v == null || v.trim().length < 2)
                        ? 'Adını yaz.'
                        : null,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    controller: _phone,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(labelText: 'Telefon'),
                    validator: (v) => sanitizePhone(v ?? '').length < 10
                        ? 'Geçerli bir telefon numarası gir.'
                        : null,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  DropdownButtonFormField<String>(
                    initialValue: _mainType,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Kategori'),
                    items: [
                      for (final c in categories)
                        DropdownMenuItem(value: c.id, child: Text(c.name)),
                    ],
                    onChanged: (v) => setState(() {
                      _mainType = v;
                      _subType = null;
                    }),
                    validator: (v) => v == null ? 'Kategori seç.' : null,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  DropdownButtonFormField<String>(
                    key: ValueKey(_mainType),
                    initialValue: _subType,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Uzmanlık'),
                    items: [
                      for (final s in subTypes)
                        DropdownMenuItem(value: s.value, child: Text(s.label)),
                    ],
                    onChanged: (v) => setState(() => _subType = v),
                    validator: (v) => v == null ? 'Uzmanlığını seç.' : null,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  DropdownButtonFormField<String>(
                    initialValue: _city,
                    isExpanded: true,
                    menuMaxHeight: 320,
                    decoration: const InputDecoration(labelText: 'Şehir'),
                    items: [
                      for (final c in kTurkishCities)
                        DropdownMenuItem(value: c, child: Text(c)),
                    ],
                    onChanged: (v) => setState(() => _city = v),
                    validator: (v) => v == null ? 'Şehir seç.' : null,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    controller: _district,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(labelText: 'İlçe'),
                    validator: (v) => (v == null || v.trim().length < 2)
                        ? 'İlçeni yaz.'
                        : null,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    controller: _address,
                    decoration: const InputDecoration(
                      labelText: 'Açık adres (isteğe bağlı)',
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    controller: _about,
                    minLines: 3,
                    maxLines: 5,
                    maxLength: 500,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      labelText: 'Kendini tanıt (isteğe bağlı)',
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  const Text('Fiyat listesi', style: AppTypography.titleSm),
                  const SizedBox(height: AppSpacing.xs),
                  const Text(
                    'Min ve maks fiyat arasında makul bir aralık bırak.',
                    style: AppTypography.bodySm,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  for (var i = 0; i < _prices.length; i++)
                    _PriceRowEditor(
                      key: ObjectKey(_prices[i]),
                      row: _prices[i],
                      onRemove: _prices.length > 1
                          ? () => setState(() => _prices.removeAt(i).dispose())
                          : null,
                    ),
                  if (_prices.length < 10)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        icon: const Icon(PhosphorIconsRegular.plus, size: 18),
                        label: const Text('Hizmet ekle'),
                        onPressed: () =>
                            setState(() => _prices.add(_PriceRow())),
                      ),
                    ),
                  if (_error != null) ...[
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      _error!,
                      style: AppTypography.bodySm.copyWith(
                        color: AppColors.danger,
                      ),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.xl),
                  FilledButton(
                    onPressed: _sending ? null : _submit,
                    child: _sending
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Başvuruyu gönder'),
                  ),
                ],
              ),
            ),
    );
  }
}

class _PriceRowEditor extends StatelessWidget {
  const _PriceRowEditor({super.key, required this.row, this.onRemove});

  final _PriceRow row;
  final VoidCallback? onRemove;

  String? _validate() {
    final name = row.name.text.trim();
    final min = ServicePrice.parseRange(row.min.text.trim()).$1;
    final max = ServicePrice.parseRange(row.max.text.trim()).$1;
    if (name.isEmpty && min == null && max == null) {
      return null; // empty rows are ignored
    }
    if (name.isEmpty) return 'Hizmet adını yaz.';
    return validatePriceRange(min, max);
  }

  @override
  Widget build(BuildContext context) {
    return FormField<String>(
      validator: (_) => _validate(),
      builder: (field) => Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.md),
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
                      hintText: 'Hizmet (örn. Musluk değişimi)',
                    ),
                    onChanged: (_) => field.didChange(null),
                  ),
                ),
                if (onRemove != null)
                  IconButton(
                    tooltip: 'Satırı sil',
                    icon: const Icon(PhosphorIconsRegular.trash, size: 20),
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
                    decoration: const InputDecoration(hintText: 'Min ₺'),
                    onChanged: (_) => field.didChange(null),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: TextField(
                    controller: row.max,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(hintText: 'Maks ₺'),
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
                  style: AppTypography.caption.copyWith(
                    color: AppColors.danger,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Success extends StatelessWidget {
  const _Success({required this.usta});

  final Usta usta;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.gutter),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            PhosphorIconsFill.checkCircle,
            size: 64,
            color: AppColors.success,
          ),
          const SizedBox(height: AppSpacing.lg),
          const Text('Başvurun alındı', style: AppTypography.title),
          const SizedBox(height: AppSpacing.sm),
          const Text(
            'Profilin artık listede görünüyor. Fiyat listeni ve bilgilerini istediğin zaman güncelletebilirsin.',
            style: AppTypography.bodySm,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xxl),
          FilledButton(
            onPressed: () =>
                context.pushReplacement('/usta/${usta.id}', extra: usta),
            child: const Text('Profilimi gör'),
          ),
        ],
      ),
    );
  }
}
