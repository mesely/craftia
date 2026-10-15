import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/accessibility/ui_scale.dart';
import '../../core/constants/services.dart';
import '../../core/errors/app_failure.dart';
import '../../core/icons/usta_icon.dart';
import '../../core/icons/usta_icons.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/contact_launcher.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/app_sheet.dart';
import '../../core/widgets/choice_tile.dart';
import '../../core/widgets/state_views.dart';
import '../../data/models/chat.dart';
import '../../data/models/complaint.dart';
import '../../data/models/service_request.dart';
import '../auth/auth_controller.dart';
import '../orders/requests_controller.dart';
import '../provider/image_viewer.dart';
import 'chat_controller.dart';
import 'message_bubble.dart';
import 'quick_replies.dart';
import 'swipe_to_reply.dart';

/// Mesajlaşma: the request is the first message; both sides can answer, reply to a message by
/// swiping it, edit or delete their own, send photos and pick ready-made sentences. Calling
/// and WhatsApp stay one tap away, so there is never a reason to leave the app just to talk.
class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key, required this.conversationId});

  final String conversationId;

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _text = TextEditingController();
  final _focus = FocusNode();

  @override
  void dispose() {
    _text.dispose();
    _focus.dispose();
    super.dispose();
  }

  ChatController get _controller =>
      ref.read(chatProvider(widget.conversationId).notifier);

  void _toast(String message) => ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));

  Future<void> _send() async {
    final text = _text.text;
    if (text.trim().isEmpty) return;
    try {
      await _controller.submit(text);
      _text.clear();
    } catch (e) {
      if (mounted) _toast(AppFailure.from(e).message);
    }
  }

  Future<void> _pickPhoto() async {
    final source = await showAppSheet<ImageSource>(
      context,
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
          context.ui.gutter,
          0,
          context.ui.gutter,
          AppSpacing.xxl,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Fotoğraf gönder', style: AppTypography.title),
            const SizedBox(height: AppSpacing.lg),
            ChoiceTile(
              leading: UstaIcons.photoCamera,
              label: 'Fotoğraf çek',
              selected: false,
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            const SizedBox(height: AppSpacing.sm),
            ChoiceTile(
              leading: UstaIcons.image,
              label: 'Galeriden seç',
              selected: false,
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;
    try {
      final file = await ImagePicker().pickImage(
        source: source,
        maxWidth: 1280,
        maxHeight: 1280,
        imageQuality: 72,
      );
      if (file == null) return;
      final bytes = await file.readAsBytes();
      final name = file.name.toLowerCase();
      final type = name.endsWith('.png')
          ? 'image/png'
          : name.endsWith('.webp')
          ? 'image/webp'
          : 'image/jpeg';
      await _controller.sendPhoto(bytes, type);
    } catch (e) {
      if (mounted) {
        _toast(
          e is AppFailure ? e.message : 'Fotoğraf gönderilemedi. Tekrar dene.',
        );
      }
    }
  }

  Future<void> _quickReplies(ConversationInfo info) async {
    final options = quickReplies(
      asProvider: info.viewerIsProvider,
      subType: info.subject,
    );
    final picked = await showAppSheet<String>(
      context,
      builder: (ctx) => ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(ctx).height * 0.8,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SheetTitle(
              'Hazır mesajlar',
              subtitle: 'Birine dokun, mesaj kutusuna eklensin. Göndermeden önce değiştirebilirsin.',
            ),
            Flexible(
              child: ListView.separated(
                padding: EdgeInsets.fromLTRB(
                  context.ui.gutter,
                  0,
                  context.ui.gutter,
                  AppSpacing.xxl,
                ),
                itemCount: options.length,
                separatorBuilder: (_, _) =>
                    const SizedBox(height: AppSpacing.sm),
                itemBuilder: (_, i) => ChoiceTile(
                  label: options[i],
                  selected: false,
                  onTap: () => Navigator.pop(ctx, options[i]),
                ),
              ),
            ),
          ],
        ),
      ),
    );
    if (picked != null && mounted) {
      _text.text = picked;
      _text.selection = TextSelection.collapsed(offset: picked.length);
      _focus.requestFocus();
    }
  }

  Future<void> _messageMenu(
    ChatMessage m,
    ConversationInfo info,
    String me,
  ) async {
    if (m.kind == MessageKind.system) return;
    final mine = m.senderId == me;
    final canEdit = mine && m.kind == MessageKind.text && !m.isDeleted;
    final canDelete = mine && m.kind != MessageKind.request && !m.isDeleted;
    final action = await showAppSheet<String>(
      context,
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
          context.ui.gutter,
          0,
          context.ui.gutter,
          AppSpacing.xxl,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!m.isDeleted) ...[
              ChoiceTile(
                leading: UstaIcons.reply,
                label: 'Yanıtla',
                selected: false,
                onTap: () => Navigator.pop(ctx, 'reply'),
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
            if (!m.isDeleted && m.kind != MessageKind.image) ...[
              ChoiceTile(
                leading: UstaIcons.copy,
                label: 'Kopyala',
                selected: false,
                onTap: () => Navigator.pop(ctx, 'copy'),
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
            if (canEdit) ...[
              ChoiceTile(
                leading: UstaIcons.pencil,
                label: 'Düzenle',
                selected: false,
                onTap: () => Navigator.pop(ctx, 'edit'),
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
            if (canDelete) ...[
              ChoiceTile(
                leading: UstaIcons.trash,
                label: 'Sil',
                caption: 'Mesajın yerinde “Mesaj silindi” görünür',
                selected: false,
                onTap: () => Navigator.pop(ctx, 'delete'),
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
            if (!mine && !m.isDeleted)
              ChoiceTile(
                leading: UstaIcons.flag,
                label: 'Bu mesajı şikayet et',
                selected: false,
                onTap: () => Navigator.pop(ctx, 'report'),
              ),
          ],
        ),
      ),
    );
    if (action == null || !mounted) return;
    switch (action) {
      case 'reply':
        _controller.startReply(m);
        _focus.requestFocus();
      case 'copy':
        await Clipboard.setData(
          ClipboardData(
            text: m.kind == MessageKind.request ? m.requestBody : m.text,
          ),
        );
        if (mounted) _toast('Mesaj kopyalandı.');
      case 'edit':
        _controller.startEdit(m);
        _text.text = m.text;
        _text.selection = TextSelection.collapsed(offset: m.text.length);
        _focus.requestFocus();
      case 'delete':
        try {
          await _controller.delete(m);
        } catch (e) {
          if (mounted) _toast(AppFailure.from(e).message);
        }
      case 'report':
        context.push(
          '/complaint',
          extra: ComplaintTarget(
            type: ComplaintTargetType.message,
            id: m.id,
            name: info.otherName,
            conversationId: info.id,
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(chatProvider(widget.conversationId));
    final account = ref.watch(authProvider.select((s) => s.account));
    final info = state.info;
    final me = account?.id ?? '';
    final request = ref
        .watch(requestsProvider)
        .value
        ?.where((r) => r.conversationId == widget.conversationId)
        .firstOrNull;

    if (account == null) {
      return Scaffold(
        appBar: AppBar(leading: _back(context)),
        body: Center(
          child: FilledButton(
            onPressed: () => context.push('/login'),
            child: const Text('Giriş yap'),
          ),
        ),
      );
    }
    if (state.loading) {
      return Scaffold(
        appBar: AppBar(leading: _back(context)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (info == null) {
      return Scaffold(
        appBar: AppBar(leading: _back(context)),
        body: Center(
          child: ErrorStateView(
            title: 'Sohbeti açamadık',
            failure: state.failure ?? AppFailure.unknown,
            onRetry: () =>
                ref.read(chatProvider(widget.conversationId).notifier).retry(),
          ),
        ),
      );
    }

    final phone = info.viewerIsProvider
        ? (request?.contactPhone ?? '')
        : (request?.providerPhone ?? '');
    final items = _withDays(state.messages);

    return Scaffold(
      appBar: AppBar(
        leading: _back(context),
        titleSpacing: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              info.otherName,
              style: AppTypography.titleSm,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (info.subject.isNotEmpty)
              Text(
                serviceFor(subType: info.subject)?.label ?? info.subject,
                style: AppTypography.bodySm,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
        actions: [
          if (phone.isNotEmpty)
            TextButton.icon(
              icon: const UstaIcon(UstaIcons.phone, size: 22),
              label: const Text('Ara'),
              onPressed: () async {
                final ok = await ref.read(contactLauncherProvider).call(phone);
                if (!ok && mounted)
                  _toast('Arama başlatılamadı. Numara: ${formatPhone(phone)}');
              },
            ),
          _Menu(info: info, request: request, phone: phone, onToast: _toast),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            const _RecordNotice(),
            if (request != null) _StatusBar(request: request, info: info),
            if (!info.providerOnApp && !info.viewerIsProvider)
              _NotOnAppNotice(phone: phone, onToast: _toast),
            Expanded(
              child: ListView.builder(
                reverse: true,
                padding: EdgeInsets.symmetric(
                  horizontal: context.ui.gutter - 6,
                  vertical: AppSpacing.sm,
                ),
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[items.length - 1 - index];
                  if (item is DateTime) return _DayLabel(day: item);
                  final m = item as ChatMessage;
                  final mine = m.senderId == me;
                  final target = state.messageById(m.replyToId);
                  final bubble = MessageBubble(
                    message: m,
                    mine: mine,
                    replyTarget: target,
                    replyAuthor: target == null
                        ? ''
                        : (target.senderId == me ? 'Sen' : info.otherName),
                    onLongPress: () => _messageMenu(m, info, me),
                    onImageTap: (url) => openImageViewer(context, [url], 0),
                  );
                  if (m.kind == MessageKind.system || m.isDeleted)
                    return bubble;
                  return SwipeToReply(
                    onReply: () {
                      ref
                          .read(chatProvider(widget.conversationId).notifier)
                          .startReply(m);
                      _focus.requestFocus();
                    },
                    child: bubble,
                  );
                },
              ),
            ),
            _Composer(
              controller: _text,
              focus: _focus,
              state: state,
              closed:
                  request != null &&
                  (request.status == RequestStatus.cancelled ||
                      request.status == RequestStatus.completed),
              me: me,
              info: info,
              onSend: _send,
              onPhoto: _pickPhoto,
              onQuick: () => _quickReplies(info),
              onCancelReply: () => ref
                  .read(chatProvider(widget.conversationId).notifier)
                  .cancelReply(),
              onCancelEdit: () {
                ref
                    .read(chatProvider(widget.conversationId).notifier)
                    .cancelEdit();
                _text.clear();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _back(BuildContext context) => IconButton(
    tooltip: 'Geri',
    icon: const UstaIcon(UstaIcons.arrowLeft, size: 26),
    onPressed: () => context.canPop() ? context.pop() : context.go('/requests'),
  );

  /// Messages with a [DateTime] marker before the first message of each day.
  static List<Object> _withDays(List<ChatMessage> messages) {
    final out = <Object>[];
    DateTime? last;
    for (final m in messages) {
      final day = DateTime(
        m.createdAt.year,
        m.createdAt.month,
        m.createdAt.day,
      );
      if (last == null || day != last) {
        out.add(day);
        last = day;
      }
      out.add(m);
    }
    return out;
  }
}

class _DayLabel extends StatelessWidget {
  const _DayLabel({required this.day});

  final DateTime day;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
    child: Center(
      child: Text(formatDayLabel(day), style: AppTypography.caption),
    ),
  );
}

/// One calm line that says, before anyone writes, that the conversation is recorded.
class _RecordNotice extends StatelessWidget {
  const _RecordNotice();

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: () => context.push('/legal/kvkk'),
    child: Container(
      width: double.infinity,
      color: AppColors.surfaceMuted,
      padding: EdgeInsets.symmetric(
        horizontal: context.ui.gutter,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          UstaIcon(UstaIcons.lock, size: 16, color: AppColors.inkMuted),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              'Yazışmalar güvenlik için kaydedilir · Ayrıntı',
              style: AppTypography.caption,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    ),
  );
}

/// What state the request is in and the one thing that moves it forward.
class _StatusBar extends ConsumerWidget {
  const _StatusBar({required this.request, required this.info});

  final ServiceRequest request;
  final ConversationInfo info;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asProvider = info.viewerIsProvider;
    final controller = ref.read(requestsProvider.notifier);

    Future<void> change(RequestStatus s) async {
      try {
        await controller.changeStatus(request.id, s);
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(AppFailure.from(e).message)));
        }
      }
    }

    final (
      String? primary,
      RequestStatus? primaryTo,
      String? secondary,
      RequestStatus? secondaryTo,
    ) = switch ((request.status, asProvider)) {
      (RequestStatus.pending, true) => (
        'Kabul et',
        RequestStatus.accepted,
        'Reddet',
        RequestStatus.cancelled,
      ),
      (RequestStatus.accepted, true) => (
        'İş tamamlandı',
        RequestStatus.completed,
        null,
        null,
      ),
      (RequestStatus.accepted, false) => (
        'İş bitti',
        RequestStatus.completed,
        null,
        null,
      ),
      _ => (null, null, null, null),
    };

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: context.ui.gutter,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  request.status.label(asProvider: asProvider),
                  style: AppTypography.titleSm.copyWith(
                    color: AppColors.primary,
                  ),
                ),
                if (primary == null)
                  Text(
                    request.status.hint(asProvider: asProvider),
                    style: AppTypography.bodySm.copyWith(color: AppColors.ink),
                  ),
              ],
            ),
          ),
          if (primary != null) ...[
            if (secondary != null) ...[
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  minimumSize: Size(context.ui.tapTarget, context.ui.tapTarget),
                  backgroundColor: AppColors.surface,
                ),
                onPressed: () => change(secondaryTo!),
                child: Text(secondary),
              ),
              const SizedBox(width: AppSpacing.sm),
            ],
            FilledButton(
              style: FilledButton.styleFrom(
                minimumSize: Size(context.ui.tapTarget, context.ui.tapTarget),
              ),
              onPressed: () => change(primaryTo!),
              child: Text(primary),
            ),
          ],
        ],
      ),
    );
  }
}

class _NotOnAppNotice extends ConsumerWidget {
  const _NotOnAppNotice({required this.phone, required this.onToast});

  final String phone;
  final void Function(String) onToast;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final launcher = ref.read(contactLauncherProvider);
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: context.ui.gutter,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: AppColors.amberSoft,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Bu usta henüz Usta uygulamasını kullanmıyor.',
            style: AppTypography.label.copyWith(color: AppColors.amberInk),
          ),
          const SizedBox(height: 2),
          Text(
            'Mesajına geç yanıt verebilir. Hemen ulaşmak için ara ya da WhatsApp’tan yaz.',
            style: AppTypography.bodySm.copyWith(color: AppColors.ink),
          ),
          if (phone.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const UstaIcon(UstaIcons.phone, size: 20),
                    label: const Text('Ara'),
                    onPressed: () async {
                      if (!await launcher.call(phone))
                        onToast('Arama başlatılamadı.');
                    },
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const UstaIcon(UstaIcons.message, size: 20),
                    label: const Text('WhatsApp'),
                    onPressed: () async {
                      if (!await launcher.whatsapp(phone))
                        onToast('WhatsApp açılamadı.');
                    },
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _Menu extends ConsumerWidget {
  const _Menu({
    required this.info,
    required this.request,
    required this.phone,
    required this.onToast,
  });

  final ConversationInfo info;
  final ServiceRequest? request;
  final String phone;
  final void Function(String) onToast;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final canCancel =
        request != null &&
        (request!.status == RequestStatus.pending ||
            request!.status == RequestStatus.accepted);
    return PopupMenuButton<String>(
      tooltip: 'Diğer işlemler',
      icon: const UstaIcon(UstaIcons.more, size: 26),
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.borderMd),
      onSelected: (v) async {
        switch (v) {
          case 'whatsapp':
            final ok = await ref
                .read(contactLauncherProvider)
                .whatsapp(
                  phone,
                  text: info.viewerIsProvider ? null : 'Merhaba, Usta uygulamasındaki talebim hakkında yazıyorum.',
                );
            if (!ok) onToast('WhatsApp açılamadı.');
          case 'report':
            context.push(
              '/complaint',
              extra: ComplaintTarget(
                type: ComplaintTargetType.conversation,
                id: info.id,
                name: info.otherName,
                conversationId: info.id,
              ),
            );
          case 'cancel':
            try {
              await ref
                  .read(requestsProvider.notifier)
                  .changeStatus(request!.id, RequestStatus.cancelled);
            } catch (e) {
              onToast(AppFailure.from(e).message);
            }
        }
      },
      itemBuilder: (_) => [
        if (phone.isNotEmpty)
          const PopupMenuItem(
            value: 'whatsapp',
            child: Text('WhatsApp’tan yaz'),
          ),
        const PopupMenuItem(value: 'report', child: Text('Şikayet et')),
        if (canCancel)
          const PopupMenuItem(value: 'cancel', child: Text('Talebi iptal et')),
      ],
    );
  }
}

class _Composer extends StatelessWidget {
  const _Composer({
    required this.controller,
    required this.focus,
    required this.state,
    required this.closed,
    required this.me,
    required this.info,
    required this.onSend,
    required this.onPhoto,
    required this.onQuick,
    required this.onCancelReply,
    required this.onCancelEdit,
  });

  final TextEditingController controller;
  final FocusNode focus;
  final ChatState state;
  final bool closed;
  final String me;
  final ConversationInfo info;
  final VoidCallback onSend;
  final VoidCallback onPhoto;
  final VoidCallback onQuick;
  final VoidCallback onCancelReply;
  final VoidCallback onCancelEdit;

  @override
  Widget build(BuildContext context) {
    if (closed) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        child: Text(
          'Bu talep kapandı, yeni mesaj yazılamaz. Gerekirse yeni bir talep oluşturabilirsin.',
          style: AppTypography.bodySm,
          textAlign: TextAlign.center,
        ),
      );
    }
    final box = context.ui.tapTarget;
    final strip = state.editing != null
        ? ('Mesajı düzenliyorsun', state.editing!.text, onCancelEdit)
        : state.replyTo != null
        ? (
            'Yanıtlanıyor: ${state.replyTo!.senderId == me ? 'Sen' : info.otherName}',
            state.replyTo!.kind == MessageKind.image
                ? 'Fotoğraf'
                : state.replyTo!.kind == MessageKind.request
                ? state.replyTo!.requestBody
                : state.replyTo!.text,
            onCancelReply,
          )
        : null;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      padding: EdgeInsets.fromLTRB(
        AppSpacing.sm,
        AppSpacing.xs,
        AppSpacing.sm,
        AppSpacing.sm,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (strip != null)
            Container(
              margin: const EdgeInsets.only(bottom: AppSpacing.xs),
              padding: const EdgeInsets.only(left: AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.primarySoft,
                borderRadius: AppRadius.borderSm,
                border: Border(
                  left: BorderSide(color: AppColors.primary, width: 3),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          strip.$1,
                          style: AppTypography.caption.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          strip.$2,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.bodySm.copyWith(
                            color: AppColors.ink,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Vazgeç',
                    icon: const UstaIcon(UstaIcons.close, size: 20),
                    onPressed: strip.$3,
                  ),
                ],
              ),
            ),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              style: TextButton.styleFrom(
                minimumSize: Size(box, 40),
                visualDensity: VisualDensity.compact,
              ),
              icon: const UstaIcon(UstaIcons.requests, size: 18),
              label: const Text('Hazır mesajlar'),
              onPressed: onQuick,
            ),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              IconButton(
                tooltip: 'Fotoğraf gönder',
                style: IconButton.styleFrom(minimumSize: Size.square(box)),
                icon: UstaIcon(
                  UstaIcons.photoCamera,
                  size: 26,
                  color: AppColors.primary,
                ),
                onPressed: state.sending || state.editing != null
                    ? null
                    : onPhoto,
              ),
              Expanded(
                child: TextField(
                  controller: controller,
                  focusNode: focus,
                  minLines: 1,
                  maxLines: 5,
                  maxLength: 2000,
                  buildCounter: (
                    _, {
                    required currentLength,
                    required isFocused,
                    maxLength,
                  }) => null,
                  textCapitalization: TextCapitalization.sentences,
                  textInputAction: TextInputAction.newline,
                  style: AppTypography.body,
                  decoration: InputDecoration(
                    hintText: 'Mesaj yaz',
                    floatingLabelBehavior: FloatingLabelBehavior.never,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                      vertical: AppSpacing.md,
                    ),
                    constraints: BoxConstraints(minHeight: box),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              ListenableBuilder(
                listenable: controller,
                builder: (context, _) {
                  final empty = controller.text.trim().isEmpty;
                  return IconButton.filled(
                    tooltip: state.editing != null ? 'Kaydet' : 'Gönder',
                    style: IconButton.styleFrom(
                      minimumSize: Size.square(box),
                      backgroundColor: empty
                          ? AppColors.surfaceMuted
                          : AppColors.primary,
                    ),
                    icon: state.sending
                        ? SizedBox.square(
                            dimension: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: AppColors.onPrimary,
                            ),
                          )
                        : UstaIcon(
                            state.editing != null
                                ? UstaIcons.check
                                : UstaIcons.send,
                            size: 24,
                            color: empty
                                ? AppColors.inkSubtle
                                : AppColors.onPrimary,
                          ),
                    onPressed: empty || state.sending ? null : onSend,
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
