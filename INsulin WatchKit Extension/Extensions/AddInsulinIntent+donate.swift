//
//  AddInsulinIntent.swift
//  INsulin WatchKit Extension
//
//  Created by Robert Herber on 2020-08-02.
//  Copyright © 2020 Robert Herber. All rights reserved.
//

import Foundation
import Intents

extension AddInsulinIntent {
  static func donate(units: Double?){
    let intent = AddInsulinIntent()
    if let units = units {
      intent.suggestedInvocationPhrase = "Add " + units.format("1") + " units of insulin"
      intent.units = NSNumber(value: units)
    }
    else {
      intent.suggestedInvocationPhrase = "Add insulin"
    }
    
    let interaction = INInteraction(intent: intent, response: nil)
    interaction.dateInterval = DateInterval(start: Date(), duration: 0);
    interaction.donate { error in
      if let error = error as NSError? {
        print("Interaction donation failed: \(error.description)")
      } else {
        print("Successfully donated interaction")
      }
    }
  }
}
