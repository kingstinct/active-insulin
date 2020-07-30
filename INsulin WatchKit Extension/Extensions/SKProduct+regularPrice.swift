import StoreKit;

extension SKProduct {
  /// - returns: The cost of the product formatted in the local currency.
  var regularPrice: String? {
    let formatter = NumberFormatter()
    formatter.numberStyle = .currency
    formatter.locale = self.priceLocale
    return formatter.string(from: self.price)
  }
}
