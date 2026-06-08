/// Résultat d'une tentative d'achat in-app.
enum IapPurchaseResult {
  success,
  cancelled,
  unavailable,
  productNotFound,
  error,
}

/// Résultat d'une restauration d'achats.
enum IapRestoreResult {
  restored,
  alreadyPremium,
  nothingToRestore,
  unavailable,
}
