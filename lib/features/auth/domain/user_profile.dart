/// Identité de l'utilisateur côté domaine, sans type Firebase.
class UserProfile {
  const UserProfile({
    required this.uid,
    this.email,
    this.displayName,
  });

  final String uid;
  final String? email;
  final String? displayName;
}
