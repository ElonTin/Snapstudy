import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:snapstudy/features/sessions/presentation/providers/session_providers.dart';

/// Pauses the study timer when the app goes to background.
class StudySessionLifecycleHandler extends ConsumerStatefulWidget {
  const StudySessionLifecycleHandler({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<StudySessionLifecycleHandler> createState() =>
      _StudySessionLifecycleHandlerState();
}

class _StudySessionLifecycleHandlerState
    extends ConsumerState<StudySessionLifecycleHandler>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached ||
        state == AppLifecycleState.hidden) {
      ref.read(activeSessionProvider.notifier).pauseTimer();
    } else if (state == AppLifecycleState.resumed) {
      ref.invalidate(activeSessionPreviewProvider);
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
