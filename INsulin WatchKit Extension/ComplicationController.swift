//
//  ComplicationController.swift
//  INsulin WatchKit Extension
//
//  Created by Robert Herber on 2020-07-24.
//  Copyright © 2020 Robert Herber. All rights reserved.
//
import HealthKit
import ClockKit
import Combine
import WatchKit
import SwiftUI

class ComplicationController: NSObject, CLKComplicationDataSource {
  var currentPromise: AnyCancellable?
  
  // MARK: - Timeline Configuration
  
  func getSupportedTimeTravelDirections(for complication: CLKComplication, withHandler handler: @escaping (CLKComplicationTimeTravelDirections) -> Void) {
    handler([.forward, .backward])
  }
  
  func getTimelineStartDate(for complication: CLKComplication, withHandler handler: @escaping (Date?) -> Void) {
    handler(nil)
  }
  
  func getTimelineEndDate(for complication: CLKComplication, withHandler handler: @escaping (Date?) -> Void) {
    handler(Date().addHours(addHours: 5))
  }
  
  func getPrivacyBehavior(for complication: CLKComplication, withHandler handler: @escaping (CLKComplicationPrivacyBehavior) -> Void) {
    handler(.showOnLockScreen)
  }
  
  // MARK: - Timeline Population
  
  enum DeviceSize {
    case mm38
    case mm40and42
    case mm44
  }
  
  func getImageForComplication(vals: [ChartPoint], now: Date = Date(), family: CLKComplicationFamily) -> UIImage? {
    let (width, height) = self.getImageSizeForComplication(family: family);
    return ChartBuilder.getChartImage(vals: vals, now: now, width: width, chartHeight: height, showEdgeLines: family != .graphicBezel)
  }
  
  let advancedFamilies = [
    CLKComplicationFamily.graphicBezel,
    CLKComplicationFamily.extraLarge,
    // CLKComplicationFamily.modularSmall,
    CLKComplicationFamily.graphicRectangular
  ]
  
  func getImageSizeForComplication(family: CLKComplicationFamily) -> (Double, Double){
    let deviceWidth = WKInterfaceDevice.current().screenBounds.width
    let deviceSize = deviceWidth == 136 ? DeviceSize.mm38
      : deviceWidth == 156 || deviceWidth == 162 ? DeviceSize.mm40and42
      : DeviceSize.mm44;
    
    if(family == .graphicRectangular){
      if(deviceSize == .mm40and42){
        return (150, 47)
      }
      else {
        return (171, 54);
      }
    }
    
    if(family == .graphicBezel || family == .graphicCircular){
      if(deviceSize == .mm40and42){
        return (42, 42)
      }
      else {
        return (47, 47);
      }
    }
    
    if(family == .extraLarge){ // stack image
      if(deviceSize == .mm38){
        return (78, 42);
      }
      if(deviceSize == .mm40and42){
        return (87, 45);
      }
      if(deviceSize == .mm44){
        return (96, 51);
      }
    }
    
    if(family == .modularSmall){ // stack image
      if(deviceSize == .mm38){
        return (26, 12);
      }
      if(deviceSize == .mm40and42){
        return (29, 15);
      }
      if(deviceSize == .mm44){
        return (32, 17);
      }
    }
    
    return (100, 100);
  }
  
  func combinedTextProviderSmall(iob: Double) -> CLKTextProvider{
    let iobStr = iob.format("0.1");
    let label = CLKSimpleTextProvider(text: LocalizedString("insulin_on_board_short"))
    label.tintColor = UIColor.gray
    
    let text = CLKSimpleTextProvider(text: iobStr)
    text.tintColor = UIColor.magenta
    
    let separator = " "
    
    let multi = CLKTextProvider(byJoining: [label, text], separator: separator)!
    return multi;
  }
  
  func combinedTextProvider(iob: Double) -> CLKTextProvider{
    let iobStr = iob.format("0.1");
    let label = CLKSimpleTextProvider(text: LocalizedString("insulin_on_board"))
    label.tintColor = UIColor.gray
    
    let text = CLKSimpleTextProvider(text: iobStr)
    text.tintColor = UIColor.magenta
    
    let separator = " "
    
    let multi = CLKTextProvider(byJoining: [label, text], separator: separator)!
    return multi;
  }
  
  func imageWithSize(size: CGSize, filledWithColor color: UIColor = UIColor.clear, scale: CGFloat = 0.0, opaque: Bool = false) -> UIImage {
    let rect = CGRect(x: 0, y: 0, width: size.width, height: size.height)
    
    UIGraphicsBeginImageContextWithOptions(size, opaque, scale)
    color.set()
    UIRectFill(rect)
    let image = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()
    
    return image!;
  }
  
  func getGraphicRectangular(iob: Double, image: UIImage) -> CLKComplicationTemplateGraphicRectangularLargeImage {
    let complication = CLKComplicationTemplateGraphicRectangularLargeImage();
    complication.imageProvider = getFullColorImage(image: image);
    complication.textProvider = combinedTextProvider(iob: iob);
    return complication
  }
  
  func getFullColorImage(image: UIImage) -> CLKFullColorImageProvider{
    let tintedImage = CLKImageProvider(onePieceImage: image, twoPieceImageBackground: imageWithSize(size: image.size, filledWithColor: UIColor.white.withAlphaComponent(0.1), scale: image.scale), twoPieceImageForeground: image);
    tintedImage.tintColor = .magenta;
    return CLKFullColorImageProvider(fullColorImage: image, tintedImageProvider: tintedImage);
  }
  
  func getGraphicBezel(iob: Double, image: UIImage) -> CLKComplicationTemplateGraphicBezelCircularText {
    let complication = CLKComplicationTemplateGraphicBezelCircularText();
    
    let circularProvider = CLKComplicationTemplateGraphicCircularImage();
    
    circularProvider.imageProvider = getFullColorImage(image: image);
    complication.circularTemplate = circularProvider;
    complication.textProvider = combinedTextProvider(iob: iob);
    return complication
  }
  
  func getModularSmall(iob: Double, image: UIImage) -> CLKComplicationTemplateModularSmallStackImage {
    let modularSmall = CLKComplicationTemplateModularSmallStackImage();
    modularSmall.line1ImageProvider = CLKImageProvider(onePieceImage: image);
    modularSmall.line2TextProvider = CLKSimpleTextProvider(text: iob.format("0.1"))

    return modularSmall;
  }
  
  func getExtraLarge(iob: Double, image: UIImage) -> CLKComplicationTemplateExtraLargeStackImage {
    let iobStr = iob.format("0.1");
    
    let text = CLKSimpleTextProvider(text: iobStr)
    text.tintColor = UIColor.magenta
    
    
    let extraLarge = CLKComplicationTemplateExtraLargeStackImage();
    extraLarge.line1ImageProvider = CLKImageProvider(onePieceImage: image);
    extraLarge.line2TextProvider = text;
    
    return extraLarge;
  }
  
  func getTemplateWithChart(for complication: CLKComplication, iob: Double, unfilteredVals: Array<ChartPoint>, now: Date = Date()) -> CLKComplicationTemplate? {
    let vals = unfilteredVals.filter { (point) -> Bool in
      if(complication.family == .graphicRectangular){
        return point.date >= now.addHours(addHours: -1) && point.date <= now.addHours(addHours: 5);
      }
      return point.date >= now.addHours(addHours: -1) && point.date <= now.addHours(addHours: 2);
    }
    
    if let image = getImageForComplication(vals: vals, now: now, family: complication.family) {
      if(complication.family == .graphicBezel){
        return self.getGraphicBezel(iob: iob, image: image)
      } else if (complication.family == .graphicRectangular){
        return self.getGraphicRectangular(iob: iob, image: image)
      } else if (complication.family == .modularSmall){
        return self.getModularSmall(iob: iob, image: image)
      } else if (complication.family == .extraLarge){
        return self.getExtraLarge(iob: iob, image: image)
      }
    }
    return getTemplateWithIOB(for: complication, iob: iob)
  }
  
  func getTemplateWithIOB(for complication: CLKComplication, iob: Double) -> CLKComplicationTemplate? {
    let iobStr = iob.format("0.1");
    
    let labelProvider = CLKSimpleTextProvider(text: LocalizedString("insulin_on_board"));
    labelProvider.shortText = LocalizedString("insulin_on_board_short")
    let valueTextProvider = CLKSimpleTextProvider(text: iobStr);
    valueTextProvider.tintColor = UIColor.magenta
    
    if(complication.family == .circularSmall){
      let complication = CLKComplicationTemplateCircularSmallStackText();
      complication.line1TextProvider = labelProvider;
      complication.line2TextProvider = valueTextProvider;
      return complication
    }else if(complication.family == .utilitarianSmall){
      let complication = CLKComplicationTemplateUtilitarianSmallFlat();
      complication.textProvider = valueTextProvider;
      return complication
    } else if(complication.family == .modularSmall){
      let complication = CLKComplicationTemplateModularSmallStackText();
      complication.line1TextProvider = labelProvider;
      complication.line2TextProvider = valueTextProvider;
      complication.highlightLine2 = true;
      return complication
    } else if(complication.family == .graphicCircular){
      let complication = CLKComplicationTemplateGraphicCircularStackText();
      complication.line1TextProvider = labelProvider
      complication.line2TextProvider = valueTextProvider
      return complication
    } else if(complication.family == .extraLarge) {
      let complication = CLKComplicationTemplateExtraLargeSimpleText();
      complication.textProvider = valueTextProvider;
      return complication
    } else if (complication.family == .graphicBezel){
      let complication = CLKComplicationTemplateGraphicBezelCircularText();
      
      let circularComplication = CLKComplicationTemplateGraphicCircularStackText();
      circularComplication.line1TextProvider = labelProvider
      circularComplication.line2TextProvider = valueTextProvider
      
      complication.circularTemplate = circularComplication
      
      return complication;
    } else if (complication.family == .graphicCircular){
      let complication = CLKComplicationTemplateGraphicCircularStackText();
      complication.line1TextProvider = labelProvider;
      complication.line2TextProvider = valueTextProvider;
      return complication;
    }else if (complication.family == .graphicCorner){
      let complication = CLKComplicationTemplateGraphicCornerStackText();
      complication.outerTextProvider = valueTextProvider;
      complication.innerTextProvider = labelProvider;
      return complication;
    }else if (complication.family == .graphicRectangular){
      let complication = CLKComplicationTemplateGraphicRectangularStandardBody();
      complication.headerTextProvider = labelProvider
      complication.body1TextProvider = valueTextProvider;
      return complication;
    }else if (complication.family == .modularLarge){
      let complication = CLKComplicationTemplateModularLargeStandardBody();
      complication.headerTextProvider = labelProvider;
      complication.body1TextProvider = valueTextProvider;
      return complication;
    } else if (complication.family == .utilitarianLarge){
      let complication = CLKComplicationTemplateUtilitarianLargeFlat();
      complication.textProvider = combinedTextProviderSmall(iob: iob);
      return complication;
    } else if (complication.family == .utilitarianSmallFlat){
      let complication = CLKComplicationTemplateUtilitarianSmallFlat();
      complication.textProvider = valueTextProvider;
      return complication;
    }
    return nil;
  }
  
  func getCurrentTimelineEntry(for complication: CLKComplication, withHandler handler: @escaping (CLKComplicationTimelineEntry?) -> Void) {
    
    Health.current.fetchIOB { (error, value) in
      if let iob = value {
        if(self.advancedFamilies.contains(complication.family)){
          
          Health.current.fetchActiveInsulinChart(from: Date().addHours(addHours: -1), to: Date().addHours(addHours: 5)) { (error, data) in
            if let template = self.getTemplateWithChart(for: complication, iob: iob, unfilteredVals: data) {
              let entry = CLKComplicationTimelineEntry(date: Date(), complicationTemplate: template)
              handler(entry);
            }
            else {
              handler(nil);
            }
          }
        }
        else {
          if let template = self.getTemplateWithIOB(for: complication, iob: iob) {
            let entry = CLKComplicationTimelineEntry(date: Date(), complicationTemplate: template)
            
            return handler(entry);
          }
          
          handler(nil)
        }
      }
    }
  }
  
  func getTimelineEntries(for complication: CLKComplication, before date: Date, limit: Int, withHandler handler: @escaping ([CLKComplicationTimelineEntry]?) -> Void) {
    // Call the handler with the timeline entries prior to the given date
    handler(nil)
  }
  
  func getTimelineEntries(for complication: CLKComplication, after date: Date, limit: Int, withHandler handler: @escaping ([CLKComplicationTimelineEntry]?) -> Void) {
    // Call the handler with the timeline entries after to the given date
    
    Health.current.fetchTimelineIOB(from: date, limit: limit) { (error, _results) in
      if let results = _results {
        
        if(self.advancedFamilies.contains(complication.family)){
          Health.current.fetchActiveInsulinChart(from: date.addHours(addHours: -1), to: date.addHours(addHours: 11)) { (error, data) in
            let timelineEntries = results.map { (time, iob) -> CLKComplicationTimelineEntry? in
              if let template = self.getTemplateWithChart(for: complication, iob: iob, unfilteredVals: data, now: time) {
                let entry = CLKComplicationTimelineEntry(date: time, complicationTemplate: template)
                return entry;
              }
              return nil;
            }
            
            if let entries = timelineEntries as? [CLKComplicationTimelineEntry] {
              handler(entries);
            } else {
              handler(nil);
            }
          }
        } else {
          let timelineEntries = results.map { (time, iob) -> CLKComplicationTimelineEntry? in
            if let template = self.getTemplateWithIOB(for: complication, iob: iob) {
              return CLKComplicationTimelineEntry(date: time, complicationTemplate: template);
            }
            
            return nil;
            
          }
          if let entries = timelineEntries as? [CLKComplicationTimelineEntry] {
            handler(entries);
          } else {
            handler(nil);
          }
        }
        
      }
      
      
    }
  }
  
  // MARK: - Placeholder Templates
  
  func getLocalizableSampleTemplate(for complication: CLKComplication, withHandler handler: @escaping (CLKComplicationTemplate?) -> Void) {
    // This method will be called once per supported complication, and the results will be cached
    var template: CLKComplicationTemplate?;
    
    if(self.advancedFamilies.contains(complication.family)){
      var injections = Array<Injection>();
      injections.append(Injection(date: Date(), insulinUnits: 5))
      
      let data = Health.current.buildChartData(injections: injections,
                                               from: Date().addHours(addHours: -1),
                                               to: Date().addHours(addHours: 5),
                                               minuteResolution: 2);
      
      template = self.getTemplateWithChart(
        for: complication,
        iob: 5,
        unfilteredVals: data
      )
    }
    
    
    if(template == nil){
      template = self.getTemplateWithIOB(for: complication, iob: 5)
    }
    
    handler(template);
  }
  
}



