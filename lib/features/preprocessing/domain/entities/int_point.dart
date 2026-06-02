import 'package:equatable/equatable.dart';

/// 2D point for document geometry (platform-agnostic).
class IntPoint extends Equatable {
  const IntPoint(this.x, this.y);

  final int x;
  final int y;

  @override
  List<Object?> get props => [x, y];
}
