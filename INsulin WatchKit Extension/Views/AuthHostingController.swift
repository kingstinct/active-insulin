//
//  InsulinInputHostingController.swift
//  glucool-watch WatchKit Extension
//
//  Created by Robert Herber on 2020-07-24.
//  Copyright © 2020 Robert Herber. All rights reserved.
//

import WatchKit
import Foundation
import SwiftUI
import HealthKit
import Combine
import YOChartImageKit

class AuthHostingController: WKHostingController<AuthView> {
  
  override func awake(withContext context: Any?) {
    
  }
  
  override func didAppear() {
  }
  
  
  override var body: AuthView {
    return AuthView(appState: AppState.current)
    // return InsulinInputView(saveAction: saveAction, appState: AppState.current)
  }
}



