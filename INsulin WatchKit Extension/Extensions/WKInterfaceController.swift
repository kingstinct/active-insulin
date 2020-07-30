//
//  WKInterfaceController.swift
//  INsulin WatchKit Extension
//
//  Created by Robert Herber on 2020-07-30.
//  Copyright © 2020 Robert Herber. All rights reserved.
//

import WatchKit

private var isPresentingAuth = false;

private var handlers = Array<(Bool, Bool) -> Void>();

extension WKInterfaceController {
  
  func presentAuthAlert(handler: @escaping (Bool, Bool) -> Void){
    handlers.append(handler);
    if(!isPresentingAuth){
      isPresentingAuth = true;

      self.presentAlert(withTitle: LocalizedString("please_authorize_title"), message: LocalizedString("please_authorize"), preferredStyle: WKAlertControllerStyle.alert, actions: [
        WKAlertAction.init(title: LocalizedString("allow"), style: WKAlertActionStyle.default, handler: {
          Auth.current.requestPermissions(handler: { (healthKitSuccess, notificationSuccess) in
            isPresentingAuth = false;
            handlers.forEach { (handler) in
              handler(healthKitSuccess, notificationSuccess);
            }
          })
        })
      ])
    }
  }
}
