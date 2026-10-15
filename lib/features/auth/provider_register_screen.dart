import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/accessibility/ui_scale.dart';
import '../../core/constants/services.dart';
import '../../core/errors/app_failure.dart';
import '../../core/icons/usta_icon.dart';
import '../../core/icons/usta_icons.dart';
import '../../core/theme/app_borders.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/validators.dart';
import '../../core/widgets/choice_tile.dart';
import '../../core/widgets/city_picker.dart';
import '../../data/models/provider_application.dart';
import '../../core/constants/cities.dart';
import '../discovery/service_tile.dart';
import '../location/location_controller.dart';
import '../location/location_service.dart';
import '../location/place_name.dart';
import 'auth_controller.dart';
import 'widgets/consent_checkbox.dart';
import 'widgets/price_list_editor.dart';

/// Usta registration in three short steps. Everything the customers need to trust an usta is
/// required (name, service, place, how they work, a short introduction); only the price list is
/// optional. A signed-in customer skips step 1 and keeps their account.
class ProviderRegisterScreen extends ConsumerStatefulWidget {
  const ProviderRegisterScreen({super.key});

  @override
  ConsumerState<ProviderRegisterScreen> createState() =>
      _ProviderRegisterScreenState();
}

class _ProviderRegisterScreenState
    extends ConsumerState<ProviderRegisterScreen> {
  final _accountForm = GlobalKey<FormState>();
  final _detailsForm = GlobalKey<FormState>();
  final _priceForm = GlobalKey<FormState>();

  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _business = TextEditingController();
  final _district = TextEditingController();
  final _address = TextEditingController();
  final _areas = TextEditingController();
  final _about = TextEditingController();
  final _prices = <PriceRowData>[PriceRowData()];

  late final bool _upgrade = ref.read(authProvider).signedIn;
  late int _step = _upgrade ? 1 : 0;

  ServiceOption? _service;
  String? _city;
  bool? _hasShop;
  double? _lat;
  double? _lng;
  bool _locating = false;
  bool _consent = false;
  bool _showErrors = false;
  bool _hidden = true;
  bool _busy = false;
  String? _error;

  List<TextEditingController> get _fields => [
    _name,
    _phone,
    _email,
    _password,
    _business,
    _district,
    _address,
    _areas,
    _about,
    for (final p in _prices) p.name,
  ];

  /// Mock stage: "admin" in any field skips the checks and fills sensible demo values.
  bool get _admin => _fields.any((c) => isAdminToken(c.text));

  int get _firstStep => _upgrade ? 1 : 0;

  @override
  void dispose() {
    for (final c in [
      _name,
      _phone,
      _email,
      _password,
      _business,
      _district,
      _address,
      _areas,
      _about,
    ]) {
      c.dispose();
    }
    for (final p in _prices) {
      p.dispose();
    }
    super.dispose();
  }

  void _back() {
    if (_step > _firstStep) {
      setState(() => _step--);
    } else {
      context.canPop() ? context.pop() : context.go('/welcome');
    }
  }

  void _next() {
    if (_admin) {
      _submit();
      return;
    }
    setState(() => _showErrors = true);
    final ok = switch (_step) {
      0 => _accountForm.currentState!.validate(),
      1 => _detailsForm.currentState!.validate() && _detailsComplete,
      _ => _priceForm.currentState!.validate() && _consent,
    };
    if (!ok) return;
    if (_step < 2) {
      setState(() {
        _step++;
        _showErrors = false;
      });
    } else {
      _submit();
    }
  }

  /// The province in the list of cities, whichever way the phone spells it ("Izmir", "İzmir").
  static String? _matchCity(String name) {
    String fold(String v) => v
        .toLowerCase()
        .replaceAll('ı', 'i')
        .replaceAll('İ', 'i')
        .replaceAll('ş', 's')
        .replaceAll('ğ', 'g')
        .replaceAll('ü', 'u')
        .replaceAll('ö', 'o')
        .replaceAll('ç', 'c');
    for (final c in kTurkishCities) {
      if (fold(c) == fold(name)) return c;
    }
    return null;
  }

  /// Fills province, district and address from where the phone is, and remembers the coordinates
  /// so customers nearby can find this usta. Returns false when the phone could not say.
  Future<bool> _fillFromLocation({required bool fillAddress}) async {
    final found = await ref
        .read(locationServiceProvider)
        .getCurrentLocation(requestPermission: true);
    if (found is! LocationFound) return false;
    final place = await ref
        .read(placeNameServiceProvider)
        .detailsFor(found.location);
    if (!mounted) return false;
    setState(() {
      _lat = found.location.lat;
      _lng = found.location.lng;
      if (place != null) {
        _city = _matchCity(place.city) ?? _city;
        _district.text = place.district;
        if (fillAddress && place.address.isNotEmpty) {
          _address.text = place.address;
        }
      }
    });
    return place != null;
  }

  Future<void> _useMyLocation() async {
    setState(() => _locating = true);
    final ok = await _fillFromLocation(fillAddress: _hasShop != false);
    if (!mounted) return;
    setState(() => _locating = false);
    if (!ok) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text(
              'Konumunu alamadık. Konum iznini açıp tekrar dene ya da elle yaz.',
            ),
          ),
        );
    }
  }

  bool get _detailsComplete =>
      _service != null && _city != null && _hasShop != null;

  Future<void> _submit() async {
    final admin = _admin;
    setState(() {
      _busy = true;
      _error = null;
    });
    // The demo sign-in takes its place from the phone, not from a made-up address.
    if (admin && _lat == null) {
      await _fillFromLocation(fillAddress: _address.text.trim().isEmpty);
    }
    final service = _service ?? kServices.first;
    final shop = _hasShop ?? true;
    final city = _city ?? 'İstanbul';
    final application = ProviderApplication(
      businessName: admin && _business.text.trim().length < 3
          ? 'Admin Usta'
          : _business.text.trim(),
      phoneNumber: admin && _phone.text.trim().length < 10
          ? '05550000000'
          : _phone.text.trim(),
      mainType: service.mainType,
      subType: service.subType,
      city: city,
      district: admin && _district.text.trim().length < 2
          ? 'Kadıköy'
          : _district.text.trim(),
      address: shop
          ? (admin && _address.text.trim().isEmpty
                ? 'Moda Caddesi No:1, Kadıköy'
                : _address.text.trim())
          : '',
      about: admin && _about.text.trim().length < 20
          ? 'Bu bir demo usta hesabıdır.'
          : _about.text.trim(),
      serviceAreas: shop
          ? const []
          : _areas.text
                .split(',')
                .map((s) => s.trim())
                .where((s) => s.isNotEmpty && !isAdminToken(s))
                .toList(),
      priceList: _admin ? const [] : collectPrices(_prices),
      demo: admin,
      lat: _lat,
      lng: _lng,
    );
    try {
      final auth = ref.read(authProvider.notifier);
      if (_upgrade) {
        await auth.upgradeToProvider(application);
      } else {
        await auth.registerProvider(
          name: admin && _name.text.trim().length < 5
              ? 'Admin Usta'
              : _name.text,
          phone: application.phoneNumber,
          email: admin && !_email.text.contains('@')
              ? 'admin@usta.app'
              : _email.text,
          password: admin && _password.text.length < 6
              ? 'admin'
              : _password.text,
          application: application,
        );
      }
      if (mounted) setState(() => _step = 3);
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
    if (_step == 3) {
      return _Done(providerId: ref.read(authProvider).account?.providerId);
    }
    final gutter = context.ui.gutter;
    final stepCount = _upgrade ? 2 : 3;
    final shown = _step - _firstStep + 1;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Geri',
          icon: const UstaIcon(UstaIcons.arrowLeft, size: 26),
          onPressed: _busy ? null : _back,
        ),
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: ListView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: EdgeInsets.fromLTRB(gutter, 0, gutter, AppSpacing.xl),
                children: [
                  Text(
                    'Adım $shown / $stepCount',
                    style: AppTypography.label.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Semantics(
                    header: true,
                    child: Text(switch (_step) {
                      0 => 'Hesabını oluştur',
                      1 => 'Usta bilgilerin',
                      _ => 'Fiyat listen',
                    }, style: AppTypography.display),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    switch (_step) {
                      0 => 'Giriş yapmak ve müşterilerle yazışmak için kullanacaksın.',
                      1 => 'Müşteriler seni bu bilgilerle tanıyacak. Hepsi gerekli.',
                      _ => 'İsteğe bağlı. Fiyat yazarsan müşteriler seni daha kolay seçer.',
                    },
                    style: AppTypography.body.copyWith(
                      color: AppColors.inkMuted,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                  if (_step == 0) _accountStep(),
                  if (_step == 1) _detailsStep(),
                  if (_step == 2) _priceStep(),
                  if (_error != null) ...[
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      _error!,
                      style: AppTypography.body.copyWith(
                        color: AppColors.danger,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                gutter,
                AppSpacing.sm,
                gutter,
                AppSpacing.lg,
              ),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _busy ? null : _next,
                  child: _busy
                      ? SizedBox.square(
                          dimension: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: AppColors.onPrimary,
                          ),
                        )
                      : Text(_step == 2 ? 'Kaydı tamamla' : 'Devam'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _accountStep() => Form(
    key: _accountForm,
    child: Column(
      children: [
        TextFormField(
          controller: _name,
          textCapitalization: TextCapitalization.words,
          textInputAction: TextInputAction.next,
          autofillHints: const [AutofillHints.name],
          decoration: const InputDecoration(labelText: 'Ad soyad'),
          validator: Validators.name,
        ),
        const SizedBox(height: AppSpacing.lg),
        TextFormField(
          controller: _phone,
          keyboardType: TextInputType.phone,
          textInputAction: TextInputAction.next,
          autofillHints: const [AutofillHints.telephoneNumber],
          decoration: const InputDecoration(
            labelText: 'Telefon',
            hintText: '05XX XXX XX XX',
            helperText: 'Müşteriler seni bu numaradan arayacak.',
          ),
          validator: Validators.phone,
        ),
        const SizedBox(height: AppSpacing.lg),
        TextFormField(
          controller: _email,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          autofillHints: const [AutofillHints.email],
          decoration: const InputDecoration(labelText: 'E-posta'),
          validator: Validators.email,
        ),
        const SizedBox(height: AppSpacing.lg),
        TextFormField(
          controller: _password,
          obscureText: _hidden,
          textInputAction: TextInputAction.done,
          autofillHints: const [AutofillHints.newPassword],
          decoration: InputDecoration(
            labelText: 'Şifre',
            helperText: 'En az 6 karakter',
            suffixIcon: TextButton(
              onPressed: () => setState(() => _hidden = !_hidden),
              child: Text(_hidden ? 'Göster' : 'Gizle'),
            ),
          ),
          validator: Validators.password,
        ),
      ],
    ),
  );

  Widget _detailsStep() => Form(
    key: _detailsForm,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: _business,
          textCapitalization: TextCapitalization.words,
          textInputAction: TextInputAction.next,
          decoration: const InputDecoration(
            labelText: 'Usta veya işletme adı',
            hintText: 'Örn. Yıldız Elektrik',
          ),
          validator: Validators.businessName,
        ),
        const SizedBox(height: AppSpacing.xl),
        Text('Hangi işi yapıyorsun?', style: AppTypography.titleSm),
        const SizedBox(height: AppSpacing.sm),
        ServiceGrid(
          selectedId: _service?.id,
          onSelect: (s) => setState(() => _service = s),
        ),
        _FieldError(
          show: _showErrors && _service == null,
          text: 'Lütfen yaptığın işi seç.',
        ),
        const SizedBox(height: AppSpacing.xl),
        Text('Nerede çalışıyorsun?', style: AppTypography.titleSm),
        const SizedBox(height: AppSpacing.sm),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _locating ? null : _useMyLocation,
            icon: _locating
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : UstaIcon(UstaIcons.locate, size: 20),
            label: const Text('Konumumu kullan'),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        _PickerRow(
          label: 'İl',
          value: _city,
          placeholder: 'İlini seç',
          onTap: () async {
            final c = await pickCity(context, selected: _city);
            if (c != null) setState(() => _city = c);
          },
        ),
        _FieldError(
          show: _showErrors && _city == null,
          text: 'Lütfen ilini seç.',
        ),
        const SizedBox(height: AppSpacing.lg),
        TextFormField(
          controller: _district,
          textCapitalization: TextCapitalization.words,
          textInputAction: TextInputAction.next,
          decoration: const InputDecoration(labelText: 'İlçe'),
          validator: (v) => Validators.required(v, 'İlçeni yaz.'),
        ),
        const SizedBox(height: AppSpacing.xl),
        Text('Nasıl çalışıyorsun?', style: AppTypography.titleSm),
        const SizedBox(height: AppSpacing.sm),
        ChoiceTile(
          label: 'Dükkânım ya da ofisim var',
          caption: 'Müşteriler adresimi görür, Yol Tarifi alabilir.',
          selected: _hasShop == true,
          onTap: () => setState(() => _hasShop = true),
        ),
        const SizedBox(height: AppSpacing.sm),
        ChoiceTile(
          label: 'Müşterinin adresine giderim',
          caption: 'Hizmet verdiğin bölgeleri yazarsın.',
          selected: _hasShop == false,
          onTap: () => setState(() => _hasShop = false),
        ),
        _FieldError(
          show: _showErrors && _hasShop == null,
          text: 'Lütfen bir seçenek seç.',
        ),
        if (_hasShop == true) ...[
          const SizedBox(height: AppSpacing.lg),
          TextFormField(
            controller: _address,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: 'Açık adres',
              hintText: 'Mahalle, cadde, no',
            ),
            validator: (v) =>
                Validators.required(v, 'Açık adresini yaz.', min: 8),
          ),
        ],
        if (_hasShop == false) ...[
          const SizedBox(height: AppSpacing.lg),
          TextFormField(
            controller: _areas,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: 'Hizmet verdiğin bölgeler',
              hintText: 'Kadıköy, Ataşehir, Üsküdar',
              helperText: 'İlçeleri virgülle ayır.',
            ),
            validator: (v) =>
                Validators.required(v, 'En az bir bölge yaz.', min: 3),
          ),
        ],
        const SizedBox(height: AppSpacing.xl),
        TextFormField(
          controller: _about,
          minLines: 4,
          maxLines: 6,
          maxLength: 500,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(
            labelText: 'Kendini tanıt',
            hintText: 'Kaç yıldır çalışıyorsun, neleri yaparsın?',
          ),
          validator: (v) => Validators.required(
            v,
            'Kendini birkaç cümleyle tanıt (en az 20 karakter).',
            min: 20,
          ),
        ),
      ],
    ),
  );

  Widget _priceStep() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Form(
        key: _priceForm,
        child: PriceListEditor(rows: _prices),
      ),
      const SizedBox(height: AppSpacing.md),
      ConsentCheckbox(
        value: _consent,
        errorText: _showErrors && !_consent
            ? 'Devam etmek için metinleri kabul etmelisin.'
            : null,
        onChanged: (v) => setState(() => _consent = v),
      ),
      const SizedBox(height: AppSpacing.md),
      Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.surfaceMuted,
          borderRadius: AppRadius.borderMd,
        ),
        child: Text(
          'Önemli: Usta bir ilan platformudur. İşin kalitesi, ödeme ve müşteriyle anlaşmazlıklar tamamen senin sorumluluğundadır.',
          style: AppTypography.bodySm.copyWith(color: AppColors.ink),
        ),
      ),
    ],
  );
}

class _FieldError extends StatelessWidget {
  const _FieldError({required this.show, required this.text});

  final bool show;
  final String text;

  @override
  Widget build(BuildContext context) => show
      ? Padding(
          padding: const EdgeInsets.only(
            top: AppSpacing.xs,
            left: AppSpacing.xs,
          ),
          child: Text(
            text,
            style: AppTypography.bodySm.copyWith(color: AppColors.danger),
          ),
        )
      : const SizedBox.shrink();
}

class _PickerRow extends StatelessWidget {
  const _PickerRow({
    required this.label,
    required this.value,
    required this.placeholder,
    required this.onTap,
  });

  final String label;
  final String? value;
  final String placeholder;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: '$label: ${value ?? placeholder}',
    excludeSemantics: true,
    child: Material(
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.borderMd,
        side: AppBorders.strong,
      ),
      child: InkWell(
        borderRadius: AppRadius.borderMd,
        onTap: onTap,
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: context.ui.rowHeight),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    value ?? placeholder,
                    style: AppTypography.body.copyWith(
                      color: value == null
                          ? AppColors.inkSubtle
                          : AppColors.ink,
                    ),
                  ),
                ),
                const UstaIcon(UstaIcons.chevronDown, size: 20),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

class _Done extends StatelessWidget {
  const _Done({required this.providerId});

  final String? providerId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(context.ui.gutter),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              UstaIcon(
                UstaIcons.checkCircle,
                size: 72,
                color: AppColors.success,
              ),
              const SizedBox(height: AppSpacing.xl),
              Text(
                'Kaydın tamamlandı',
                style: AppTypography.display,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Profilin artık müşterilere görünüyor. Gelen talepleri “Talepler” sekmesinde göreceksin.',
                style: AppTypography.body.copyWith(color: AppColors.inkMuted),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xxl),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => context.go('/'),
                  child: const Text('Ana sayfaya git'),
                ),
              ),
              if (providerId != null) ...[
                const SizedBox(height: AppSpacing.sm),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () {
                      context.go('/');
                      context.push('/usta/$providerId');
                    },
                    child: const Text('Profilimi gör'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
