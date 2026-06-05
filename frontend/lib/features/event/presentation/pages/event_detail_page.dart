import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:smart_calendar/features/event/domain/entities/event_entity.dart';
import 'package:smart_calendar/features/event/presentation/providers/event_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:smart_calendar/features/event/data/datasources/photo_datasource.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:smart_calendar/features/event/presentation/pages/create_event_page.dart';

class EventDetailPage extends ConsumerWidget {
  final String eventId;
  const EventDetailPage({super.key, required this.eventId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventsAsync = ref.watch(eventNotifierProvider);
    final event = eventsAsync.valueOrNull
        ?.where((e) => e.id == eventId)
        .firstOrNull;

    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.chevron_left_rounded, size: 28),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('일정 상세'),
        centerTitle: true,
        actions: [
          if (event != null)
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => CreateEventPage(editEvent: event),
                ),
              ),
            ),
          if (event != null)
            IconButton(
              icon: Icon(Icons.delete_outline_rounded, color: cs.error),
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('일정 삭제'),
                    content: const Text('이 일정을 삭제할까요?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('취소'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        child: Text('삭제', style: TextStyle(color: cs.error)),
                      ),
                    ],
                  ),
                );
                if (confirm == true && context.mounted) {
                  await ref.read(eventNotifierProvider.notifier).deleteEvent(eventId);
                  if (context.mounted) Navigator.of(context).pop();
                }
              },
            ),
        ],
      ),
      body: event == null
          ? const Center(child: CircularProgressIndicator())
          : _EventDetailBody(event: event, eventId: eventId),
    );
  }
}

class _EventDetailBody extends ConsumerWidget {
  final EventEntity event;
  final String eventId;
  const _EventDetailBody({required this.event, required this.eventId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final color = event.category.color;
    final photosAsync = ref.watch(eventPhotosProvider(eventId));

    String formatDate(DateTime d, {bool showTime = true}) {
      if (event.isAllDay) return DateFormat('yyyy년 M월 d일 (E)', 'ko').format(d);
      return DateFormat('yyyy년 M월 d일 (E) HH:mm', 'ko').format(d);
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── 카테고리 뱃지 + 제목 ──
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  event.category.label,
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color),
                ),
              ),
              if (event.isVerified) ...[
                const SizedBox(width: 8),
                Icon(Icons.verified_rounded, size: 16, color: color),
                const SizedBox(width: 4),
                Text('OCR 등록', style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w600)),
              ],
            ],
          ),
          const SizedBox(height: 12),
          Text(
            event.title,
            style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 24),

          // ── 날짜/시간 ──
          _DetailSection(
            icon: Icons.calendar_today_outlined,
            color: color,
            children: [
              _DetailRow(
                label: event.isMultiDay ? '시작' : '날짜',
                value: formatDate(event.startAt),
              ),
              if (event.endAt != null)
                _DetailRow(
                  label: event.isMultiDay ? '종료' : '종료 시간',
                  value: formatDate(event.endAt!),
                ),
              if (event.isAllDay)
                _DetailRow(label: '유형', value: '종일 일정'),
              if (event.isMultiDay) ...[
                _DetailRow(
                  label: 'D-day',
                  value: () {
                    final remaining = event.endAt!.difference(DateTime.now()).inDays + 1;
                    if (remaining < 0) return '종료됨';
                    if (remaining == 0) return '오늘 마감';
                    return 'D-$remaining';
                  }(),
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),

          // ── 위치 ──
          if (event.location != null) ...[
            _DetailSection(
              icon: Icons.location_on_outlined,
              color: color,
              children: [
                _DetailRow(label: '장소', value: event.location!),
              ],
            ),
            const SizedBox(height: 16),
          ],

          // ── 연락처 ──
          if (event.contactEmail != null) ...[
            _DetailSection(
              icon: Icons.email_outlined,
              color: color,
              children: [
                _DetailRow(label: '이메일', value: event.contactEmail!),
              ],
            ),
            const SizedBox(height: 16),
          ],

          // ── 링크 바로가기 ──
          if (event.link != null && event.link!.isNotEmpty) ...[
            GestureDetector(
              onTap: () async {
                final uri = Uri.tryParse(event.link!);
                if (uri != null && await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: color.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.link_rounded, color: color, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('바로가기 링크',
                            style: TextStyle(color: color,
                              fontWeight: FontWeight.w700, fontSize: 13)),
                          const SizedBox(height: 2),
                          Text(event.link!,
                            style: TextStyle(color: color.withValues(alpha: 0.7),
                              fontSize: 11),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                    Icon(Icons.open_in_new_rounded, color: color, size: 18),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // ── 메모 ──
          if (event.memo != null && event.memo!.isNotEmpty) ...[
            _DetailSection(
              icon: Icons.notes_rounded,
              color: color,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    event.memo!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: cs.onSurface,
                      height: 1.6,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],

          // ── 알림 ──
          if (event.reminderMinutes != null) ...[
            _DetailSection(
              icon: Icons.notifications_outlined,
              color: color,
              children: [
                _DetailRow(
                  label: '알림',
                  value: event.reminderMinutes == 0
                      ? '시작 시각'
                      : '${event.reminderMinutes}분 전',
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],

          // ── 사진 갤러리 ──
          _PhotoGallerySection(eventId: eventId, photosAsync: photosAsync, color: color),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

class _DetailSection extends StatelessWidget {
  final IconData icon;
  final Color color;
  final List<Widget> children;
  const _DetailSection({required this.icon, required this.color, required this.children});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 60,
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: cs.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: cs.onSurface,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Photo Gallery Section ─────────────────────────────────────
class _PhotoGallerySection extends ConsumerWidget {
  final String eventId;
  final AsyncValue<List<Map<String, dynamic>>> photosAsync;
  final Color color;
  const _PhotoGallerySection({
    required this.eventId,
    required this.photosAsync,
    required this.color,
  });

  Future<void> _pickAndUpload(BuildContext context, WidgetRef ref) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (picked == null) return;
    try {
      await ref.read(photoDatasourceProvider).uploadPhoto(eventId, File(picked.path));
      ref.invalidate(eventPhotosProvider(eventId));
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('업로드 실패: $e')),
        );
      }
    }
  }

  Future<void> _deletePhoto(BuildContext context, WidgetRef ref, String photoId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('사진 삭제'),
        content: const Text('이 사진을 삭제할까요?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('취소')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('삭제', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await ref.read(photoDatasourceProvider).deletePhoto(eventId, photoId);
      ref.invalidate(eventPhotosProvider(eventId));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final baseUrl = 'http://127.0.0.1:8000';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(Icons.photo_library_outlined, size: 18, color: color),
                const SizedBox(width: 8),
                Text('사진',
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w700)),
              ],
            ),
            TextButton.icon(
              onPressed: () => _pickAndUpload(context, ref),
              icon: Icon(Icons.add_photo_alternate_outlined, size: 16, color: color),
              label: Text('추가', style: TextStyle(color: color, fontSize: 13)),
            ),
          ],
        ),
        const SizedBox(height: 8),
        photosAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Text('사진을 불러올 수 없어요',
              style: TextStyle(color: cs.onSurfaceVariant)),
          data: (photos) => photos.isEmpty
              ? Container(
                  height: 100,
                  decoration: BoxDecoration(
                    color: theme.cardTheme.color,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: cs.outlineVariant,
                        style: BorderStyle.solid),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.add_photo_alternate_outlined,
                            size: 28, color: cs.onSurfaceVariant),
                        const SizedBox(height: 6),
                        Text('사진을 추가해보세요',
                            style: TextStyle(
                                color: cs.onSurfaceVariant, fontSize: 13)),
                      ],
                    ),
                  ),
                )
              : GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: photos.length,
                  itemBuilder: (ctx, i) {
                    final photo = photos[i];
                    final url = '$baseUrl${photo["url"]}';
                    return GestureDetector(
                      onLongPress: () =>
                          _deletePhoto(context, ref, photo['id']),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.network(
                          url,
                          fit: BoxFit.cover,
                          loadingBuilder: (ctx, child, progress) =>
                              progress == null
                                  ? child
                                  : Container(
                                      color: cs.surfaceContainerHighest,
                                      child: const Center(
                                          child: CircularProgressIndicator(
                                              strokeWidth: 2)),
                                    ),
                          errorBuilder: (ctx, e, _) => Container(
                            color: cs.surfaceContainerHighest,
                            child: Icon(Icons.broken_image_outlined,
                                color: cs.onSurfaceVariant),
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
