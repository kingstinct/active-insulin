import SwiftUI
import Combine

struct SettingsNotificationsView: View {
  let customStepSize: Double = 15
  /*@State var peakInsulinEnabled: Bool = AppState.current.notifyOnInsulinPeakEnabled;
  @State var noInsulinEnabled: Bool = false;
  @State var customInsulinEnabled: Bool = AppState.current.notifyOnCustomEnabled;
  @State var snooze15: Bool = AppState.current.snooze15Enabled;
  @State var snooze30: Bool = AppState.current.snooze30Enabled;
  @State var snooze60: Bool = AppState.current.snooze60Enabled;
  @State var customNotificationTime: Double = AppState.current.insulinPeakTimeInMinutes;*/
  @ObservedObject var appState: AppState = AppState.current;
  
  func onSave() -> Void {
    WKInterfaceDevice.current().play(.success)
  }
  
  var body: some View {
    ScrollView {
      VStack(alignment: .center){
        /*Button(action: {
          if let product = StoreObserver.current.availableProducts.first{
            StoreObserver.current.makePurchase(product: product)
          }
        }, label: {
          Text("go_premium")
        })
        
        Button(action: {
          StoreObserver.current.restorePurchases();
        }, label: {
          Text("restore_purchases")
        })*/
        Toggle(isOn: $appState.notifyOnInsulinPeakEnabled){
          Text("notification_peak_title")
        }.padding().accentColor(Color(UIColor.magenta))/*.onReceive(Just(peakInsulinEnabled)) { (value) in
          if(value != AppState.current.notifyOnInsulinPeakEnabled){
            AppState.current.notifyOnInsulinPeakEnabled = value
          }
        }*/
        Toggle(isOn: $appState.notifyOnInsulinZeroEnabled){
          Text("no_insulin")
        }.padding()
        /*StyledGroup {
          Toggle(isOn:  $appState.notifyOnCustomEnabled){
            Text(appState.notifyOnCustomMinutes.format(f: "1.0") + " " + NSLocalizedString("min", comment: "Minutes"))
            }.padding(0)
          Slider(value: $appState.notifyOnCustomMinutes, in: ClosedRange(uncheckedBounds: (lower: customStepSize, upper: Double(appState.insulinDurationInMinutes))), step: self.customStepSize, minimumValueLabel: Text(customStepSize.format(f: "1.0")), maximumValueLabel: Text(appState.insulinDurationInMinutes.format(f: "1.0")), label: {
            Text(appState.notifyOnCustomMinutes.format(f: "1.0"))
            }).padding(0).disabled(!appState.notifyOnCustomEnabled)
          }.accentColor(Color.AccentColor)*/
        StyledGroup {
          Text("snooze_options").bold()
          Toggle(isOn: $appState.snooze15Enabled){
            Text("15" + LocalizedString("min"))
          }.padding()
          Toggle(isOn: $appState.snooze30Enabled){
            Text("30" + LocalizedString("min"))
          }.padding()
          Toggle(isOn:  $appState.snooze60Enabled){
            Text("60" + LocalizedString("min"))
          }.padding()
        }
        
        /*Picker(selection: $value, label: "Step Size") {
         ForEach(0 ..< options.count){
         Text(self.options[$0])
         }
         }*/
        
      }.navigationBarTitle(LocalizedStringKey(stringLiteral: "notifications"))
    }
    
  }
}




struct SettingsNotificationsView_Previews: PreviewProvider {
  static var previews: some View {
    SettingsNotificationsView()
  }
}
