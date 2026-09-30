part of 'operations_portal_page.dart';

extension _OperationsPortalActions on _OperationsPortalPageState {
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
