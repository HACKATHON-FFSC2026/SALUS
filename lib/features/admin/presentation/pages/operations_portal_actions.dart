part of 'operations_portal_page.dart';

extension _OperationsPortalActions on _OperationsPortalPageState {
  Future<void> _createShelter() async {
    final formKey = GlobalKey<FormState>();
    final name = TextEditingController();
    final address = TextEditingController();
    final capacity = TextEditingController(text: '10');
    final latitude = TextEditingController();
    final longitude = TextEditingController();
    final created = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Nouveau refuge'),
        content: Form(
          key: formKey,
          child: SizedBox(
            width: 420,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _requiredField(name, 'Nom du refuge'),
                  _requiredField(address, 'Adresse'),
                  _requiredField(capacity, 'Capacité totale', numeric: true),
                  _requiredField(
                    latitude,
                    'Latitude',
                    decimal: true,
                    minimum: -90,
                    maximum: 90,
                  ),
                  _requiredField(
                    longitude,
                    'Longitude',
                    decimal: true,
                    minimum: -180,
                    maximum: 180,
                  ),
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () {
              if (!formKey.currentState!.validate()) return;
              Navigator.pop(dialogContext, true);
            },
            child: const Text('Créer et valider'),
          ),
        ],
      ),
    );
    if (created == true) {
      await ref
          .read(adminPortalUseCasesProvider)
          .createShelter(
            name: name.text.trim(),
            address: address.text.trim(),
            capacityTotal: int.parse(capacity.text.trim()),
            latitude: double.parse(latitude.text.trim()),
            longitude: double.parse(longitude.text.trim()),
            userId: _uid,
          );
    }
    name.dispose();
    address.dispose();
    capacity.dispose();
    latitude.dispose();
    longitude.dispose();
  }

  Widget _requiredField(
    TextEditingController controller,
    String label, {
    bool numeric = false,
    bool decimal = false,
    double? minimum,
    double? maximum,
  }) => TextFormField(
    controller: controller,
    decoration: InputDecoration(labelText: label),
    keyboardType: numeric || decimal
        ? const TextInputType.numberWithOptions(decimal: true)
        : TextInputType.text,
    validator: (value) {
      final text = value?.trim() ?? '';
      if (text.isEmpty) return 'Champ obligatoire';
      if (numeric && (int.tryParse(text) == null || int.parse(text) <= 0))
        return 'Entrez un entier positif';
      if (decimal) {
        final number = double.tryParse(text);
        if (number == null || !number.isFinite) return 'Coordonnée invalide';
        if ((minimum != null && number < minimum) ||
            (maximum != null && number > maximum)) {
          return 'Valeur entre $minimum et $maximum';
        }
      }
      return null;
    },
  );

  Future<void> _openRiskZoneEditor({
    String? organizationId,
    AdminPortalRecord? zone,
  }) async {
    await showDialog<bool>(
      context: context,
      builder: (context) => OperationsPortalZoneEditor(
        zone: zone,
        onSave:
            ({
              required id,
              required name,
              required disasterType,
              required severity,
              required geometry,
            }) => ref
                .read(adminPortalUseCasesProvider)
                .saveManualRiskZone(
                  id: id,
                  name: name,
                  disasterType: disasterType,
                  severity: severity,
                  geometry: geometry,
                  userId: _uid,
                  organizationId: organizationId,
                ),
      ),
    );
  }

  Future<void> _createOrganization() async {
    final formKey = GlobalKey<FormState>();
    final name = TextEditingController();
    final email = TextEditingController();
    final phone = TextEditingController();
    final created = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Nouvelle organisation'),
        content: Form(
          key: formKey,
          child: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: name,
                  decoration: const InputDecoration(labelText: 'Nom'),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Nom obligatoire'
                      : null,
                ),
                TextFormField(
                  controller: email,
                  decoration: const InputDecoration(
                    labelText: 'Email de contact',
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) => value == null || !value.contains('@')
                      ? 'Email invalide'
                      : null,
                ),
                TextFormField(
                  controller: phone,
                  decoration: const InputDecoration(labelText: 'Téléphone'),
                  keyboardType: TextInputType.phone,
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Téléphone obligatoire'
                      : null,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(dialogContext, true);
              }
            },
            child: const Text('Créer'),
          ),
        ],
      ),
    );
    if (created == true) {
      await ref
          .read(adminPortalUseCasesProvider)
          .createOrganization(
            name: name.text.trim(),
            email: email.text.trim(),
            phone: phone.text.trim(),
          );
    }
    name.dispose();
    email.dispose();
    phone.dispose();
  }
}
