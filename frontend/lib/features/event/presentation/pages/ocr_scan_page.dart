import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:smart_calendar/core/theme/app_theme.dart';
import 'package:smart_calendar/features/event/domain/entities/event_entity.dart';
import 'package:smart_calendar/features/event/presentation/providers/event_provider.dart';
import 'package:smart_calendar/features/event/presentation/widgets/event_card.dart';
import 'package:smart_calendar/features/event/data/datasources/photo_datasource.dart';
import 'package:url_launcher/url_launcher.dart';

class OcrScanPage extends ConsumerStatefulWidget {
  const OcrScanPage({super.key});

  @override
  ConsumerState<OcrScanPage> createState() => _OcrScanPageState();
}

class _OcrScanPageState extends ConsumerState<OcrScanPage> {
  XFile? _imageFile;
  List<EventEntity>? _extracted;
  final Set<String> _selectedIds = {};
  bool _processing = false;

  Future<void> _pick(ImageSource source) async {
    final picker = ImagePicker();
    final file = await picker.pickImage(
      source: source,
      imageQuality: 85,
    );
    if (file == null) return;

    setState(() {
      _imageFile = file;
      _extracted = null;
      _selectedIds.clear();
      _processing = true;
    });

    try {
      final bytes = await file.readAsBytes();
      final events = await ref
          .read(eventNotifierProvider.notifier)
          .extractFromImage(bytes);
      setState(() {
        _extracted = events;
        _selectedIds.addAll(events.map((e) => e.id));
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('OCR 처리 중 오류: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  Future<void> _saveSelected() async {
    final toSave =
        _extracted?.where((e) => _selectedIds.contains(e.id)).toList() ?? [];
    if (toSave.isEmpty) return;

    final createdEvents = <String>[];
    for (final event in toSave) {
      final created = await ref.read(eventNotifierProvider.notifier).createEvent(event);
      if (created != null) createdEvents.add(created.id);
    }

    // OCR 이미지를 등록된 모든 일정에 자동 첨부
    if (_imageFile != null && createdEvents.isNotEmpty) {
      final photoDs = ref.read(photoDatasourceProvider);
      for (final eventId in createdEvents) {
        try {
          await photoDs.uploadPhoto(eventId, File(_imageFile!.path));
        } catch (_) {}
      }
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${toSave.length}개의 일정이 등록되었습니다'),
          backgroundColor: AppColors.accentGreen,
        ),
      );
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.chevron_left_rounded, size: 28),
          onPressed: () => Navigator.of(context).pop(),
        ),
        backgroundColor: Colors.transparent,
        title: Text(
          'OCR 일정 추가',
          style: theme.textTheme.titleLarge
              ?.copyWith(fontWeight: FontWeight.w800),
        ),
      ),
      body: _imageFile == null
          ? _PickerState(onPick: _pick)
          : Column(
              children: [
                // ── 미리보기 이미지 ────────────────────
                Container(
                  height: 200,
                  margin: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: cs.surfaceContainerHighest,
                  ),
                  clipBehavior: Clip.hardEdge,
                  child: Image.file(
                    File(_imageFile!.path),
                    fit: BoxFit.cover,
                    width: double.infinity,
                  ),
                ),

                // ── 재선택 버튼 ───────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: OutlinedButton.icon(
                    onPressed: () => _showSourceSheet(),
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    label: const Text('다른 이미지 선택'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 44),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // ── 처리 중 / 결과 ────────────────────
                if (_processing)
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const CircularProgressIndicator(),
                        const SizedBox(height: 16),
                        Text(
                          '이미지에서 일정을 찾는 중...',
                          style: theme.textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  )
                else if (_extracted != null) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        Text(
                          '발견된 일정 ${_extracted!.length}개',
                          style: theme.textTheme.titleSmall,
                        ),
                        const Spacer(),
                        TextButton(
                          onPressed: () {
                            setState(() {
                              if (_selectedIds.length ==
                                  _extracted!.length) {
                                _selectedIds.clear();
                              } else {
                                _selectedIds.addAll(
                                    _extracted!.map((e) => e.id));
                              }
                            });
                          },
                          child: Text(
                            _selectedIds.length == _extracted!.length
                                ? '전체 해제'
                                : '전체 선택',
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: _extracted!.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.search_off_rounded,
                                    size: 48,
                                    color: cs.onSurfaceVariant
                                        .withValues(alpha: 0.4)),
                                const SizedBox(height: 12),
                                Text(
                                  '이미지에서 일정을 찾지 못했어요',
                                  style: theme.textTheme.bodyMedium,
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(
                                16, 0, 16, 100),
                            itemCount: _extracted!.length,
                            itemBuilder: (ctx, i) {
                              final event = _extracted![i];
                              final selected =
                                  _selectedIds.contains(event.id);
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: Stack(
                                  children: [
                                    // 카드 전체 탭 → 미리보기
                                    GestureDetector(
                                      onTap: () => _showPreview(event),
                                      child: Opacity(
                                        opacity: selected ? 1.0 : 0.5,
                                        child: EventCard(event: event),
                                      ),
                                    ),
                                    // 체크 아이콘만 선택/해제
                                    Positioned(
                                      right: 0,
                                      top: 0,
                                      bottom: 0,
                                      width: 56,
                                      child: GestureDetector(
                                        behavior: HitTestBehavior.opaque,
                                        onTap: () => setState(() {
                                          if (selected) {
                                            _selectedIds.remove(event.id);
                                          } else {
                                            _selectedIds.add(event.id);
                                          }
                                        }),
                                        child: Center(
                                          child: Icon(
                                            selected
                                                ? Icons.check_circle_rounded
                                                : Icons.circle_outlined,
                                            color: selected
                                                ? AppColors.accentGreen
                                                : cs.onSurfaceVariant,
                                            size: 26,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ],
            ),
      floatingActionButton: _extracted != null && _selectedIds.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: _saveSelected,
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.check_rounded),
              label: Text('${_selectedIds.length}개 등록하기'),
            )
          : null,
    );
  }


  void _showPreview(EventEntity event) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: cs.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            // 카테고리 뱃지
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: event.category.color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                event.category.label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: event.category.color,
                ),
              ),
            ),
            const SizedBox(height: 10),
            // 제목
            Text(
              event.title,
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 12),
            // 날짜
            _PreviewRow(icon: Icons.calendar_today_outlined, label: '시작',
              value: '${event.startAt.year}년 ${event.startAt.month}월 ${event.startAt.day}일 '
                '${event.startAt.hour.toString().padLeft(2,"0")}:${event.startAt.minute.toString().padLeft(2,"0")}',
              color: event.category.color),
            if (event.endAt != null)
              _PreviewRow(icon: Icons.event_outlined, label: '종료',
                value: '${event.endAt!.year}년 ${event.endAt!.month}월 ${event.endAt!.day}일 '
                  '${event.endAt!.hour.toString().padLeft(2,"0")}:${event.endAt!.minute.toString().padLeft(2,"0")}',
                color: event.category.color),
            if (event.isAllDay)
              _PreviewRow(icon: Icons.wb_sunny_outlined, label: '유형',
                value: '종일 일정', color: event.category.color),
            if (event.location != null)
              _PreviewRow(icon: Icons.location_on_outlined, label: '장소',
                value: event.location!, color: event.category.color),
            if (event.link != null && event.link!.isNotEmpty) ...[
              _PreviewRow(icon: Icons.link_rounded, label: '링크',
                value: event.link!, color: event.category.color),
              Padding(
                padding: const EdgeInsets.only(left: 28, bottom: 8),
                child: GestureDetector(
                  onTap: () async {
                    final uri = Uri.tryParse(event.link!);
                    if (uri != null && await canLaunchUrl(uri)) {
                      await launchUrl(uri, mode: LaunchMode.externalApplication);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: event.category.color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text('바로가기 →',
                      style: TextStyle(color: event.category.color,
                        fontSize: 13, fontWeight: FontWeight.w700)),
                  ),
                ),
              ),
            ],
            if (event.memo != null && event.memo!.isNotEmpty)
              _PreviewRow(icon: Icons.notes_rounded, label: '메모',
                value: event.memo!, color: event.category.color),
            const SizedBox(height: 16),
            // 닫기 버튼
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: event.category.color,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('닫기', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSourceSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _SourceSheet(onPick: (src) {
        Navigator.pop(context);
        _pick(src);
      }),
    );
  }
}

// ── 처음 이미지 선택 화면 ─────────────────────────────────────
class _PickerState extends StatelessWidget {
  final void Function(ImageSource) onPick;
  const _PickerState({required this.onPick});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: cs.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(24),
            ),
            alignment: Alignment.center,
            child: Icon(Icons.document_scanner_rounded,
                size: 44, color: cs.primary),
          ).also((w) => Center(child: w)),
          const SizedBox(height: 24),
          Text(
            '이미지에서 일정 추출',
            style: theme.textTheme.headlineSmall
                ?.copyWith(fontWeight: FontWeight.w800),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            '공지문, 포스터, 캡처 이미지 등에서\n일정 정보를 자동으로 추출합니다',
            style: theme.textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),

          // 사진 보관함
          _SourceButton(
            icon: Icons.photo_library_outlined,
            color: AppColors.primary,
            label: '사진 보관함',
            subtitle: '기존 사진에서 선택',
            onTap: () => onPick(ImageSource.gallery),
          ),
          const SizedBox(height: 12),

          // 카메라
          _SourceButton(
            icon: Icons.camera_alt_outlined,
            color: AppColors.secondary,
            label: '카메라',
            subtitle: '지금 촬영하기',
            onTap: () => onPick(ImageSource.camera),
          ),
        ],
      ),
    );
  }
}

// ── 소스 선택 시트 ────────────────────────────────────────────
class _SourceSheet extends StatelessWidget {
  final void Function(ImageSource) onPick;
  const _SourceSheet({required this.onPick});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              '이미지 선택',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _SourceButton(
                    icon: Icons.photo_library_outlined,
                    color: AppColors.primary,
                    label: '사진 보관함',
                    onTap: () => onPick(ImageSource.gallery),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _SourceButton(
                    icon: Icons.camera_alt_outlined,
                    color: AppColors.secondary,
                    label: '카메라',
                    onTap: () => onPick(ImageSource.camera),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _SourceButton(
                    icon: Icons.folder_outlined,
                    color: AppColors.accentOrange,
                    label: '파일',
                    onTap: () => onPick(ImageSource.gallery), // 파일 = 갤러리 fallback
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _SourceButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String? subtitle;
  final VoidCallback onTap;

  const _SourceButton({
    required this.icon,
    required this.color,
    required this.label,
    this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(label,
                style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w700,
                    fontSize: 13)),
            if (subtitle != null) ...[
              const SizedBox(height: 2),
              Text(subtitle!,
                  style: theme.textTheme.bodySmall,
                  textAlign: TextAlign.center),
            ],
          ],
        ),
      ),
    );
  }
}

// Dart extension helper
extension _AlsoExtension<T> on T {
  T also(void Function(T it) block) {
    block(this);
    return this;
  }
}

class _PreviewRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  const _PreviewRow({required this.icon, required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 10),
          SizedBox(
            width: 44,
            child: Text(label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: cs.onSurfaceVariant, fontWeight: FontWeight.w600)),
          ),
          Expanded(
            child: Text(value,
              style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }
}
