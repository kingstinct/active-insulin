//
//  ContentView.swift
//  glucool-watch WatchKit Extension
//
//  Created by Robert Herber on 2020-07-24.
//  Copyright © 2020 Robert Herber. All rights reserved.
//

import SwiftUI
import Combine

extension Double {
    func format(f: String) -> String {
        return String(format: "%\(f)f", self)
    }
}

struct ContentView: View {
    @State var insulin: Double = 0.5
    @State var rotation: Double = 0.0
    @State var lastRotation: Double = 0.0
    var activeInsulin: Double
    var saveAction: ((_: Double) -> Void)?
    var body: some View {
        VStack(alignment: .center){
            Text("Insulin on Board")
            Text("\(activeInsulin.format(f: "0.1"))")
            Text("Units of insulin").focusable(true)
                .digitalCrownRotation(
                $rotation,
                from: -100000,
                through: 100000,
                by: 1,
                sensitivity: .low,
                isContinuous: true,
                isHapticFeedbackEnabled: true
            ).onAppear() {
                
            }.onReceive(Just(rotation)) { output in
                let diff = output - self.lastRotation
                
                if(diff > 1){
                    self.lastRotation = output
                    self.insulin = self.insulin + 0.5
                }
                else if(diff < -1){
                    self.lastRotation = output
                    self.insulin = self.insulin > 0.5 ? self.insulin - 0.5 : 0.5
                }
            }
            Text("\(insulin.format(f: "0.1"))")
            Button(action: {
                self.saveAction?(self.insulin)
            }){
                Text("Save")
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        return ContentView(insulin: 10, rotation: 0, lastRotation: 0, activeInsulin: 5, saveAction: nil)
    }
}
