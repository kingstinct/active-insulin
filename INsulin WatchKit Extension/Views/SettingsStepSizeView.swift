import SwiftUI
import Combine


struct SettingsInsulinView: View {
  @ObservedObject var appState: AppState
  
  @ViewBuilder
  var body: some View {
    VStack(alignment: .center){
      
      Slider(value: $appState.insulinStepSize, in: ClosedRange(uncheckedBounds: (lower: 0.5, upper: 1.0)), minimumValueLabel: Text("0.5"), maximumValueLabel: Text("1")) {
        Text("Insulin Step Size")
      }
      
      StyledGroup {
        Text("Hello")
        Slider(value: $appState.insulinDurationInMinutes, in: ClosedRange(uncheckedBounds: (lower: 0.5, upper: 1.0)), minimumValueLabel: Text("0.5"), maximumValueLabel: Text("1")) {
          Text("df")
        }
      }
      
      
      /*Picker(selection: $value, label: "Step Size") {
        ForEach(0 ..< options.count){
          Text(self.options[$0])
        }
      }*/
      
    }.navigationBarTitle(LocalizedStringKey(stringLiteral: "insulin"))
  }
}




struct SettingsStepSizeView_Previews: PreviewProvider {
  static var previews: some View {
    SettingsInsulinView(appState: AppState.current)
  }
}
