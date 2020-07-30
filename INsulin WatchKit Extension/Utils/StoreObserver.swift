import StoreKit

class StoreObserver: NSObject, SKPaymentTransactionObserver, SKProductsRequestDelegate {
  var availableProducts = Array<SKProduct>();
  var invalidProductIdentifiers = Array<String>();
  
  func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
    if !response.products.isEmpty {
      availableProducts = response.products
    }
    
    // invalidProductIdentifiers contains all product identifiers not recognized by the App Store.
    if !response.invalidProductIdentifiers.isEmpty {
      invalidProductIdentifiers = response.invalidProductIdentifiers
    }
  }
  
  
  static let current = StoreObserver()
  
  override init() {
    super.init()
  }
  
  //Observe transaction updates.
  func paymentQueue(_ queue: SKPaymentQueue,updatedTransactions transactions: [SKPaymentTransaction]) {
    
    /*if (transaction.error as? SKError)?.code != .paymentCancelled {
      DispatchQueue.main.async {
        self.delegate?.storeObserverDidReceiveMessage(message)
      }
    }*/
    
    for transaction in transactions {
      switch transaction.transactionState {
      case .purchasing: break
      // Do not block the UI. Allow the user to continue using the app.
      /*case .deferred: print(Messages.deferred)
      // The purchase was successful.
      case .purchased: handlePurchased(transaction)
      // The transaction failed.
      case .failed: handleFailed(transaction)
      // There're restored products.
      case .restored: handleRestored(transaction)*/
      @unknown default: break;//fatalError(Messages.unknownPaymentTransaction)
      }
    }
  }
  
  var isAuthorizedForPayments: Bool {
    return SKPaymentQueue.canMakePayments()
  }
  
  private func fetchProducts(matchingIdentifiers identifiers: [String]) {
    // Create a set for the product identifiers.
    let productIdentifiers = Set(identifiers)
    
    // Initialize the product request with the above identifiers.
    let productRequest = SKProductsRequest(productIdentifiers: productIdentifiers)
    productRequest.delegate = self
    
    // Send the request to the App Store.
    productRequest.start()
  }
}
