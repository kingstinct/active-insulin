import SwiftUI

struct StyledGroup<Content> : View where Content : View {
  var content: Content
  
  init(@ViewBuilder builder: () -> Content) {
    content = builder()
  }
  
  var body: some View {
    VStack {
      content
    }.padding().background(Color.AlmostBlack).cornerRadius(10, antialiased: true)
  }
}
