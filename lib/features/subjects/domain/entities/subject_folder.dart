import 'package:equatable/equatable.dart';

/// Folder grouping for subjects (e.g. "Học kỳ 1", "Ôn thi").
class SubjectFolder extends Equatable {
  const SubjectFolder({
    required this.id,
    required this.name,
    required this.sortOrder,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String name;
  final int sortOrder;
  final DateTime createdAt;
  final DateTime updatedAt;

  @override
  List<Object?> get props => [id, name, sortOrder, createdAt, updatedAt];
}
