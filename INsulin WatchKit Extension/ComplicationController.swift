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
    handler(Date().addHours(addHours: 5))
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
    
    Health.current.fetchIOB { (error, value) in
      if let iob = value {
        if(complication.family == .graphicRectangular){
          self.currentPromise = Health.current.fetchActiveInsulinChart(from: Date().addHours(addHours: -1), to: Date().addHours(addHours: 5)).sink(receiveCompletion: { (completion) in
            switch completion {
            case let .failure(error):
              handler(nil);
              print(error)
            case .finished: break
            }
          }) { (vals) in
            let image = ChartBuilder.getChartImage(vals: vals, width: 171, chartHeight: 54);
            if let template = image != nil
              ? self.getGraphicRectangular(for: complication, iob: iob, image: image!)
              : self.getTemplateWithIOB(for: complication, iob: iob) {
              let entry = CLKComplicationTimelineEntry(date: Date(), complicationTemplate: template)
              handler(entry);
            } else {
              handler(nil)
            }
            
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
    
    Health.current.fetchTimelineIOB(from: date, limit: limit) { (error, _results) in
      var timelineEntries = Array<CLKComplicationTimelineEntry?>();
      if let results = _results {
        
        if(complication.family == .graphicRectangular){
          self.currentPromise = Health.current.fetchActiveInsulinChart(from: date.addHours(addHours: -1), to: date.addHours(addHours: 11)).sink(receiveCompletion: { (errors) in
            
          }) { (vals) in
            timelineEntries = results.map { (time, iob) -> CLKComplicationTimelineEntry? in
              let chartFrom = time.addHours(addHours: -1)
              let chartTo = time.addHours(addHours: 5)
              let valsForChart = vals.filter { chartPoint -> Bool in
                return chartPoint.date >= chartFrom && chartPoint.date <= chartTo;
              }
              
              let image = WKInterfaceDevice.current().screenBounds.width > 162
                ? ChartBuilder.getChartImage(vals: valsForChart,now: time, width: 171, chartHeight: 54)
                : ChartBuilder.getChartImage(vals: valsForChart,now: time, width: 150, chartHeight: 47);
              if let template = image != nil
                ? self.getGraphicRectangular(for: complication, iob: iob, image: image!)
                : self.getTemplateWithIOB(for: complication, iob: iob) {
                return CLKComplicationTimelineEntry(date: time, complicationTemplate: template);
              }
              else {
                return nil;
              }
              
            }
            
            
          }
        } else {
          timelineEntries = results.map { (time, iob) -> CLKComplicationTimelineEntry? in
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
    var template: CLKComplicationTemplate?;
    
    if(complication.family == .graphicRectangular){
      
      
      var injections = Array<(Date, Double)>();
      injections.append((Date(), 5));
      
      let data = Health.current.buildChartData(injections: injections,
                                               from: Date().addHours(addHours: -1),
                                               to: Date().addHours(addHours: 5),
                                               minuteResolution: 2);
      
      if let image = ChartBuilder.getChartImage(vals: data){
        template = self.getGraphicRectangular(for: complication, iob: 4.5, image: image);
      }
    }
    
    if(template == nil){
      template = self.getTemplateWithIOB(for: complication, iob: 4.5)
    }
    
    handler(template);
  }
  
}



