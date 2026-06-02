import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:snapstudy/core/constants/app_constants.dart';
import 'package:snapstudy/core/env/env_config.dart';
import 'package:snapstudy/core/errors/failures.dart';
import 'package:snapstudy/core/theme/app_colors.dart';
import 'package:snapstudy/core/utils/extensions.dart';
import 'package:snapstudy/core/widgets/app_button.dart';
import 'package:snapstudy/features/auth/presentation/providers/auth_providers.dart';
import 'package:snapstudy/features/auth/presentation/widgets/google_sign_in_button.dart';

/// Login screen — Google Sign-In + optional dev auth.
class LoginPage extends ConsumerWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);
    final isLoading = authState.isLoading;
    final colors = Theme.of(context).colorScheme;

    ref.listen(authControllerProvider, (prev, next) {
      if (next is AsyncError) {
        final error = next.error;
        final message = error is Failure ? error.message : error.toString();
        context.showSnack(message, isError: true);
      }
    });

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.defaultPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              Center(
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        AppColors.aiGradientStart,
                        AppColors.aiGradientEnd,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: const Icon(
                    Icons.camera_enhance_rounded,
                    color: Colors.white,
                    size: 40,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Chào mừng đến ${AppConstants.appName}',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'Đăng nhập để đồng bộ buổi học và tài liệu AI của bạn',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
              ),
              const Spacer(),
              GoogleSignInButton(
                isLoading: isLoading,
                onPressed: () =>
                    ref.read(authControllerProvider.notifier).signInWithGoogle(),
              ),
              if (EnvConfig.authDevMode) ...[
                const SizedBox(height: 12),
                AppButton(
                  label: 'Đăng nhập Dev (không cần Google)',
                  variant: AppButtonVariant.outline,
                  expand: true,
                  isLoading: isLoading,
                  onPressed: () =>
                      ref.read(authControllerProvider.notifier).signInDev(),
                ),
              ],
              const SizedBox(height: 24),
              Text(
                'Bằng việc tiếp tục, bạn đồng ý với Điều khoản & Chính sách bảo mật',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
