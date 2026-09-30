class AdminPortalRecord {
  const AdminPortalRecord({
    required this.id,
    this.name,
    this.displayName,
    this.description,
    this.email,
    this.roles = const [],
    this.distressType,
    this.createdAt,
    this.startedAt,
    this.address,
    this.capacityOccupied,
    this.capacityTotal,
    this.contactEmail,
    this.type,
    this.targetType,
    this.status,
    this.verified = false,
    this.validationStatus,
    this.isActive,
    this.organizationId,
    this.assignedOrganizationId,
    this.createdBy,
  });

  final String id;
  final String? name;
  final String? displayName;
  final String? description;
  final String? email;
  final List<String> roles;
  final String? distressType;
  final DateTime? createdAt;
  final DateTime? startedAt;
  final String? address;
  final int? capacityOccupied;
  final int? capacityTotal;
  final String? contactEmail;
  final String? type;
  final String? targetType;
  final String? status;
  final bool verified;
  final String? validationStatus;
  final bool? isActive;
  final String? organizationId;
  final String? assignedOrganizationId;
  final String? createdBy;

  String get title => name ?? displayName ?? description ?? id;
}
