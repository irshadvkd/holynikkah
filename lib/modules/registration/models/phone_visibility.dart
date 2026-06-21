/// Phone visibility for registration (`mob_visibility` API field).
enum PhoneVisibility {
  visibleToAll(true, 'Visible to all'),
  onRequest(false, 'On request');

  const PhoneVisibility(this.mobVisibility, this.label);

  /// Maps to `mob_visibility` on register: true = visible, false = on request.
  final bool mobVisibility;
  final String label;

  static PhoneVisibility fromMobVisibility(bool? value) {
    if (value == true) return PhoneVisibility.visibleToAll;
    return PhoneVisibility.onRequest;
  }
}
