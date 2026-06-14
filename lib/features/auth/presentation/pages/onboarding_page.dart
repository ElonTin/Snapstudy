import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:snapstudy/core/constants/app_constants.dart';
import 'package:snapstudy/core/routing/route_paths.dart';
import 'package:snapstudy/core/theme/app_colors.dart';
import 'package:snapstudy/core/widgets/app_button.dart';
import 'package:snapstudy/features/auth/presentation/providers/onboarding_provider.dart';

class _OnboardingSlide {
  const _OnboardingSlide({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;
}

const _slides = [
  _OnboardingSlide(
    icon: Icons.camera_alt_outlined,
    title: 'Chụp nhanh, học thông minh',
    subtitle:
        'Ghi lại bảng giảng và tài liệu lớp học chỉ với một lần chạm.',
  ),
  _OnboardingSlide(
    icon: Icons.auto_awesome,
    title: 'AI biến ảnh thành kiến thức',
    subtitle:
        'Tự động tóm tắt, flashcard, quiz và mindmap từ ảnh của bạn.',
  ),
  _OnboardingSlide(
    icon: Icons.school_outlined,
    title: 'Ghi nhớ lâu dài',
    subtitle:
        'Spaced repetition giúp bạn ôn đúng lúc, nhớ lâu hơn.',
  ),
];

/// First-run onboarding carousel.
class OnboardingPage extends HookConsumerWidget {
  const OnboardingPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pageController = usePageController();
    final currentPage = useState(0);
    final colors = Theme.of(context).colorScheme;

    Future<void> finish() async {
      await ref.read(onboardingCompletedProvider.notifier).complete();
      if (context.mounted) {
        context.go(RoutePaths.login);
      }
    }

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: finish,
                child: Text(
                  'Bỏ qua',
                  style: TextStyle(color: colors.onSurfaceVariant),
                ),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: pageController,
                itemCount: _slides.length,
                onPageChanged: (i) => currentPage.value = i,
                itemBuilder: (context, index) {
                  final slide = _slides[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 36),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 128,
                          height: 128,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                colors.primaryContainer,
                                colors.secondaryContainer,
                              ],
                            ),
                            borderRadius:
                                BorderRadius.circular(AppConstants.largeRadius),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.shadowLight,
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Icon(
                            slide.icon,
                            size: 56,
                            color: colors.primary,
                          ),
                        ),
                        const SizedBox(height: 44),
                        Text(
                          slide.title,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          slide.subtitle,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                color: colors.onSurfaceVariant,
                                height: 1.6,
                              ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_slides.length, (i) {
                final active = i == currentPage.value;
                return AnimatedContainer(
                  duration: AppConstants.animationDuration,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: active ? 28 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: active ? colors.secondary : colors.outlineVariant,
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
              }),
            ),
            const SizedBox(height: 32),
            Padding(
              padding: const EdgeInsets.all(AppConstants.defaultPadding),
              child: AppButton(
                label: currentPage.value == _slides.length - 1
                    ? 'Bắt đầu'
                    : 'Tiếp theo',
                expand: true,
                size: AppButtonSize.large,
                onPressed: () {
                  if (currentPage.value < _slides.length - 1) {
                    pageController.nextPage(
                      duration: AppConstants.animationDuration,
                      curve: Curves.easeOutCubic,
                    );
                  } else {
                    finish();
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
