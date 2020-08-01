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

class SettingsHostingController: WKHostingController<SettingsView> {
  
  override func awake(withContext context: Any?) {
    
  }

  override func didAppear() {
    if(AppState.current.activePage != .settings) {
      AppState.current.activePage = .settings
    }
  }
  
  
  override var body: SettingsView {
    return SettingsView(appState: AppState.current)
    // return InsulinInputView(saveAction: saveAction, appState: AppState.current)
  }
}



