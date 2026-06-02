import 'package:equatable/equatable.dart';

/// A photo captured or imported during a camera session.
class CapturedPhoto extends Equatable {
  const CapturedPhoto({
    required this.localPath,
    required this.capturedAt,
  });

  final String localPath;
  final DateTime capturedAt;

  @override
  List<Object?> get props => [localPath, capturedAt];
}
