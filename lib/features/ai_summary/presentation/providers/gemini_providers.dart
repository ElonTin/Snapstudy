import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:snapstudy/core/network/shared_dio_provider.dart';
import 'package:snapstudy/features/ai_summary/data/services/gemini_api_client.dart';

final geminiApiClientProvider = Provider<GeminiApiClient>((ref) {
  return GeminiApiClient(dio: ref.watch(geminiDioProvider));
});
