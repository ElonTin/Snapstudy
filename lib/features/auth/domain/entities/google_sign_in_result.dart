import 'package:equatable/equatable.dart';

/// Raw Google sign-in payload before backend JWT exchange.
class GoogleSignInResult extends Equatable {
  const GoogleSignInResult({
    required this.idToken,
    required this.email,
    this.displayName,
    this.photoUrl,
    this.googleUserId,
  });

  final String idToken;
  final String email;
  final String? displayName;
  final String? photoUrl;
  final String? googleUserId;

  @override
  List<Object?> get props => [idToken, email, displayName, photoUrl, googleUserId];
}
