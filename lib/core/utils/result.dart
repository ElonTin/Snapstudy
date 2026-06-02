import 'package:equatable/equatable.dart';
import 'package:snapstudy/core/errors/failures.dart';

/// Functional result type for repository/use-case boundaries.
sealed class Result<T> extends Equatable {
  const Result();

  bool get isSuccess => this is Success<T>;
  bool get isFailure => this is Error<T>;

  T? get valueOrNull => switch (this) {
        Success(value: final v) => v,
        _ => null,
      };

  Failure? get failureOrNull => switch (this) {
        Error(failure: final f) => f,
        _ => null,
      };

  Result<R> map<R>(R Function(T data) transform) => switch (this) {
        Success(value: final v) => Success(transform(v)),
        Error(failure: final f) => Error(f),
      };

  Future<Result<R>> flatMap<R>(Future<Result<R>> Function(T data) transform) =>
      switch (this) {
        Success(value: final v) => transform(v),
        Error(failure: final f) => Future.value(Error(f)),
      };

  R fold<R>({
    required R Function(T data) onSuccess,
    required R Function(Failure failure) onFailure,
  }) =>
      switch (this) {
        Success(value: final v) => onSuccess(v),
        Error(failure: final f) => onFailure(f),
      };

  @override
  List<Object?> get props => [];
}

final class Success<T> extends Result<T> {
  const Success(this.value);

  final T value;

  @override
  List<Object?> get props => [value];
}

final class Error<T> extends Result<T> {
  const Error(this.failure);

  final Failure failure;

  @override
  List<Object?> get props => [failure];
}
