import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:snapstudy/core/routing/route_paths.dart';
import 'package:snapstudy/core/widgets/app_loading.dart';
import 'package:snapstudy/features/home/presentation/utils/home_ingest_flow.dart';

/// Redirect — mở thư viện ngay và chạy luồng ingest tự động.
class GalleryImportPage extends HookConsumerWidget {
  const GalleryImportPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    useEffect(() {
      Future.microtask(() async {
        if (!context.mounted) return;
        await runHomeGalleryIngest(context, ref);
        if (context.mounted && GoRouter.of(context).canPop()) {
          context.pop();
        } else if (context.mounted) {
          context.go(RoutePaths.home);
        }
      });
      return null;
    }, const []);

    return const Scaffold(
      body: AppLoading(
        fullScreen: true,
        useSkeleton: true,
        message: 'Đang mở thư viện ảnh...',
      ),
    );
  }
}
