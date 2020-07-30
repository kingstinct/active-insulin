import WatchKit
import SwiftUI

struct VolumeView: WKInterfaceObjectRepresentable {
  typealias WKInterfaceObjectType = WKInterfaceVolumeControl
  
  
  func makeWKInterfaceObject(context: Self.Context) -> WKInterfaceVolumeControl {
    let view = WKInterfaceVolumeControl(origin: .local)
    Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak view] timer in
      if let view = view {
        view.focus()
      } else {
        timer.invalidate()
      }
    }
    DispatchQueue.main.async {
      view.focus()
    }
    return view
  }
  func updateWKInterfaceObject(_ wkInterfaceObject: WKInterfaceVolumeControl, context: WKInterfaceObjectRepresentableContext<VolumeView>) {
  }
}
