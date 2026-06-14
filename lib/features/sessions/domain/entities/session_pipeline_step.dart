/// Steps in the automatic post-session AI pipeline.
enum SessionPipelineStep {
  ocr,
  summary,
  flashcards,
  quiz,
  mindmap,
}

/// Các bước chạy tự động sau khi người dùng đưa ảnh vào.
const autoPipelineSteps = [
  SessionPipelineStep.ocr,
  SessionPipelineStep.summary,
];

extension SessionPipelineStepX on SessionPipelineStep {
  String get label => switch (this) {
        SessionPipelineStep.ocr => 'Nhận dạng văn bản (OCR)',
        SessionPipelineStep.summary => 'Tóm tắt AI',
        SessionPipelineStep.flashcards => 'Tạo flashcard',
        SessionPipelineStep.quiz => 'Tạo quiz',
        SessionPipelineStep.mindmap => 'Tạo mindmap',
      };

  bool get isAutomatic => autoPipelineSteps.contains(this);
}
