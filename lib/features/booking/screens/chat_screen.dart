import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../l10n/app_localizations.dart';
import '../../../models/enums.dart';
import '../../../models/models.dart';
import '../../../services/auth_provider.dart';
import '../providers/booking_provider.dart';

/// V4 Chat — fully themed (light/dark) + localized (EN/AR)
class ChatScreen extends StatefulWidget {
  final String bookingId;
  const ChatScreen({super.key, required this.bookingId});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _textCtrl   = TextEditingController();
  final _scrollCtrl = ScrollController();
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final provider = context.read<BookingProvider>();
      if (provider.booking?.id != widget.bookingId) {
        await provider.loadBooking(widget.bookingId);
      }
      final myId = context.read<AuthProvider>().currentProfile?.id;
      if (myId != null) {
        await provider.markMessagesRead(widget.bookingId, myId);
      }
      _scrollToBottom();
    });
  }

  @override
  void dispose() {
    _textCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _send() async {
    final text = _textCtrl.text.trim();
    if (text.isEmpty || _sending) return;
    final myId = context.read<AuthProvider>().currentProfile?.id;
    if (myId == null) return;
    setState(() => _sending = true);
    _textCtrl.clear();
    await context.read<BookingProvider>().sendMessage(
          bookingId: widget.bookingId,
          senderId: myId,
          text: text,
        );
    setState(() => _sending = false);
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final t    = AppLocalizations.of(context)!;
    final cs   = Theme.of(context).colorScheme;
    final myId = context.read<AuthProvider>().currentProfile?.id ?? '';

    return Scaffold(
      appBar: AppBar(
        title: Consumer<BookingProvider>(builder: (_, provider, __) {
          final owner   = provider.ownerProfile;
          final booking = provider.booking;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(owner?.fullName ?? t.chat,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
              if (booking != null) _StatusBadge(status: booking.status),
            ],
          );
        }),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline, size: 20),
            onPressed: () => context.push('/booking/${widget.bookingId}'),
          ),
        ],
      ),
      body: Column(children: [

        // Contact paths — shown to customer only
        Consumer<BookingProvider>(builder: (_, provider, __) {
          final booking = provider.booking;
          if (booking == null) return const SizedBox.shrink();
          final myIdLocal = context.read<AuthProvider>().currentProfile?.id;
          if (myIdLocal != booking.customerId) return const SizedBox.shrink();
          return _ContactBanner(ownerPhone: provider.ownerProfile?.phone);
        }),

        // Messages list — realtime from chat_messages
        Expanded(child: Consumer<BookingProvider>(
          builder: (context, provider, _) {
            final messages = provider.messages;
            if (provider.isLoading && messages.isEmpty) {
              return Center(child: CircularProgressIndicator(color: cs.secondary));
            }
            if (messages.isEmpty) return _EmptyState();
            WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
            return ListView.builder(
              controller: _scrollCtrl,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemCount: messages.length,
              itemBuilder: (_, i) {
                final msg      = messages[i];
                final isMe     = msg.senderId == myId;
                final showDate = i == 0 ||
                    !_sameDay(messages[i - 1].createdAt, msg.createdAt);
                return Column(children: [
                  if (showDate) _DateLabel(date: msg.createdAt),
                  _Bubble(msg: msg, isMe: isMe),
                ]);
              },
            );
          },
        )),

        // Input bar — INSERT chat_messages
        _InputBar(controller: _textCtrl, sending: _sending, onSend: _send),
      ]),
    );
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

// ──────────────────────────────────────────────────────────
// CONTACT BANNER
// ──────────────────────────────────────────────────────────
class _ContactBanner extends StatelessWidget {
  final String? ownerPhone;
  const _ContactBanner({this.ownerPhone});

  String? _intlPhone() {
    if (ownerPhone == null || ownerPhone!.trim().isEmpty) return null;
    final digits = ownerPhone!.replaceAll(RegExp(r'\D'), '');
    if (digits.startsWith('0'))  return '2$digits';
    if (digits.startsWith('20')) return digits;
    return digits;
  }

  Future<void> _openWhatsApp(BuildContext context) async {
    final t     = AppLocalizations.of(context)!;
    final phone = _intlPhone();
    if (phone == null) { _snack(context, t.ownerNoPhone); return; }
    final uri = Uri.parse('https://wa.me/$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      _snack(context, t.whatsappNotInstalled);
    }
  }

  Future<void> _callOwner(BuildContext context) async {
    final t     = AppLocalizations.of(context)!;
    final phone = ownerPhone?.trim();
    if (phone == null || phone.isEmpty) { _snack(context, t.ownerNoPhone); return; }
    final uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      _snack(context, t.cannotCall);
    }
  }

  void _snack(BuildContext ctx, String msg) =>
      ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text(msg)));

  @override
  Widget build(BuildContext context) {
    final t  = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        border: Border(bottom: BorderSide(color: cs.outlineVariant)),
      ),
      child: Row(children: [
        Text(t.contactVia,
            style: TextStyle(color: cs.onSurfaceVariant,
                fontSize: 11, fontWeight: FontWeight.w600)),
        const SizedBox(width: 10),
        _Pill(label: t.inApp,    color: cs.secondary, active: true,  onTap: () {}),
        const SizedBox(width: 8),
        _Pill(label: t.whatsapp, color: const Color(0xFF25D366), active: false,
            onTap: () => _openWhatsApp(context)),
        const SizedBox(width: 8),
        _Pill(label: t.call,     color: Colors.blue, active: false,
            onTap: () => _callOwner(context)),
      ]),
    );
  }
}

class _Pill extends StatelessWidget {
  final String label;
  final Color color;
  final bool active;
  final VoidCallback onTap;
  const _Pill({required this.label, required this.color,
      required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: active ? color : color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: active ? color : color.withValues(alpha: 0.3)),
        ),
        child: Text(label, style: TextStyle(
            fontSize: 11, fontWeight: FontWeight.w700,
            color: active ? cs.onSecondary : color)),
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  final ChatMessage msg;
  final bool isMe;
  const _Bubble({required this.msg, required this.isMe});

  @override
  Widget build(BuildContext context) {
    final cs      = Theme.of(context).colorScheme;
    final timeFmt = DateFormat('HH:mm');
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(
          bottom: 8,
          left:  isMe ? 56 : 0,
          right: isMe ? 0 : 56,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isMe ? cs.primary : cs.surfaceContainerHighest,
          borderRadius: BorderRadius.only(
            topLeft:     const Radius.circular(16),
            topRight:    const Radius.circular(16),
            bottomLeft:  isMe ? const Radius.circular(16) : const Radius.circular(4),
            bottomRight: isMe ? const Radius.circular(4)  : const Radius.circular(16),
          ),
        ),
        child: Column(
          crossAxisAlignment:
              isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(msg.text,
                style: TextStyle(
                    color: isMe ? cs.onPrimary : cs.onSurface,
                    fontSize: 14)),
            const SizedBox(height: 4),
            Row(mainAxisSize: MainAxisSize.min, children: [
              Text(timeFmt.format(msg.createdAt),
                  style: TextStyle(
                      fontSize: 10,
                      color: isMe
                          ? cs.onPrimary.withValues(alpha: 0.7)
                          : cs.onSurfaceVariant)),
              if (isMe) ...[
                const SizedBox(width: 4),
                Icon(
                  msg.read ? Icons.done_all : Icons.done,
                  size: 12,
                  color: msg.read ? cs.secondary : cs.onPrimary.withValues(alpha: 0.7),
                ),
              ],
            ]),
          ],
        ),
      ),
    );
  }
}

class _DateLabel extends StatelessWidget {
  final DateTime date;
  const _DateLabel({required this.date});

  String _label(BuildContext context) {
    final now = DateTime.now();
    if (date.year == now.year && date.month == now.month && date.day == now.day)
      return 'Today';
    final y = now.subtract(const Duration(days: 1));
    if (date.year == y.year && date.month == y.month && date.day == y.day)
      return 'Yesterday';
    return DateFormat('d MMM yyyy').format(date);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(children: [
        Expanded(child: Divider(color: cs.outlineVariant)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
                color: cs.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(10)),
            child: Text(_label(context),
                style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
          ),
        ),
        Expanded(child: Divider(color: cs.outlineVariant)),
      ]),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final BookingStatus status;
  const _StatusBadge({required this.status});

  Color _color(ColorScheme cs) {
    switch (status) {
      case BookingStatus.confirmed:  return Colors.green;
      case BookingStatus.pending:    return cs.secondary;
      case BookingStatus.declined:
      case BookingStatus.cancelled:  return cs.error;
      case BookingStatus.completed:  return Colors.blue;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs    = Theme.of(context).colorScheme;
    final color = _color(cs);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(8)),
      child: Text(status.name,
          style: TextStyle(color: color,
              fontSize: 9, fontWeight: FontWeight.w700)),
    );
  }
}

class _InputBar extends StatelessWidget {
  final TextEditingController controller;
  final bool sending;
  final VoidCallback onSend;
  const _InputBar({required this.controller,
      required this.sending, required this.onSend});

  @override
  Widget build(BuildContext context) {
    final t  = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest,
          border: Border(top: BorderSide(color: cs.outlineVariant)),
        ),
        child: Row(children: [
          Expanded(
            child: TextField(
              controller: controller,
              minLines: 1, maxLines: 4,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => onSend(),
              decoration: InputDecoration(
                hintText: t.typeMessage,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none),
                filled: true,
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 10),
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: sending ? null : onSend,
            child: Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                  color: cs.secondary, shape: BoxShape.circle),
              child: sending
                  ? Padding(
                      padding: const EdgeInsets.all(12),
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: cs.onSecondary))
                  : Icon(Icons.send, color: cs.onSecondary, size: 20),
            ),
          ),
        ]),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final t  = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
      Icon(Icons.chat_bubble_outline, size: 56, color: cs.outlineVariant),
      const SizedBox(height: 12),
      Text(t.noMessages,
          style: TextStyle(color: cs.onSurfaceVariant, fontSize: 14)),
      const SizedBox(height: 4),
      Text(t.startConversation,
          style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12)),
    ]));
  }
}
