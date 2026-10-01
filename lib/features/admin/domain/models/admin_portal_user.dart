class AdminPortalUser {
  const AdminPortalUser({
    required this.uid,
    required this.roles,
    required this.isActive,
    this.organizationId,
    this.displayName,
    this.email,
  });

  final String uid;
  final Set<String> roles;
  final bool isActive;
  final String? organizationId;
  final String? displayName;
  final String? email;

  bool get isAdmin => roles.contains('admin');
  bool get isResponder => roles.contains('organizationMember');
  bool get canAccess => isActive && (isAdmin || isResponder);
}
