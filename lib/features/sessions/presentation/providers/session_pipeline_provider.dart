import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:snapstudy/core/errors/failures.dart';
import 'package:snapstudy/features/home/presentation/providers/dashboard_provider.dart';
import 'package:snapstudy/features/sessions/presentation/providers/session_providers.dart';

/// Refreshes session detail + dashboard after a pipeline step completes.
void refreshSessionAfterPipeline(Ref ref, String sessionId) {
  ref.invalidate(sessionDetailProvider(sessionId));
  ref.invalidate(dashboardProvider);
}

/// Throws so [AsyncValue.guard] surfaces errors in UI listeners.
Never pipelineFailure(Failure failure) => throw Exception(failure.message);
