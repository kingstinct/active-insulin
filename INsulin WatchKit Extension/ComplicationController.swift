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
    handler(Date().addingTimeInterval(TimeInterval(60 * 60 * 5)))
  }
  
  func getPrivacyBehavior(for complication: CLKComplication, withHandler handler: @escaping (CLKComplicationPrivacyBehavior) -> Void) {
    handler(.showOnLockScreen)
  }
  
  // MARK: - Timeline Population
  
  func getGraphicRectangular(for complication: CLKComplication, iob: Double, image: UIImage) -> CLKComplicationTemplateGraphicRectangularLargeImage {
    let iobStr = iob.format(f: "0.1");
    // let valueTextProvider = CLKSimpleTextProvider(text: NSLocalizedString("app_name", comment: "Active Insulin") + " - " + iobStr);
    
    let label = CLKSimpleTextProvider(text: NSLocalizedString("insulin_on_board", comment: "Active Insulin"))
    label.tintColor = UIColor.gray

    let text = CLKSimpleTextProvider(text: iobStr)
    text.tintColor = UIColor.magenta
    
    let separator = " "
    
    let multi = CLKTextProvider(byJoining: [label, text], separator: separator)!
    
    
    let complication = CLKComplicationTemplateGraphicRectangularLargeImage();
    complication.imageProvider = CLKFullColorImageProvider(fullColorImage: image);
    complication.textProvider = multi;
    return complication
  }
  
  func getTemplateWithIOB(for complication: CLKComplication, iob: Double) -> CLKComplicationTemplate? {
    let iobStr = iob.format(f: "0.1");
    
    let labelProvider = CLKSimpleTextProvider(text: NSLocalizedString("insulin_on_board", comment: "Insulin on board"));
    labelProvider.shortText = NSLocalizedString("insulin_on_board_short", comment: "Insulin on board")
    let valueTextProvider = CLKSimpleTextProvider(text: iobStr);
    valueTextProvider.tintColor = UIColor.magenta
    
    if(complication.family == .circularSmall){
      let complication = CLKComplicationTemplateCircularSmallSimpleText();
      complication.textProvider = valueTextProvider;
      return complication
    }else if(complication.family == .utilitarianSmall){
      let complication = CLKComplicationTemplateUtilitarianSmallFlat();
      complication.textProvider = valueTextProvider;
      return complication
    } else if(complication.family == .modularSmall){
      let complication = CLKComplicationTemplateModularSmallSimpleText();
      complication.textProvider = valueTextProvider;
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
      complication.textProvider = valueTextProvider;
      return complication;
    } else if (complication.family == .utilitarianSmallFlat){
      let complication = CLKComplicationTemplateUtilitarianSmallFlat();
      complication.textProvider = valueTextProvider;
      return complication;
    }
    return nil;
  }
  
  func getCurrentTimelineEntry(for complication: CLKComplication, withHandler handler: @escaping (CLKComplicationTimelineEntry?) -> Void) {
    
    Calculations.fetchActiveInsulin { (error, value) in
      if let iob = value {
        if(complication.family == .graphicRectangular){
          self.currentPromise = Calculations.fetchActiveInsulinChart(from: Date().addingTimeInterval(TimeInterval(-60 * 60)), to: Date().addingTimeInterval(TimeInterval(5 * 60 * 60))).sink(receiveCompletion: { (completion) in
            switch completion {
            case let .failure(error):
              handler(nil);
              print(error)
            case .finished: break
            }
          }) { (vals) in
            let image = Calculations.getChartImage(vals: vals, width: 171, chartHeight: 54);
            let template = self.getGraphicRectangular(for: complication, iob: iob, image: image);
            
            let entry = CLKComplicationTimelineEntry(date: Date(), complicationTemplate: template)
            handler(entry);
          }
        }
        else {
          if let template = self.getTemplateWithIOB(for: complication, iob: iob) {
            let entry = CLKComplicationTimelineEntry(date: Date(), complicationTemplate: template)
            handler(entry);
          } else  {
            handler(nil)
          }
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
    
    Calculations.fetchActiveInsulinTimeline(from: date, to: date.addingTimeInterval(TimeInterval(5 * 60 * 60))) { (error, _results) in
      var timelineEntries = Array<CLKComplicationTimelineEntry?>();
      if let results = _results {
        
        if(complication.family == .graphicRectangular){
          self.currentPromise = Calculations.fetchActiveInsulinChart(from: date.addingTimeInterval(TimeInterval(-60 * 60)), to: date.addingTimeInterval(TimeInterval(11 * 60 * 60))).sink(receiveCompletion: { (errors) in
            
          }) { (vals) in
            timelineEntries = results.suffix(limit).map { (time, iob) -> CLKComplicationTimelineEntry? in
              let chartFrom = time.addingTimeInterval(TimeInterval(-60 * 60))
              let chartTo = time.addingTimeInterval(TimeInterval(5 * 60 * 60))
              let valsForChart = vals.filter { (hey) -> Bool in
                return hey.0 >= chartFrom && hey.0 <= chartTo;
              }
              
              let image = WKInterfaceDevice.current().screenBounds.width > 162
                ? Calculations.getChartImage(vals: valsForChart,now: time, width: 171, chartHeight: 54)
                : Calculations.getChartImage(vals: valsForChart,now: time, width: 150, chartHeight: 47);
              let template = self.getGraphicRectangular(for: complication, iob: iob, image: image);
              return CLKComplicationTimelineEntry(date: time, complicationTemplate: template);
            }
            
            
          }
        } else {
          timelineEntries = results.suffix(limit).map { (time, iob) -> CLKComplicationTimelineEntry? in
            if let template = self.getTemplateWithIOB(for: complication, iob: iob) {
              return CLKComplicationTimelineEntry(date: time, complicationTemplate: template);
            }
            else {
              return nil;
            }
          }
          
        }
        
      }
      
      if let entries = timelineEntries as? [CLKComplicationTimelineEntry] {
        handler(entries);
      } else {
        handler(nil);
      }
    }
  }
  
  // MARK: - Placeholder Templates
  
  func getLocalizableSampleTemplate(for complication: CLKComplication, withHandler handler: @escaping (CLKComplicationTemplate?) -> Void) {
    // This method will be called once per supported complication, and the results will be cached
    
    let image = Calculations.getChartImage(vals: Array<(Date, Double)>([
      (Date().addingTimeInterval(TimeInterval(-60 * 60)), 0),
      (Date(), 0),
      (Date().addingTimeInterval(TimeInterval(60 * 60)), 10),
      (Date().addingTimeInterval(TimeInterval(2 * 60 * 60)), 5),
      (Date().addingTimeInterval(TimeInterval(3 * 60 * 60)), 4),
      (Date().addingTimeInterval(TimeInterval(4 * 60 * 60)), 3),
      (Date().addingTimeInterval(TimeInterval(5 * 60 * 60)), 2),
    ]))
    let template = (complication.family == .graphicRectangular)
      ? self.getGraphicRectangular(for: complication, iob: 4.5, image: image)
      : self.getTemplateWithIOB(for: complication, iob: 4.5);
    handler(template);
  }
  
}


