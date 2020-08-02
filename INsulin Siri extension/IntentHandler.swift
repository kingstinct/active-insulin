//
//  IntentHandler.swift
//  INsulin Siri extension
//
//  Created by Robert Herber on 2020-07-26.
//  Copyright © 2020 Robert Herber. All rights reserved.
//

import Intents
import Foundation

// As an example, this class is set up to handle Message intents.
// You will want to replace this or add other intents as appropriate.
// The intents you wish to handle must be declared in the extension's Info.plist.

// You can test your example integration by saying things to Siri like:
// "Send a message using <myApp>"
// "<myApp> John saying hello"
// "Search for messages in <myApp>"

import HealthKit

class AddInsulinIntentHandler : NSObject, AddInsulinIntentHandling {
  /*func provideUnitsOptions(for intent: AddInsulinIntent, with completion: @escaping ([Double]?, Error?) -> Void) {
    if let units = intent.units as? Double {
      completion([units], nil);
    } else {
      completion(nil, nil);
    }
  }*/

  
  func resolveUnits(for intent: AddInsulinIntent, with completion: @escaping (AddInsulinUnitsResolutionResult) -> Void) {
    if let units = intent.units as? Double {
      if (units >= 0.5) {
        return completion(AddInsulinUnitsResolutionResult.success(with: units));
      } else if(units < 0) {
        return completion(AddInsulinUnitsResolutionResult
          .unsupported(forReason: .negativeNumbersNotSupported));
      } else {
        return completion(AddInsulinUnitsResolutionResult.unsupported(forReason: .lessThanMinimumValue));
      }
    }
    completion(AddInsulinUnitsResolutionResult.unsupported(forReason: .lessThanMinimumValue));
  }
  
  func handle(intent: AddInsulinIntent, completion: @escaping (AddInsulinIntentResponse) -> Void) {
    if let units = intent.units as? Double {
      let now = Date();
      let sample = HKQuantitySample.init(type: Health.current.insulinQuantityType, quantity: HKQuantity(unit: HKUnit.internationalUnit(), doubleValue: units), start: now, end: now,
                                         metadata: [HKMetadataKeyInsulinDeliveryReason : HKInsulinDeliveryReason.bolus.rawValue]
      )
    
      Health.current.healthStore.save(sample) { (success, error) in
        if(success){
          Health.current.fetchIOB { (error, iob) in
            if let iob = iob {
              completion(AddInsulinIntentResponse.success(insulinOnBoard: NSNumber(value: iob)))
            } else {
              completion(AddInsulinIntentResponse(code: .success, userActivity: nil))
            }
          }
          
        } else {
          completion(AddInsulinIntentResponse(code: .failure, userActivity: nil))
        }
      }
    } else {
      completion(AddInsulinIntentResponse(code: .failure, userActivity: nil))
    }
  }
  
  /* func resolveUnits(for intent: AddInsulinIntent, with completion: @escaping (AddInsulinUnitsResolutionResult) -> Void) {
    if let units = intent.units as? Double {
      if(units > 0.5){
        return completion(AddInsulinUnitsResolutionResult.success(with: units));
      } else if(units < 0){
        return completion(AddInsulinUnitsResolutionResult.unsupported(forReason: .negativeNumbersNotSupported));
      }
    }
    completion(AddInsulinUnitsResolutionResult.unsupported(forReason: .lessThanMinimumValue));
  }*/

  
  
}

class IntentHandler: INExtension {
  
    
    override func handler(for intent: INIntent) -> Any {
      if intent is AddInsulinIntent {
        return AddInsulinIntentHandler();
      }
      
      //guard intent is INAddinsulin
        // let if intent is IN
        // This is the default implementation.  If you want different objects to handle different intents,
        // you can override this and return the handler you want for that particular intent.
        
        return self
    }
}

