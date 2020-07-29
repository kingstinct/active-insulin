import SwiftUI
import Combine


struct SettingsInsulinView: View {
  @ObservedObject var appState: AppState
  
  @ViewBuilder
  var body: some View {
    ScrollView {
      VStack(alignment: .center){
        StyledGroup {
          HStack {
            Text("Duration")
            Text(appState.insulinDurationInMinutes.format(f: "1.0") + " " + NSLocalizedString("min", comment: "Minutes"))
          }
          Slider(value: $appState.insulinDurationInMinutes, in: ClosedRange(uncheckedBounds: (lower: 200, upper: 600)), step: 5) {
            Text("Insulin Duration")
          }
        }
        
        StyledGroup {
          HStack {
            Text("Peak")
            Text(appState.insulinPeakTimeInMinutes.format(f: "1.0") + " " + NSLocalizedString("min", comment: "Minutes"))
          }
          Slider(value: $appState.insulinPeakTimeInMinutes, in: ClosedRange(uncheckedBounds: (lower: 30, upper: 100)), step: 5) {
            Text("Insulin Duration")
          }
        }
        
        StyledGroup {
          HStack {
            Text("Step size")
            Text(appState.insulinStepSize.format(f: "0.1"))
          }
          Slider(value: $appState.insulinStepSize, in: ClosedRange(uncheckedBounds: (lower: 0.5, upper: 1.0)), step: 0.5, minimumValueLabel: Text("0.5"), maximumValueLabel: Text("1")) {
            Text("Insulin Step Size")
          }
        }
        
        
        
        
        
        
        /*Picker(selection: $value, label: "Step Size") {
         ForEach(0 ..< options.count){
         Text(self.options[$0])
         }
         }*/
        
      }
    }
    .navigationBarTitle(LocalizedStringKey(stringLiteral: "insulin"))
  }
}




struct SettingsStepSizeView_Previews: PreviewProvider {
  static var previews: some View {
    SettingsInsulinView(appState: AppState.current)
  }
}
