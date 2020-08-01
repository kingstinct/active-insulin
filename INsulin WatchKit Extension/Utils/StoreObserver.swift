import StoreKit

class StoreObserver: NSObject, SKPaymentTransactionObserver, SKProductsRequestDelegate {
  var availableProducts = Array<SKProduct>();
  var invalidProductIdentifiers = Array<String>();
  
  func request(_ request: SKRequest, didFailWithError error: Error) {
    print("finished with error")
  }
  
  //Initialize the store observer.
  override init() {
    super.init()
    //Other initialization here.
    fetchProducts()
  }
  
  func requestDidFinish(_ request: SKRequest) {
    print("finished")
  }
  
  func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
    
    if !response.products.isEmpty {
      availableProducts = response.products
    }
    
    // invalidProductIdentifiers contains all product identifiers not recognized by the App Store.
    if !response.invalidProductIdentifiers.isEmpty {
      invalidProductIdentifiers = response.invalidProductIdentifiers
    }
  }
  
  let identifiers = ["com.kingstinct.INsulin.premium_monthly", "com.kingstinct.INsulin.premium-monthly"];
  
  static let current = StoreObserver()
  
  func makePurchase(product: SKProduct){
    let payment = SKPayment(product: product);
    SKPaymentQueue.default().add(payment);
  }
  
  func restorePurchases(){
    SKPaymentQueue.default().restoreCompletedTransactions()
  }
  
  func getExpirationDateFromResponse(_ jsonResponse: NSDictionary) -> Date? {
    
    if let receiptInfo: NSArray = jsonResponse["latest_receipt_info"] as? NSArray {
      
      let lastReceipt = receiptInfo.lastObject as! NSDictionary
      let formatter = DateFormatter()
      formatter.dateFormat = "yyyy-MM-dd HH:mm:ss VV"
      
      if let expiresDate = lastReceipt["expires_date"] as? String {
        return formatter.date(from: expiresDate)
      }
      
      return nil
    }
    else {
      return nil
    }
  }
  
  let verifyReceiptURL = "https://sandbox.itunes.apple.com/verifyReceipt" // https://buy.itunes.apple.com/verifyReceipt
  
  func receiptValidation() {
    let receiptFileURL = Bundle.main.appStoreReceiptURL
    let receiptData = try? Data(contentsOf: receiptFileURL!)
    let recieptString = receiptData?.base64EncodedString(options: NSData.Base64EncodingOptions(rawValue: 0))
    let jsonDict: [String: AnyObject] = ["receipt-data" : recieptString! as AnyObject, "password" : "ee70188badc24b1fa8c78f1ddb4cbb3a" as AnyObject]
    
    do {
      let requestData = try JSONSerialization.data(withJSONObject: jsonDict, options: JSONSerialization.WritingOptions.prettyPrinted)
      let storeURL = URL(string: verifyReceiptURL)!
      var storeRequest = URLRequest(url: storeURL)
      storeRequest.httpMethod = "POST"
      storeRequest.httpBody = requestData
      
      let session = URLSession(configuration: URLSessionConfiguration.default)
      let task = session.dataTask(with: storeRequest, completionHandler: { [weak self] (data, response, error) in
        
        do {
          let jsonResponse = try JSONSerialization.jsonObject(with: data!, options: JSONSerialization.ReadingOptions.mutableContainers)
          print("=======>",jsonResponse)
          if let date = self?.getExpirationDateFromResponse(jsonResponse as! NSDictionary) {
            print(date)
            AppState.current.isPremiumUntil = date.timeIntervalSince1970
          }
        } catch let parseError {
          print(parseError)
        }
      })
      task.resume()
    } catch let parseError {
      print(parseError)
    }
  }
  
  func handlePurchased(_ transaction: SKPaymentTransaction){
    var components = DateComponents();
    components.month = 1;
    let date = Calendar.current.date(byAdding: components, to: Date())
    AppState.current.isPremiumUntil = date?.timeIntervalSince1970 ?? 0
    receiptValidation()
    SKPaymentQueue.default().finishTransaction(transaction);
  }
   
  func handleFailed(_ transaction: SKPaymentTransaction){
    if let transactionError = transaction.error as NSError?,
      let localizedDescription = transaction.error?.localizedDescription,
      transactionError.code != SKErrorCode.paymentCancelled.rawValue {
      print("Transaction Error: \(localizedDescription)")
    }
    
    SKPaymentQueue.default().finishTransaction(transaction)
  }
  
  func handleRestored(_ transaction: SKPaymentTransaction){
    var components = DateComponents();
    components.month = 1;
    let date = Calendar.current.date(byAdding: components, to: Date())
    AppState.current.isPremiumUntil = date?.timeIntervalSince1970 ?? 0
    SKPaymentQueue.default().finishTransaction(transaction);
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
      case .purchasing: break;
      // Do not block the UI. Allow the user to continue using the app.
      case .deferred: break;
      // The purchase was successful.
      case .purchased: handlePurchased(transaction)
      // The transaction failed.
      case .failed: handleFailed(transaction)
      // There're restored products.
      case .restored: handleRestored(transaction)
      @unknown default: break;//fatalError(Messages.unknownPaymentTransaction)
      }
    }
  }
  
  var isAuthorizedForPayments: Bool {
    return SKPaymentQueue.canMakePayments()
  }
  
  func fetchProducts() {
    if(SKPaymentQueue.canMakePayments()){
      // Create a set for the product identifiers.
      let productIdentifiers = Set(identifiers)
      
      // Initialize the product request with the above identifiers.
      let productRequest = SKProductsRequest(productIdentifiers: productIdentifiers)
      productRequest.delegate = self
      
      // Send the request to the App Store.
      productRequest.start()
    } else {
      
    }
    
  }
}
