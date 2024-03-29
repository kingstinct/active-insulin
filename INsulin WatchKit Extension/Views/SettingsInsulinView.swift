import SwiftUI
import Combine


struct SettingsInsulinView: View {
  @ObservedObject var appState: AppState
  
  @ViewBuilder
  var body: some View {
    ScrollView {
      VStack(alignment: .center){
        Text("insulin_info").padding()
        StyledGroup {
          HStack {
            Text("duration")
            Text(appState.insulinDurationInMinutes.format("1.0") + " " + LocalizedString("min")).frame(minWidth: 0, maxWidth: .infinity, alignment: .trailing)
          }
          Slider(value: $appState.insulinDurationInMinutes, in: ClosedRange(uncheckedBounds: (lower: 200, upper: 600)), step: 5) {
            Text("Insulin Duration")
          }.accentColor(Color.AccentColor)
        }
        
        StyledGroup {
          HStack {
            Text("peak")
            Text(appState.insulinPeakTimeInMinutes.format("1.0") + " " + LocalizedString("min")).frame(minWidth: 0, maxWidth: .infinity, alignment: .trailing)
          }
          Slider(value: $appState.insulinPeakTimeInMinutes, in: ClosedRange(uncheckedBounds: (lower: 30, upper: 100)), step: 5) {
            Text("Insulin Duration")
          }.accentColor(Color.AccentColor)
        }
        
        StyledGroup {
          HStack {
            Text("step_size")
            Text(appState.insulinStepSize.format("0.1")).frame(minWidth: 0, maxWidth: .infinity, alignment: .trailing)
          }
          Slider(value: $appState.insulinStepSize, in: ClosedRange(uncheckedBounds: (lower: 0.5, upper: 1.0)), step: 0.5, minimumValueLabel: Text("0.5"), maximumValueLabel: Text("1")) {
            Text("Insulin Step Size")
          }.accentColor(Color.AccentColor)
        }
        
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
