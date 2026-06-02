/// Lifecycle of a study capture session.
enum SessionStatus {
  draft,
  active,
  processing,
  ready,
  completed,
}

enum CaptureItemStatus { pending, synced, failed }
