//
//  ChartBuilder.swift
//  INsulin WatchKit Extension
//
//  Created by Robert Herber on 2020-07-27.
//  Copyright © 2020 Robert Herber. All rights reserved.
//

import WatchKit
import YOChartImageKit

class ChartBuilder {
  
  
  static func getChartImage(vals: Array<ChartPoint>, now: Date = Date(), width: Double = Double(WKInterfaceDevice.current().screenBounds.width), chartHeight: Double = 100, showEdgeLines: Bool = true) -> UIImage?{
    
    if let max = vals.max(by: { (arg0, arg1) -> Bool in
      return arg0.currentInsulin < arg1.currentInsulin;
    }) {
      if let last = vals.last {
        if let first = vals.first {
          let maxDouble = max.currentInsulin * 1.2;
          
          let futureVals = vals.filter({ point -> Bool in
            return point.date.timeIntervalSince(now) >= 0
          }).map({ $0.currentInsulin / maxDouble });
          
          let previousVals = vals.filter({ point -> Bool in
            return point.date.timeIntervalSince(now) <= 0
          }).map({ $0.currentInsulin / maxDouble });
          
          let previousWidth = width * Double(previousVals.count) / Double(vals.count);
          let futureWidth = width * Double(futureVals.count) / Double(vals.count);
          
          let screenScale = WKInterfaceDevice.current().screenScale
          
          var imagePrevious: UIImage?;
          if(previousVals.count > 0){
            let previousChart = YOLineChartImage();
            let valsAsNumbers = previousVals as [NSNumber];
            previousChart.values = valsAsNumbers;
            previousChart.fillColor = UIColor.magenta.withAlphaComponent(0.3)
            previousChart.maxValue = 1;
            previousChart.smooth = false
            previousChart.strokeColor = UIColor.magenta.withAlphaComponent(0.5)
            previousChart.strokeWidth = 2.0
            
            
            imagePrevious = previousChart.draw(CGRect(x: 0, y: 0, width: previousWidth, height: chartHeight), scale: screenScale)
          }
          
          var imageFuture: UIImage?;
          
          if(futureVals.count > 0){
            let futureChart = YOLineChartImage();
            let futureAsNumbers = futureVals as [NSNumber];
            futureChart.values = futureAsNumbers;
            futureChart.maxValue = 1;
            futureChart.fillColor = UIColor.magenta.withAlphaComponent(0.6)
            futureChart.smooth = false
            futureChart.strokeColor = UIColor.magenta
            futureChart.strokeWidth = 2.0
            // futureChart.smooth = true
            
            imageFuture = futureChart.draw(CGRect(x: 0, y: 0, width: futureWidth, height: chartHeight), scale: screenScale)
          }
          
          
          let size = CGSize(width: width, height: chartHeight)
          UIGraphicsBeginImageContextWithOptions(size, false, screenScale)
          
          let context = UIGraphicsGetCurrentContext();
          
          
          let exactHourProviders = last.date.timeIntervalSince(first.date) / (60 * 60);
          /*let firstHour = Date(timeIntervalSince1970: ceil(first.date.timeIntervalSince1970 / (60 * 60)));
          let diff = firstHour.timeIntervalSince(first.date);
          let diffPartOfHour = diff / (60 * 60);
          let startX =*/
          let hourDividers = Int(floor(exactHourProviders));
          let widthPerDivider = width / exactHourProviders
          
          func drawLine(at: Double, lineWidth: CGFloat = 0.5, color: CGColor = UIColor.darkGray.cgColor) -> Void {
            context?.setLineWidth(lineWidth)
            context?.setStrokeColor(color);
            context?.move(to: CGPoint(x: at, y: 0))
            context?.addLine(to: CGPoint(x: at, y: chartHeight))
            context?.strokePath()
          }
          
          if(showEdgeLines){
            drawLine(at: width - 1)
            drawLine(at: 1)
          }
          
          for i in 0..<hourDividers { /* do something */
            let x = Double(i + 1) * widthPerDivider;
            drawLine(at: x, lineWidth: i == 0 ? 2 : 0.5, color: i == 0 ? UIColor.magenta.cgColor : UIColor.darkGray.cgColor)
          }
          
          if let imagePrevious = imagePrevious {
              imagePrevious.draw(in: CGRect(x: 0, y: 0, width: previousWidth, height: chartHeight))
          }
          
          if let imageFuture = imageFuture {
              imageFuture.draw(in: CGRect(x: previousWidth, y: 0, width: futureWidth, height: chartHeight))
          }
          
          
          let newImage:UIImage = UIGraphicsGetImageFromCurrentImageContext()!
          UIGraphicsEndImageContext()
          
          return newImage;
        }
      }
      
    }
    
    return nil;
  }
}
