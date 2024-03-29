import WatchKit
import Foundation
import SwiftUI
import HealthKit
import Combine
import YOChartImageKit

class SettingsNotificationsHostingController: WKHostingController<SettingsNotificationsView> {
  
  override func didAppear() {
  }
  
  override func awake(withContext context: Any?) {
    StoreObserver.current.fetchProducts();
  }
  
  override var body: SettingsNotificationsView {
    return SettingsNotificationsView(appState: AppState.current)
    // return InsulinInputView(saveAction: saveAction, appState: AppState.current)
  }
}
