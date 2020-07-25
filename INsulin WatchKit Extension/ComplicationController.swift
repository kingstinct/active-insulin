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
        handler(nil)
    }
    
    func getPrivacyBehavior(for complication: CLKComplication, withHandler handler: @escaping (CLKComplicationPrivacyBehavior) -> Void) {
        handler(.showOnLockScreen)
    }
    
    // MARK: - Timeline Population
    
    func getTemplateWithIOB(for complication: CLKComplication, iob: Double) -> CLKComplicationTemplate? {
        let iobStr = iob.format(f: "0.1");
        let labelProvider = CLKSimpleTextProvider(text: "Insulin on Board");
        labelProvider.shortText = "IOB"
        let valueTextProvider = CLKSimpleTextProvider(text: iobStr);
        
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
        let healthStore = HKHealthStore()
        
        currentPromise = Calculations.fetchActiveInsulin(healthStore: healthStore).sink(receiveCompletion: { (errors) in
            
        }) { (val) in
            if let template = self.getTemplateWithIOB(for: complication, iob: val) {
                let entry = CLKComplicationTimelineEntry(date: Date(), complicationTemplate: template)
                handler(entry);
            } else  {
                handler(nil)
            }
        }
        
    }
    
    func getTimelineEntries(for complication: CLKComplication, before date: Date, limit: Int, withHandler handler: @escaping ([CLKComplicationTimelineEntry]?) -> Void) {
        // Call the handler with the timeline entries prior to the given date
        handler(nil)
    }
    
    func getTimelineEntries(for complication: CLKComplication, after date: Date, limit: Int, withHandler handler: @escaping ([CLKComplicationTimelineEntry]?) -> Void) {
        let healthStore = HKHealthStore()
        // Call the handler with the timeline entries after to the given date
        currentPromise = Calculations.fetchActiveInsulinTimeline(healthStore: healthStore, forTime: date).sink(receiveCompletion: { (error) in
            
        }, receiveValue: { (results) in
            let timelineEntries = results.map { (time, iob) -> CLKComplicationTimelineEntry? in
                if let template = self.getTemplateWithIOB(for: complication, iob: iob) {
                    return CLKComplicationTimelineEntry(date: time, complicationTemplate: template);
                }
                else {
                    return nil;
                }
            }
            
            if let entries = timelineEntries as? [CLKComplicationTimelineEntry] {
                handler(entries);
            } else {
                handler(nil);
            }
        })
    }
    
    // MARK: - Placeholder Templates
    
    func getLocalizableSampleTemplate(for complication: CLKComplication, withHandler handler: @escaping (CLKComplicationTemplate?) -> Void) {
        // This method will be called once per supported complication, and the results will be cached
            
        let template = self.getTemplateWithIOB(for: complication, iob: 4.5);
        handler(template);
    }
    
}
