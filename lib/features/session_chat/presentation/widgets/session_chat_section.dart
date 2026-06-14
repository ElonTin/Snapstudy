import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:snapstudy/core/constants/app_constants.dart';
import 'package:snapstudy/core/theme/app_colors.dart';
import 'package:snapstudy/core/utils/extensions.dart';
import 'package:snapstudy/core/widgets/app_button.dart';
import 'package:snapstudy/core/widgets/app_loading.dart';
import 'package:snapstudy/core/widgets/app_scaffold.dart';
import 'package:snapstudy/features/ai/presentation/providers/llm_providers.dart';
import 'package:snapstudy/features/session_chat/domain/entities/chat_message_role.dart';
import 'package:snapstudy/features/session_chat/presentation/providers/session_chat_providers.dart';

class SessionChatSection extends ConsumerStatefulWidget {
  const SessionChatSection({super.key, required this.sessionId});

  final String sessionId;

  @override
  ConsumerState<SessionChatSection> createState() => _SessionChatSectionState();
}

class _SessionChatSectionState extends ConsumerState<SessionChatSection> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  var _expanded = false;

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    _controller.clear();
    await ref.read(sessionChatProvider(widget.sessionId).notifier).send(text);
    if (_scrollController.hasClients) {
      await Future<void>.delayed(const Duration(milliseconds: 100));
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final chatAsync = ref.watch(sessionChatProvider(widget.sessionId));
    final providerLabel = ref.watch(textLlmProviderLabelProvider);
    final colors = Theme.of(context).colorScheme;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: BorderRadius.circular(AppConstants.smallRadius),
            child: AppSectionHeader(
              title: 'Hỏi AI về buổi học',
              subtitle: 'Groq + Gemini · $providerLabel',
              trailing: Icon(
                _expanded ? Icons.expand_less : Icons.expand_more,
                color: colors.onSurfaceVariant,
              ),
            ),
          ),
          if (_expanded) ...[
            const SizedBox(height: 12),
            Container(
              height: 280,
              decoration: BoxDecoration(
                color: colors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(AppConstants.smallRadius),
                border: Border.all(
                  color: colors.outline.withValues(alpha: 0.4),
                ),
              ),
              child: chatAsync.when(
                loading: () => const Center(child: AppLoading()),
                error: (e, _) => Center(child: Text('$e')),
                data: (messages) {
                  if (messages.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          'Hỏi AI giải thích bài, công thức, hoặc cách làm dạng bài trong buổi học này.',
                          textAlign: TextAlign.center,
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: colors.onSurfaceVariant,
                                  ),
                        ),
                      ),
                    );
                  }
                  return ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(12),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final msg = messages[index];
                      final isUser = msg.role == ChatMessageRole.user;
                      return Align(
                        alignment: isUser
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          constraints: const BoxConstraints(maxWidth: 300),
                          decoration: BoxDecoration(
                            color: isUser
                                ? AppColors.primary.withValues(alpha: 0.12)
                                : colors.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(12),
                            border: isUser
                                ? Border.all(
                                    color: AppColors.primary
                                        .withValues(alpha: 0.2),
                                  )
                                : null,
                          ),
                          child: Text(msg.content),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    minLines: 1,
                    maxLines: 3,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _send(),
                    decoration: InputDecoration(
                      hintText: 'Nhập câu hỏi...',
                      border: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(AppConstants.smallRadius),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  onPressed: chatAsync.isLoading ? null : _send,
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                  icon: const Icon(Icons.send),
                ),
              ],
            ),
            Align(
              alignment: Alignment.centerRight,
              child: AppButton(
                label: 'Xóa lịch sử',
                variant: AppButtonVariant.text,
                onPressed: () async {
                  await ref
                      .read(sessionChatProvider(widget.sessionId).notifier)
                      .clear();
                  if (context.mounted) {
                    context.showSnack('Đã xóa lịch sử chat');
                  }
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}
