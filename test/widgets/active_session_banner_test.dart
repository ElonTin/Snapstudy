import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:snapstudy/features/sessions/domain/entities/session_status.dart';
import 'package:snapstudy/features/sessions/presentation/providers/session_providers.dart';
import 'package:snapstudy/features/sessions/presentation/widgets/active_session_banner.dart';
import '../helpers/session_fixtures.dart';
import '../helpers/test_helpers.dart';

void main() {
  setUpAll(() async {
    await initTestEnvironment();
  });

  testWidgets('shows active session title', (tester) async {
    final session = testSessionWithOcr(id: 'ses_active').copyWith(
      status: SessionStatus.active,
      title: 'Buổi đang học',
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          hasActiveSessionProvider.overrideWith((ref) => true),
          activeSessionPreviewProvider.overrideWith(
            (ref) async => ActiveSessionPreview(
              session: session,
              elapsed: const Duration(minutes: 12),
            ),
          ),
        ],
        child: const MaterialApp(home: Scaffold(body: ActiveSessionBanner())),
      ),
    );
    await tester.pump();

    expect(find.textContaining('Buổi đang học'), findsOneWidget);
  });

  testWidgets('hides when no active session', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          hasActiveSessionProvider.overrideWith((ref) => false),
        ],
        child: const MaterialApp(home: Scaffold(body: ActiveSessionBanner())),
      ),
    );
    await tester.pump();

    expect(find.byType(ActiveSessionBanner), findsOneWidget);
    expect(find.textContaining('Buổi'), findsNothing);
  });
}
