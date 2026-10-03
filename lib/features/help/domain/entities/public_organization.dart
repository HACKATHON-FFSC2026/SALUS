/// Informations publiques d'une organisation active et vérifiée.
class PublicOrganization {
  const PublicOrganization({
    required this.id,
    required this.name,
    required this.type,
    this.email,
    this.phone,
  });

  final String id;
  final String name;
  final String type;
  final String? email;
  final String? phone;
}
