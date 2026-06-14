import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:snapstudy/core/constants/app_constants.dart';
import 'package:snapstudy/core/utils/extensions.dart';
import 'package:snapstudy/core/theme/app_colors.dart';
import 'package:snapstudy/core/widgets/app_button.dart';
import 'package:snapstudy/core/widgets/app_loading.dart';
import 'package:snapstudy/core/widgets/app_scaffold.dart';
import 'package:snapstudy/features/ai_summary/presentation/providers/ai_summary_providers.dart';
import 'package:snapstudy/features/ai_summary/presentation/widgets/ai_summary_section.dart';
import 'package:snapstudy/features/flashcards/presentation/providers/flashcard_providers.dart';
import 'package:snapstudy/features/flashcards/presentation/widgets/flashcard_deck_section.dart';
import 'package:snapstudy/features/mindmap/presentation/providers/mindmap_providers.dart';
import 'package:snapstudy/features/mindmap/presentation/widgets/mindmap_section.dart';
import 'package:snapstudy/features/quiz/presentation/providers/quiz_providers.dart';
import 'package:snapstudy/features/quiz/presentation/widgets/quiz_section.dart';
import 'package:snapstudy/features/home/presentation/utils/dashboard_formatters.dart';
import 'package:snapstudy/features/ocr/presentation/providers/ocr_providers.dart';
import 'package:snapstudy/features/ocr/presentation/widgets/ocr_result_section.dart';
import 'package:snapstudy/features/sessions/domain/entities/study_session.dart';
import 'package:snapstudy/features/sessions/domain/entities/session_status.dart';
import 'package:snapstudy/features/sessions/presentation/providers/session_pipeline_provider.dart';
import 'package:snapstudy/features/sessions/presentation/providers/session_providers.dart';
import 'package:snapstudy/features/sessions/presentation/providers/session_study_timer_provider.dart';
import 'package:snapstudy/features/sessions/presentation/utils/append_images_flow.dart';
import 'package:snapstudy/features/sessions/presentation/utils/session_display_labels.dart';
import 'package:snapstudy/features/sessions/presentation/utils/session_formatters.dart';
import 'package:snapstudy/features/sessions/presentation/widgets/session_study_timer_chip.dart';
import 'package:snapstudy/features/session_chat/presentation/widgets/session_chat_section.dart';
import 'package:snapstudy/features/weak_areas/presentation/widgets/weak_areas_section.dart';
import 'package:snapstudy/features/sessions/presentation/widgets/capture_image_viewer.dart';
import 'package:snapstudy/features/sessions/presentation/widgets/capture_queue_grid.dart';
import 'package:snapstudy/features/sessions/presentation/widgets/session_pipeline_banner.dart';
import 'package:snapstudy/features/subjects/presentation/providers/subject_providers.dart';

class SessionDetailPage extends ConsumerStatefulWidget {
  const SessionDetailPage({super.key, required this.sessionId});

  final String sessionId;

  @override
  ConsumerState<SessionDetailPage> createState() => _SessionDetailPageState();
}

class _SessionDetailPageState extends ConsumerState<SessionDetailPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      bindSessionStudyTimer(ref, widget.sessionId);
    });
  }

  @override
  void dispose() {
    ref.read(sessionStudyTimerProvider.notifier).detach();
    super.dispose();
  }

  var _pipelineTriggered = false;
  var _isReprocessingOcr = false;
  var _isGeneratingSummary = false;
  var _isGeneratingFlashcards = false;
  var _isGeneratingQuiz = false;
  var _isGeneratingMindmap = false;
  Future<void> _reload() async {
    ref.invalidate(sessionDetailProvider(widget.sessionId));
  }

  void _onPipelineStep(AsyncValue<void>? prev, AsyncValue<void> next) {
    if (prev?.isLoading == true && !next.isLoading) {
      ref.invalidate(sessionDetailProvider(widget.sessionId));
    }
    next.whenOrNull(
      error: (e, _) {
        if (mounted) {
          context.showSnack(
            e is Exception ? e.toString().replaceFirst('Exception: ', '') : '$e',
            isError: true,
          );
        }
      },
    );
  }

  Future<void> _runOcr() async {
    setState(() => _isReprocessingOcr = true);
    await ref
        .read(ocrProcessingProvider.notifier)
        .processSession(widget.sessionId);
    setState(() => _isReprocessingOcr = false);
    await _reload();
    if (mounted) {
      context.showSnack('Đã cập nhật kết quả OCR');
    }
  }

  Future<void> _runFlashcards() async {
    setState(() => _isGeneratingFlashcards = true);
    await ref
        .read(flashcardProcessingProvider.notifier)
        .generateForSession(widget.sessionId);
    setState(() => _isGeneratingFlashcards = false);
    await _reload();
    if (mounted) {
      context.showSnack('Đã cập nhật flashcard');
    }
  }

  Future<void> _runQuiz() async {
    setState(() => _isGeneratingQuiz = true);
    await ref
        .read(quizProcessingProvider.notifier)
        .generateForSession(widget.sessionId);
    setState(() => _isGeneratingQuiz = false);
    await _reload();
    if (mounted) {
      context.showSnack('Đã cập nhật quiz');
    }
  }

  Future<void> _runMindmap() async {
    setState(() => _isGeneratingMindmap = true);
    await ref
        .read(mindmapProcessingProvider.notifier)
        .generateForSession(widget.sessionId);
    setState(() => _isGeneratingMindmap = false);
    await _reload();
    if (mounted) {
      context.showSnack('Đã cập nhật mindmap');
    }
  }

  Future<void> _applySuggestedSubject(StudySession session) async {
    final ocr = session.ocrResult;
    final subjectId = ocr?.suggestedSubjectId;
    if (subjectId == null) return;

    final subjects = await ref.read(subjectsControllerProvider.future);
    final subject = subjects.where((s) => s.id == subjectId).firstOrNull;
    if (subject == null) {
      if (mounted) context.showSnack('Không tìm thấy môn gợi ý', isError: true);
      return;
    }

    final result = await ref.read(sessionRepositoryProvider).updateSessionSubject(
          sessionId: session.id,
          subject: subject,
        );

    if (mounted) {
      result.fold(
        onSuccess: (_) {
          ref.invalidate(sessionDetailProvider(widget.sessionId));
          context.showSnack('Đã đổi sang môn ${subject.name}');
        },
        onFailure: (f) => context.showSnack(f.message, isError: true),
      );
    }
  }

  Future<void> _runAiSummary() async {
    setState(() => _isGeneratingSummary = true);
    await ref
        .read(aiSummaryProcessingProvider.notifier)
        .generateForSession(widget.sessionId);
    setState(() => _isGeneratingSummary = false);
    await _reload();
    if (mounted) {
      context.showSnack('Đã cập nhật tóm tắt AI');
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(ocrProcessingProvider, _onPipelineStep);
    ref.listen(aiSummaryProcessingProvider, _onPipelineStep);
    ref.listen(flashcardProcessingProvider, _onPipelineStep);
    ref.listen(quizProcessingProvider, _onPipelineStep);
    ref.listen(mindmapProcessingProvider, _onPipelineStep);

    final sessionAsync = ref.watch(sessionDetailProvider(widget.sessionId));
    final pipelineState = ref.watch(sessionPipelineProvider);

    sessionAsync.whenData((session) {
      if (session != null &&
          !_pipelineTriggered &&
          ref.read(sessionPipelineProvider.notifier).needsPipeline(session)) {
        _pipelineTriggered = true;
        Future.microtask(
          () => ref
              .read(sessionPipelineProvider.notifier)
              .runIfNeeded(widget.sessionId),
        );
      }
    });
    final ocrLoading = ref.watch(ocrProcessingProvider).isLoading;
    final summaryLoading = ref.watch(aiSummaryProcessingProvider).isLoading;
    final flashcardLoading = ref.watch(flashcardProcessingProvider).isLoading;
    final quizLoading = ref.watch(quizProcessingProvider).isLoading;
    final mindmapLoading = ref.watch(mindmapProcessingProvider).isLoading;

    return sessionAsync.when(
      loading: () => const Scaffold(
        body: AppLoading(fullScreen: true),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(title: const Text('Buổi học')),
        body: Center(child: Text(e.toString())),
      ),
      data: (session) {
        if (session == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Buổi học')),
            body: const Center(child: Text('Không tìm thấy buổi học')),
          );
        }

        final color = Color(session.subjectColorValue);
        final showOcrProcessing = ocrLoading || _isReprocessingOcr;
        final showSummaryProcessing = summaryLoading || _isGeneratingSummary;
        final pipelineBusy = pipelineState.isRunning ||
            showOcrProcessing ||
            showSummaryProcessing ||
            flashcardLoading ||
            _isGeneratingFlashcards ||
            quizLoading ||
            _isGeneratingQuiz ||
            mindmapLoading ||
            _isGeneratingMindmap;
        final canGenerateSummary = session.ocrResult != null &&
            session.ocrResult!.fullText.trim().isNotEmpty;
        final showFlashcardProcessing =
            flashcardLoading || _isGeneratingFlashcards;
        final canGenerateFlashcards = canGenerateSummary;
        final showQuizProcessing = quizLoading || _isGeneratingQuiz;
        final canGenerateQuiz = canGenerateSummary;
        final showMindmapProcessing = mindmapLoading || _isGeneratingMindmap;
        final canGenerateMindmap = canGenerateSummary;

        final displayTitle = SessionDisplayLabels.title(session);
        final displaySubtitle = SessionDisplayLabels.subtitle(session);

        return Scaffold(
          appBar: AppBar(
            title: Text(displayTitle),
            scrolledUnderElevation: 1,
          ),
          body: Stack(
            children: [
              ListView(
            padding: const EdgeInsets.all(AppConstants.defaultPadding),
            children: [
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.12),
                            borderRadius:
                                BorderRadius.circular(AppConstants.smallRadius),
                          ),
                          child: Icon(Icons.school_rounded, color: color),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                displaySubtitle,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleSmall
                                    ?.copyWith(fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _statusLabel(session.status, session),
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (session.status != SessionStatus.active) ...[
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          AppButton(
                            label: 'Chụp thêm',
                            icon: Icons.camera_alt_outlined,
                            variant: AppButtonVariant.outline,
                            onPressed: () =>
                                runAppendCamera(context, widget.sessionId),
                          ),
                          AppButton(
                            label: 'Import ảnh',
                            icon: Icons.photo_library_outlined,
                            variant: AppButtonVariant.outline,
                            onPressed: () =>
                                runAppendGallery(context, widget.sessionId),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: AppConstants.sectionSpacing),
              SessionPipelineBanner(sessionId: widget.sessionId),
              if (pipelineBusy && !pipelineState.isRunning) ...[
                const SizedBox(height: 12),
                AppCard(
                  color: Theme.of(context)
                      .colorScheme
                      .primaryContainer
                      .withValues(alpha: 0.5),
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: AppLoading(size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Đang xử lý yêu cầu của bạn...',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const AppSectionHeader(title: 'Thông tin buổi học'),
                    const SizedBox(height: 12),
                    _MetaRow(
                      label: 'Bắt đầu',
                      value: DashboardFormatters.relativeTime(session.startedAt),
                    ),
                    if (session.endedAt != null)
                      _MetaRow(
                        label: 'Thời lượng',
                        value: SessionFormatters.formatDuration(session.elapsed),
                      ),
                    _MetaRow(label: 'Số ảnh', value: '${session.photoCount}'),
                    if (session.tags.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: session.tags
                            .map(
                              (t) => Chip(
                                label: Text(t),
                                backgroundColor: AppColors.secondary
                                    .withValues(alpha: 0.12),
                                side: BorderSide.none,
                              ),
                            )
                            .toList(),
                      ),
                    ],
                    if (session.notes != null && session.notes!.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Text(
                        'Ghi chú',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(session.notes!),
                    ],
                  ],
                ),
              ),
              if (showOcrProcessing) ...[
                const SizedBox(height: AppConstants.sectionSpacing),
                const AppLoading(message: 'Đang nhận dạng văn bản (OCR)...'),
                const SizedBox(height: 12),
                AppButton(
                  label: 'Chạy OCR ngay',
                  icon: Icons.document_scanner_outlined,
                  variant: AppButtonVariant.outline,
                  onPressed: _isReprocessingOcr ? null : _runOcr,
                ),
              ],
              if (session.ocrResult != null) ...[
                const SizedBox(height: 24),
                OcrResultSection(
                  ocr: session.ocrResult!,
                  onReprocess: session.queue.isNotEmpty ? _runOcr : null,
                  isReprocessing: _isReprocessingOcr,
                  canApplySuggestedSubject: session.ocrResult!.suggestedSubjectId !=
                          null &&
                      session.ocrResult!.suggestedSubjectId != session.subjectId,
                  onApplySuggestedSubject: () => _applySuggestedSubject(session),
                ),
              ] else if (session.status != SessionStatus.active &&
                  session.queue.isNotEmpty) ...[
                const SizedBox(height: AppConstants.sectionSpacing),
                AppButton(
                  label: _isReprocessingOcr
                      ? 'Đang OCR...'
                      : 'Nhận dạng văn bản',
                  icon: Icons.document_scanner_outlined,
                  variant: AppButtonVariant.outline,
                  isLoading: _isReprocessingOcr,
                  onPressed: _isReprocessingOcr ? null : _runOcr,
                ),
              ],
              if (showSummaryProcessing) ...[
                const SizedBox(height: 24),
                const AppLoading(message: 'Đang tạo tóm tắt AI...'),
              ],
              if (session.aiSummary != null) ...[
                const SizedBox(height: 24),
                AiSummarySection(
                  summary: session.aiSummary!,
                  onRegenerate: canGenerateSummary ? _runAiSummary : null,
                  isRegenerating: _isGeneratingSummary,
                ),
                const SizedBox(height: 24),
                SessionChatSection(sessionId: widget.sessionId),
              ] else if (canGenerateSummary) ...[
                const SizedBox(height: AppConstants.sectionSpacing),
                AppButton(
                  label: _isGeneratingSummary
                      ? 'Đang tạo tóm tắt...'
                      : 'Tạo tóm tắt AI',
                  icon: Icons.auto_awesome,
                  expand: true,
                  isLoading: _isGeneratingSummary,
                  onPressed: _isGeneratingSummary ? null : _runAiSummary,
                ),
              ],
              if (showFlashcardProcessing) ...[
                const SizedBox(height: 24),
                const AppLoading(message: 'Đang tạo flashcard...'),
              ],
              if (session.flashcardDeck != null) ...[
                const SizedBox(height: 24),
                FlashcardDeckSection(
                  deck: session.flashcardDeck!,
                  onRegenerate: canGenerateFlashcards ? _runFlashcards : null,
                  isRegenerating: _isGeneratingFlashcards,
                ),
              ] else if (canGenerateFlashcards) ...[
                const SizedBox(height: AppConstants.sectionSpacing),
                AppButton(
                  label: _isGeneratingFlashcards
                      ? 'Đang tạo flashcard...'
                      : 'Tạo flashcard AI',
                  icon: Icons.style_outlined,
                  variant: AppButtonVariant.outline,
                  isLoading: _isGeneratingFlashcards,
                  onPressed: _isGeneratingFlashcards ? null : _runFlashcards,
                ),
              ],
              if (showQuizProcessing) ...[
                const SizedBox(height: 24),
                const AppLoading(message: 'Đang tạo quiz...'),
              ],
              if (session.sessionQuiz != null) ...[
                const SizedBox(height: 24),
                QuizSection(
                  quiz: session.sessionQuiz!,
                  onRegenerate: canGenerateQuiz ? _runQuiz : null,
                  isRegenerating: _isGeneratingQuiz,
                ),
              ] else if (canGenerateQuiz) ...[
                const SizedBox(height: AppConstants.sectionSpacing),
                AppButton(
                  label: _isGeneratingQuiz
                      ? 'Đang tạo quiz...'
                      : 'Tạo quiz AI',
                  icon: Icons.quiz_outlined,
                  variant: AppButtonVariant.outline,
                  isLoading: _isGeneratingQuiz,
                  onPressed: _isGeneratingQuiz ? null : _runQuiz,
                ),
              ],
              if (showMindmapProcessing) ...[
                const SizedBox(height: 24),
                const AppLoading(message: 'Đang tạo mindmap...'),
              ],
              if (session.sessionMindmap != null) ...[
                const SizedBox(height: 24),
                MindmapSection(
                  mindmap: session.sessionMindmap!,
                  onRegenerate: canGenerateMindmap ? _runMindmap : null,
                  isRegenerating: _isGeneratingMindmap,
                ),
              ] else if (canGenerateMindmap) ...[
                const SizedBox(height: AppConstants.sectionSpacing),
                AppButton(
                  label: _isGeneratingMindmap
                      ? 'Đang tạo mindmap...'
                      : 'Tạo mindmap AI',
                  icon: Icons.account_tree_outlined,
                  variant: AppButtonVariant.outline,
                  isLoading: _isGeneratingMindmap,
                  onPressed: _isGeneratingMindmap ? null : _runMindmap,
                ),
              ],
              WeakAreasSection(sessionId: widget.sessionId),
              const SizedBox(height: AppConstants.sectionSpacing),
              const AppSectionHeader(title: 'Ảnh đã chụp'),
              const SizedBox(height: 12),
              CaptureQueueGrid(
                items: session.queue,
                onImageTap: (item, index) => CaptureImageViewer.show(
                  context,
                  items: session.queue,
                  initialIndex: index,
                ),
              ),
            ],
          ),
              const Positioned(
                top: 0,
                right: 12,
                child: SafeArea(child: SessionStudyTimerChip()),
              ),
            ],
          ),
        );
      },
    );
  }

  String _statusLabel(SessionStatus status, StudySession session) =>
      switch (status) {
        SessionStatus.active => 'Đang diễn ra',
        SessionStatus.processing => 'Đang xử lý AI',
        SessionStatus.ready => session.ocrResult != null
            ? 'Sẵn sàng — OCR xong'
            : (session.endedAt != null ? 'Đã kết thúc' : 'Sẵn sàng'),
        SessionStatus.completed => 'Hoàn tất — AI đầy đủ',
        SessionStatus.draft => 'Nháp',
      };
}

extension _FirstOrNull<E> on Iterable<E> {
  E? get firstOrNull {
    final it = iterator;
    if (it.moveNext()) return it.current;
    return null;
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
