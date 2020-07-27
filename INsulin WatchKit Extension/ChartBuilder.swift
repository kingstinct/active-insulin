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
  static func getChartImage(vals: Array<(Date, Double)>, now: Date = Date(), width: Double = Double(WKInterfaceDevice.current().screenBounds.width), chartHeight: Double = 100) -> UIImage{
    
    let max = vals.max { (arg0, arg1) -> Bool in
      return arg0.1 < arg1.1;
      }?.1
    let maxNumber = NSNumber(value: max! * 1.5);
    
    let futureVals = vals.filter({ (date, value) -> Bool in
      return date.timeIntervalSince(now) >= 0
    }).map({ $0.1 });
    
    let previousVals = vals.filter({ (date, value) -> Bool in
      return date.timeIntervalSince(now) < 0
    }).map({ $0.1 });
    
    let previousChart = YOLineChartImage();
    let valsAsNumbers = previousVals as [NSNumber];
    previousChart.values = valsAsNumbers;
    previousChart.fillColor = UIColor.magenta.withAlphaComponent(0.3)
    previousChart.maxValue = maxNumber;
    // chart.smooth = true
    previousChart.strokeColor = UIColor.magenta.withAlphaComponent(0.5)
    previousChart.strokeWidth = 2.0
    
    
    
    let futureChart = YOLineChartImage();
    let futureAsNumbers = futureVals as [NSNumber];
    futureChart.values = futureAsNumbers;
    futureChart.maxValue = maxNumber;
    futureChart.fillColor = UIColor.magenta.withAlphaComponent(0.6)
    // chart.smooth = true
    futureChart.strokeColor = UIColor.magenta
    futureChart.strokeWidth = 2.0
    // futureChart.smooth = true
    
    
    let previousWidth = width * Double(previousVals.count) / Double(vals.count);
    let futureWidth = width * Double(futureVals.count) / Double(vals.count);
    
    let screenScale = WKInterfaceDevice.current().screenScale
    
    let imagePrevious = previousChart.draw(CGRect(x: 0, y: 0, width: previousWidth, height: chartHeight), scale: screenScale)
    
    let imageFuture = futureChart.draw(CGRect(x: 0, y: 0, width: futureWidth, height: chartHeight), scale: screenScale)
    
    
    
    let size = CGSize(width: width, height: chartHeight)
    UIGraphicsBeginImageContextWithOptions(size, false, screenScale)
    
    let context = UIGraphicsGetCurrentContext();
    
    
    let hourDividers = Int(round(vals.last!.0.timeIntervalSince(vals.first!.0) / (60 * 60))) - 1;
    let widthPerDivider = (width / Double(hourDividers + 1))
    
    
    func drawLine(at: Double, lineWidth: CGFloat = 0.5, color: CGColor = UIColor.darkGray.cgColor) -> Void {
      context?.setLineWidth(lineWidth)
      context?.setStrokeColor(color);
      context?.move(to: CGPoint(x: at, y: 0))
      context?.addLine(to: CGPoint(x: at, y: chartHeight))
      context?.strokePath()
    }
    
    drawLine(at: width - 1)
    drawLine(at: 1)
    
    for i in 0..<hourDividers { /* do something */
      let x = Double(i + 1) * widthPerDivider;
      drawLine(at: x, lineWidth: i == 0 ? 2 : 0.5, color: i == 0 ? UIColor.magenta.cgColor : UIColor.darkGray.cgColor)
    }
    
    imagePrevious.draw(in: CGRect(x: 0, y: 0, width: previousWidth, height: chartHeight))
    imageFuture.draw(in: CGRect(x: previousWidth, y: 0, width: futureWidth, height: chartHeight))
    
    let newImage:UIImage = UIGraphicsGetImageFromCurrentImageContext()!
    UIGraphicsEndImageContext()
    
    return newImage;
  }
}
