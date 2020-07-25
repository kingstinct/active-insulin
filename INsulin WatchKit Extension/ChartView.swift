//
//  ContentView.swift
//  glucool-watch WatchKit Extension
//
//  Created by Robert Herber on 2020-07-24.
//  Copyright © 2020 Robert Herber. All rights reserved.
//

import SwiftUI
import Combine

class OptionalData: ObservableObject {
    @Published var chartImage: UIImage?
}

struct ChartView: View {
    var activeInsulin: Double
    @ObservedObject var optionalData: OptionalData
    var body: some View {
        
        VStack(alignment: .leading, spacing: 0){
                self.optionalData.chartImage.map { image in
                    Image(uiImage: image)
                }
                HStack(alignment: .top, spacing: 0) {
                    VStack(alignment: .leading, spacing: 0) {
                        Text("IOB").multilineTextAlignment(.leading)
                        Text("\(activeInsulin.format(f: "0.1"))")
                    }.frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
                    Text("in 5 hours").multilineTextAlignment(.trailing).frame(minWidth: 0, maxWidth: .infinity, alignment: .trailing)
                }.frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
                
            }
        
        
    }
}

struct ChartView_Previews: PreviewProvider {
    static var previews: some View {
        let optionalData = OptionalData()
        return ChartView(activeInsulin: 5, optionalData: optionalData)
    }
}
