import 'package:snapstudy/features/weak_areas/data/models/weak_area_item_model.dart';
import 'package:snapstudy/features/weak_areas/domain/entities/session_weak_areas_insight.dart';

class SessionWeakAreasInsightModel {
  const SessionWeakAreasInsightModel({
    required this.items,
    required this.aiAdvice,
    required this.generatedAt,
  });

  factory SessionWeakAreasInsightModel.fromJson(Map<String, dynamic> json) {
    final itemsRaw = json['items'] as List<dynamic>? ?? [];
    return SessionWeakAreasInsightModel(
      items: itemsRaw
          .map(
            (e) => WeakAreaItemModel.fromJson(
              Map<String, dynamic>.from(e as Map),
            ),
          )
          .toList(),
      aiAdvice: json['aiAdvice'] as String? ?? '',
      generatedAt: DateTime.parse(json['generatedAt'] as String),
    );
  }

  final List<WeakAreaItemModel> items;
  final String aiAdvice;
  final DateTime generatedAt;

  Map<String, dynamic> toJson() => {
        'items': items.map((i) => i.toJson()).toList(),
        'aiAdvice': aiAdvice,
        'generatedAt': generatedAt.toIso8601String(),
      };

  SessionWeakAreasInsight toEntity() => SessionWeakAreasInsight(
        items: items.map((i) => i.toEntity()).toList(),
        aiAdvice: aiAdvice,
        generatedAt: generatedAt,
      );

  static SessionWeakAreasInsightModel fromEntity(SessionWeakAreasInsight i) =>
      SessionWeakAreasInsightModel(
        items: i.items.map(WeakAreaItemModel.fromEntity).toList(),
        aiAdvice: i.aiAdvice,
        generatedAt: i.generatedAt,
      );
}
