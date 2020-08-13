import WatchKit
import Foundation
import SwiftUI
import HealthKit
import Combine
import YOChartImageKit

class InjectionHostingController: WKHostingController<InjectionView> {
  
  let timeFormatter = DateFormatter();
  var injection: Injection?
  
  override init() {
    super.init()
    
    self.timeFormatter.dateFormat = "yyyy-MM-dd HH:mm"
  }
  
  override func awake(withContext context: Any?) {
    if let context = context as? Dictionary<String, Any> {
      self.injection = context["injection"] as? Injection
    }
  }
  
  override var body: InjectionView {
    /*let injection = Injection(date: Date(), insulinUnits: 0.5)*/
    
    return InjectionView(
      delete: {
        if let sample = self.injection?.quantitySample {
          Health.current.deleteSample(sample: sample) { (error) in
            self.pop()
          }
        }
        
    },
      injection: self.injection!, dateFormatter: self.timeFormatter)
  }
}
