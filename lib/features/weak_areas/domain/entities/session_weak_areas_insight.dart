import 'package:equatable/equatable.dart';
import 'package:snapstudy/features/weak_areas/domain/entities/weak_area_item.dart';

/// Gợi ý ôn tập từ AI dựa trên hành vi học.
class SessionWeakAreasInsight extends Equatable {
  const SessionWeakAreasInsight({
    required this.items,
    required this.aiAdvice,
    required this.generatedAt,
  });

  final List<WeakAreaItem> items;
  final String aiAdvice;
  final DateTime generatedAt;

  @override
  List<Object?> get props => [items, aiAdvice, generatedAt];
}
