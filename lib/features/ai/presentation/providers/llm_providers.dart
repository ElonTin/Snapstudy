import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:snapstudy/core/env/env_config.dart';
import 'package:snapstudy/core/network/shared_dio_provider.dart';
import 'package:snapstudy/features/ai/data/services/gemini_llm_json_client.dart';
import 'package:snapstudy/features/ai/data/services/groq_api_client.dart';
import 'package:snapstudy/features/ai/data/services/llm_json_client.dart';
import 'package:snapstudy/features/ai_summary/presentation/providers/gemini_providers.dart';

final groqDioProvider = Provider((ref) => ref.watch(sharedDioProvider));

/// LLM text/JSON — Groq nếu có key (nhanh), không thì Gemini.
final textLlmClientProvider = Provider<LlmJsonClient>((ref) {
  if (EnvConfig.isGroqConfigured) {
    return GroqApiClient(dio: ref.watch(groqDioProvider));
  }
  return GeminiLlmJsonClient(ref.watch(geminiApiClientProvider));
});

/// Nhãn provider đang dùng (hiển thị debug/UI).
final textLlmProviderLabelProvider = Provider<String>((ref) {
  return ref.watch(textLlmClientProvider).providerLabel;
});
