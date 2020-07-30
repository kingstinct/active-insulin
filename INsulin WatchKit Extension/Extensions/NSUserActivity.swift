//
//  NSUserActivity.swift
//  INsulin WatchKit Extension
//
//  Created by Robert Herber on 2020-07-28.
//  Copyright © 2020 Robert Herber. All rights reserved.
//

import Foundation

extension NSUserActivity {
  /// Activity of viewing the current status of the Loop
  static let displayIOBActivityTypeIdentifier = "com.kingstinct.INsulin.displayIOB"
  
  class func displayIOBActivityType() -> NSUserActivity {
    let title = LocalizedString("insulin_on_board");
    let userActivity = NSUserActivity(activityType: displayIOBActivityTypeIdentifier)
    userActivity.title = title
    userActivity.isEligibleForPrediction = true;
    userActivity.requiredUserInfoKeys = []
    userActivity.isEligibleForSearch = true
    userActivity.isEligibleForHandoff = false
    userActivity.isEligibleForPublicIndexing = false

    return userActivity;
  }

}
