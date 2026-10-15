import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/accessibility/ui_scale.dart';
import '../../core/config/app_config.dart';
import '../../core/errors/app_failure.dart';
import '../../core/icons/usta_icon.dart';
import '../../core/icons/usta_icons.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/validators.dart';
import '../../core/widgets/choice_tile.dart';
import '../../core/widgets/network_image.dart';
import '../../core/widgets/state_views.dart';
import '../../data/models/usta.dart';
import '../../data/providers.dart';
import '../auth/auth_controller.dart';
import '../auth/widgets/price_list_editor.dart';
import '../discovery/discovery_providers.dart';

/// "Sayfamı düzenle": an usta keeps their own listing up to date: introduction, where they work,
/// the price list and work photos. Photos upload immediately; the rest saves with the button.
class ProfileEditScreen extends ConsumerWidget {
  const ProfileEditScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final providerId = ref.watch(
      authProvider.select((s) => s.account?.providerId),
    );
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Geri',
          icon: const UstaIcon(UstaIcons.arrowLeft, size: 26),
          onPressed: () =>
              context.canPop() ? context.pop() : context.go('/profile'),
        ),
      ),
      body: providerId == null
          ? Center(
              child: Text(
                'Düzenlenecek bir usta sayfan yok.',
                style: AppTypography.body,
              ),
            )
          : ref
                .watch(ustaDetailProvider(providerId))
                .when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(
                    child: ErrorStateView(
                      failure: AppFailure.from(e),
                      onRetry: () =>
                          ref.invalidate(ustaDetailProvider(providerId)),
                    ),
                  ),
                  data: (usta) => ProfileEditForm(usta: usta),
                ),
    );
  }
}

/// The editing form. On its own page it closes after saving; inside the "Sayfam" tab ([embedded])
/// it stays, with [header] shown above it.
class ProfileEditForm extends ConsumerStatefulWidget {
  const ProfileEditForm({
    super.key,
    required this.usta,
    this.embedded = false,
    this.header = const [],
  });

  final Usta usta;
  final bool embedded;
  final List<Widget> header;

  @override
  ConsumerState<ProfileEditForm> createState() => _EditFormState();
}

class _EditFormState extends ConsumerState<ProfileEditForm> {
  final _form = GlobalKey<FormState>();
  late final _phone = TextEditingController(text: widget.usta.phoneNumber);
  late final _about = TextEditingController(text: widget.usta.about);
  late final _address = TextEditingController(text: widget.usta.address);
  late final _areas = TextEditingController(
    text: widget.usta.serviceAreas.join(', '),
  );
  late final List<PriceRowData> _prices = _initialPrices();
  late bool _hasShop = widget.usta.hasShopAddress;
  late List<String> _photos = widget.usta.portfolioImages;
  bool _saving = false;
  bool _photoBusy = false;
  bool _profileBusy = false;
  late String? _profileImage = widget.usta.profileImage;

  List<PriceRowData> _initialPrices() {
    final rows = <PriceRowData>[
      for (final p in widget.usta.priceList)
        PriceRowData()
          ..name.text = p.serviceName
          ..min.text = p.minPrice?.round().toString() ?? ''
          ..max.text = p.maxPrice?.round().toString() ?? '',
    ];
    return rows.isEmpty ? [PriceRowData()] : rows;
  }

  @override
  void dispose() {
    for (final c in [_phone, _about, _address, _areas]) {
      c.dispose();
    }
    for (final p in _prices) {
      p.dispose();
    }
    super.dispose();
  }

  String get _me => ref.read(authProvider).account!.id;

  void _toast(String m) => ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(m)));

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await ref
          .read(ustaRepositoryProvider)
          .updateProfile(
            widget.usta.id,
            actorId: _me,
            about: _about.text.trim(),
            phoneNumber: _phone.text.trim(),
            address: _hasShop ? _address.text.trim() : '',
            serviceAreas: _hasShop
                ? const []
                : _areas.text
                      .split(',')
                      .map((s) => s.trim())
                      .where((s) => s.isNotEmpty)
                      .toList(),
            priceList: collectPrices(_prices),
          );
      ref.invalidate(ustaDetailProvider(widget.usta.id));
      if (mounted) {
        setState(() => _saving = false);
        _toast('Sayfan güncellendi.');
        if (!widget.embedded) {
          context.canPop() ? context.pop() : context.go('/profile');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        _toast(AppFailure.from(e).message);
      }
    }
  }

  Future<void> _changeProfilePhoto() async {
    final file = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 900,
      maxHeight: 900,
      imageQuality: 80,
    );
    if (file == null) return;
    setState(() => _profileBusy = true);
    try {
      final bytes = await file.readAsBytes();
      final updated = await ref
          .read(ustaRepositoryProvider)
          .setProfilePhoto(
            widget.usta.id,
            actorId: _me,
            contentType: _contentTypeOf(file.name),
            base64Data: base64Encode(bytes),
          );
      ref.invalidate(ustaDetailProvider(widget.usta.id));
      if (mounted) setState(() => _profileImage = updated.profileImage);
    } catch (e) {
      if (mounted) _toast(AppFailure.from(e).message);
    } finally {
      if (mounted) setState(() => _profileBusy = false);
    }
  }

  static String _contentTypeOf(String fileName) {
    final name = fileName.toLowerCase();
    return name.endsWith('.png')
        ? 'image/png'
        : name.endsWith('.webp')
        ? 'image/webp'
        : 'image/jpeg';
  }

  Future<void> _addPhoto() async {
    final file = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1400,
      maxHeight: 1400,
      imageQuality: 78,
    );
    if (file == null) return;
    setState(() => _photoBusy = true);
    try {
      final bytes = await file.readAsBytes();
      final name = file.name.toLowerCase();
      final updated = await ref
          .read(ustaRepositoryProvider)
          .addPhoto(
            widget.usta.id,
            actorId: _me,
            contentType: name.endsWith('.png')
                ? 'image/png'
                : name.endsWith('.webp')
                ? 'image/webp'
                : 'image/jpeg',
            base64Data: base64Encode(bytes),
          );
      ref.invalidate(ustaDetailProvider(widget.usta.id));
      if (mounted) setState(() => _photos = updated.portfolioImages);
    } catch (e) {
      if (mounted) _toast(AppFailure.from(e).message);
    } finally {
      if (mounted) setState(() => _photoBusy = false);
    }
  }

  Future<void> _removePhoto(String url) async {
    setState(() => _photoBusy = true);
    try {
      final updated = await ref
          .read(ustaRepositoryProvider)
          .removePhoto(
            widget.usta.id,
            actorId: _me,
            path: url.replaceFirst(AppConfig.apiBaseUrl, ''),
          );
      ref.invalidate(ustaDetailProvider(widget.usta.id));
      if (mounted) setState(() => _photos = updated.portfolioImages);
    } catch (e) {
      if (mounted) _toast(AppFailure.from(e).message);
    } finally {
      if (mounted) setState(() => _photoBusy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final gutter = context.ui.gutter;
    return Form(
      key: _form,
      child: ListView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: EdgeInsets.fromLTRB(gutter, 0, gutter, AppSpacing.xxxl),
        children: [
          if (widget.embedded)
            ...widget.header
          else ...[
            Semantics(
              header: true,
              child: Text('Sayfamı düzenle', style: AppTypography.display),
            ),
            const SizedBox(height: AppSpacing.xl),
          ],
          Text('Profil fotoğrafı', style: AppTypography.title),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Yüzün ya da işletmenin logosu. Müşteriler seni bununla tanır.',
            style: AppTypography.bodySm,
          ),
          const SizedBox(height: AppSpacing.md),
          _ProfilePhotoRow(
            url: _profileImage,
            busy: _profileBusy,
            onPick: _changeProfilePhoto,
          ),
          const SizedBox(height: AppSpacing.xxl),
          Text('İş fotoğrafları', style: AppTypography.title),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Müşteriler yaptığın işleri görmek ister. En fazla 12 fotoğraf.',
            style: AppTypography.bodySm,
          ),
          const SizedBox(height: AppSpacing.md),
          _PhotoGrid(
            photos: _photos,
            busy: _photoBusy,
            onAdd: _addPhoto,
            onRemove: _removePhoto,
          ),
          const SizedBox(height: AppSpacing.xxl),
          Text('Tanıtım ve iletişim', style: AppTypography.title),
          const SizedBox(height: AppSpacing.md),
          TextFormField(
            controller: _phone,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              labelText: 'Telefon',
              hintText: '05XX XXX XX XX',
            ),
            validator: Validators.phone,
          ),
          const SizedBox(height: AppSpacing.lg),
          TextFormField(
            controller: _about,
            minLines: 4,
            maxLines: 6,
            maxLength: 500,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(labelText: 'Kendini tanıt'),
            validator: (v) => Validators.required(
              v,
              'Kendini birkaç cümleyle tanıt (en az 20 karakter).',
              min: 20,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text('Nerede çalışıyorsun?', style: AppTypography.title),
          const SizedBox(height: AppSpacing.md),
          ChoiceTile(
            label: 'Dükkânım ya da ofisim var',
            selected: _hasShop,
            onTap: () => setState(() => _hasShop = true),
          ),
          const SizedBox(height: AppSpacing.sm),
          ChoiceTile(
            label: 'Müşterinin adresine giderim',
            selected: !_hasShop,
            onTap: () => setState(() => _hasShop = false),
          ),
          const SizedBox(height: AppSpacing.lg),
          if (_hasShop)
            TextFormField(
              controller: _address,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Açık adres'),
              validator: (v) =>
                  Validators.required(v, 'Açık adresini yaz.', min: 8),
            )
          else
            TextFormField(
              controller: _areas,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Hizmet verdiğin bölgeler',
                hintText: 'Kadıköy, Ataşehir, Üsküdar',
                helperText: 'İlçeleri virgülle ayır.',
              ),
              validator: (v) =>
                  Validators.required(v, 'En az bir bölge yaz.', min: 3),
            ),
          const SizedBox(height: AppSpacing.xxl),
          Text('Fiyat listesi', style: AppTypography.title),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'İsteğe bağlı. Makul bir aralık yaz; müşteriler seni daha kolay seçer.',
            style: AppTypography.bodySm,
          ),
          const SizedBox(height: AppSpacing.md),
          PriceListEditor(rows: _prices),
          const SizedBox(height: AppSpacing.lg),
          FilledButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? SizedBox.square(
                    dimension: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: AppColors.onPrimary,
                    ),
                  )
                : const Text('Kaydet'),
          ),
        ],
      ),
    );
  }
}

class _ProfilePhotoRow extends StatelessWidget {
  const _ProfilePhotoRow({
    required this.url,
    required this.busy,
    required this.onPick,
  });

  final String? url;
  final bool busy;
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        ClipRRect(
          borderRadius: AppRadius.borderLg,
          child: SizedBox.square(
            dimension: 88,
            child: url == null
                ? ColoredBox(
                    color: AppColors.primarySoft,
                    child: Center(
                      child: UstaIcon(
                        UstaIcons.user,
                        size: 36,
                        color: AppColors.primary,
                      ),
                    ),
                  )
                : AppNetworkImage(url: url!, width: 88, height: 88),
          ),
        ),
        const SizedBox(width: AppSpacing.lg),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: busy ? null : onPick,
            icon: busy
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : UstaIcon(UstaIcons.photoCamera, size: 20),
            label: Text(url == null ? 'Fotoğraf ekle' : 'Fotoğrafı değiştir'),
          ),
        ),
      ],
    );
  }
}

class _PhotoGrid extends StatelessWidget {
  const _PhotoGrid({
    required this.photos,
    required this.busy,
    required this.onAdd,
    required this.onRemove,
  });

  final List<String> photos;
  final bool busy;
  final VoidCallback onAdd;
  final void Function(String url) onRemove;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        const gap = AppSpacing.sm;
        final side = (c.maxWidth - gap * 2) / 3;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final url in photos)
              SizedBox.square(
                dimension: side,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    AppNetworkImage(
                      url: url,
                      width: side,
                      height: side,
                      cacheWidth: (side * 2.5).round(),
                      borderRadius: AppRadius.borderSm,
                    ),
                    Positioned(
                      top: 2,
                      right: 2,
                      child: Semantics(
                        button: true,
                        label: 'Fotoğrafı sil',
                        child: GestureDetector(
                          onTap: busy ? null : () => onRemove(url),
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: const BoxDecoration(
                              color: AppColors.scrim,
                              shape: BoxShape.circle,
                            ),
                            child: UstaIcon(
                              UstaIcons.trash,
                              size: 18,
                              color: AppColors.onPrimary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            if (photos.length < 12)
              SizedBox.square(
                dimension: side,
                child: Material(
                  color: AppColors.primarySoft,
                  shape: RoundedRectangleBorder(
                    borderRadius: AppRadius.borderSm,
                    side: BorderSide(
                      color: AppColors.primary.withValues(alpha: 0.4),
                      width: 1.5,
                    ),
                  ),
                  child: InkWell(
                    borderRadius: AppRadius.borderSm,
                    onTap: busy ? null : onAdd,
                    child: Center(
                      child: busy
                          ? const SizedBox.square(
                              dimension: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                              ),
                            )
                          : Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                UstaIcon(
                                  UstaIcons.plus,
                                  size: 28,
                                  color: AppColors.primary,
                                ),
                                const SizedBox(height: AppSpacing.xs),
                                Text(
                                  'Ekle',
                                  style: AppTypography.label.copyWith(
                                    color: AppColors.primary,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
