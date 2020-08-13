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
  var listenToSelf: AnyCancellable? = nil;
  
  override func awake(withContext context: Any?) {
    listenToSelf = AppState.current.$activePage.sink { (page) in
      if(page == .settings){
        self.becomeCurrentPage()
        // self.crownSequencer.focus()
      } else {
        // self.crownSequencer.resignFocus()
      }
    }
  }

  override func didAppear() {

  }
  
  
  override var body: SettingsView {
    return SettingsView(appState: AppState.current)
    // return InsulinInputView(saveAction: saveAction, appState: AppState.current)
  }
}



