import WatchKit
import Foundation
import SwiftUI
import HealthKit
import Combine
import YOChartImageKit

class SettingsInsulinHostingController: WKHostingController<SettingsInsulinView> {
  override var body: SettingsInsulinView {
    return SettingsInsulinView(appState: AppState.current)
    // return InsulinInputView(saveAction: saveAction, appState: AppState.current)
  }
}
