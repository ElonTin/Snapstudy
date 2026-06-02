import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:snapstudy/core/constants/app_constants.dart';
import 'package:snapstudy/core/utils/extensions.dart';
import 'package:snapstudy/core/widgets/app_loading.dart';
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
import 'package:snapstudy/features/sessions/presentation/providers/session_providers.dart';
import 'package:snapstudy/features/sessions/presentation/utils/session_formatters.dart';
import 'package:snapstudy/features/sessions/presentation/widgets/capture_queue_grid.dart';

class SessionDetailPage extends ConsumerStatefulWidget {
  const SessionDetailPage({super.key, required this.sessionId});

  final String sessionId;

  @override
  ConsumerState<SessionDetailPage> createState() => _SessionDetailPageState();
}

class _SessionDetailPageState extends ConsumerState<SessionDetailPage> {
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
        final pipelineBusy = showOcrProcessing ||
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

        return Scaffold(
          appBar: AppBar(title: Text(session.title)),
          body: ListView(
            padding: const EdgeInsets.all(AppConstants.defaultPadding),
            children: [
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: color.withValues(alpha: 0.15),
                  child: Icon(Icons.school, color: color),
                ),
                title: Text(session.subjectName),
                subtitle: Text(_statusLabel(session.status, session)),
              ),
              const Divider(),
              if (pipelineBusy) ...[
                Card(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
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
                ),
                const SizedBox(height: 12),
              ],
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
                  children: session.tags
                      .map((t) => Chip(label: Text(t)))
                      .toList(),
                ),
              ],
              if (session.notes != null && session.notes!.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text('Ghi chú', style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 4),
                Text(session.notes!),
              ],
              if (showOcrProcessing) ...[
                const SizedBox(height: 24),
                const AppLoading(message: 'Đang nhận dạng văn bản (OCR)...'),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _isReprocessingOcr ? null : _runOcr,
                  icon: const Icon(Icons.document_scanner_outlined),
                  label: const Text('Chạy OCR ngay'),
                ),
              ],
              if (session.ocrResult != null) ...[
                const SizedBox(height: 24),
                OcrResultSection(
                  ocr: session.ocrResult!,
                  onReprocess: session.queue.isNotEmpty ? _runOcr : null,
                  isReprocessing: _isReprocessingOcr,
                ),
              ] else if (session.status != SessionStatus.active &&
                  session.queue.isNotEmpty) ...[
                const SizedBox(height: 24),
                OutlinedButton.icon(
                  onPressed: _isReprocessingOcr ? null : _runOcr,
                  icon: const Icon(Icons.document_scanner_outlined),
                  label: Text(
                    _isReprocessingOcr ? 'Đang OCR...' : 'Nhận dạng văn bản',
                  ),
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
              ] else if (canGenerateSummary) ...[
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: _isGeneratingSummary ? null : _runAiSummary,
                  icon: _isGeneratingSummary
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.auto_awesome),
                  label: Text(
                    _isGeneratingSummary
                        ? 'Đang tạo tóm tắt...'
                        : 'Tạo tóm tắt AI',
                  ),
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
                const SizedBox(height: 24),
                OutlinedButton.icon(
                  onPressed: _isGeneratingFlashcards ? null : _runFlashcards,
                  icon: const Icon(Icons.style_outlined),
                  label: Text(
                    _isGeneratingFlashcards
                        ? 'Đang tạo flashcard...'
                        : 'Tạo flashcard AI',
                  ),
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
                const SizedBox(height: 24),
                OutlinedButton.icon(
                  onPressed: _isGeneratingQuiz ? null : _runQuiz,
                  icon: const Icon(Icons.quiz_outlined),
                  label: Text(
                    _isGeneratingQuiz
                        ? 'Đang tạo quiz...'
                        : 'Tạo quiz AI',
                  ),
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
                const SizedBox(height: 24),
                OutlinedButton.icon(
                  onPressed: _isGeneratingMindmap ? null : _runMindmap,
                  icon: const Icon(Icons.account_tree_outlined),
                  label: Text(
                    _isGeneratingMindmap
                        ? 'Đang tạo mindmap...'
                        : 'Tạo mindmap AI',
                  ),
                ),
              ],
              const SizedBox(height: 24),
              Text(
                'Ảnh đã chụp',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              CaptureQueueGrid(items: session.queue),
            ],
          ),
        );
      },
    );
  }

  String _statusLabel(SessionStatus status, StudySession session) =>
      switch (status) {
        SessionStatus.active => 'Đang diễn ra',
        SessionStatus.processing => 'Đang xử lý',
        SessionStatus.ready => session.ocrResult != null
            ? 'Sẵn sàng — OCR xong'
            : (session.endedAt != null ? 'Đã kết thúc' : 'Sẵn sàng'),
        SessionStatus.completed => 'Hoàn tất — AI đầy đủ',
        SessionStatus.draft => 'Nháp',
      };
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
