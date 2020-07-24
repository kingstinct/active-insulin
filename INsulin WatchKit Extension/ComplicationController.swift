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
    
    func getCurrentTimelineEntry(for complication: CLKComplication, withHandler handler: @escaping (CLKComplicationTimelineEntry?) -> Void) {
        let healthStore = HKHealthStore()
        
        currentPromise = Calculations.fetchActiveInsulin(healthStore: healthStore).sink(receiveCompletion: { (errors) in
            
        }) { (val) in
            if(complication.family == .circularSmall){
                let provider = CLKSimpleTextProvider(text: "test");
                let complication = CLKComplicationTemplateCircularSmallSimpleText();
                complication.textProvider = provider;
                let entry = CLKComplicationTimelineEntry(date: Date(), complicationTemplate: complication)
                handler(entry);
            }
            
            else if(complication.family == .utilitarianSmall){
                let provider = CLKSimpleTextProvider(text: "test");
                let complication = CLKComplicationTemplateUtilitarianSmallRingText();
                complication.textProvider = provider;
                complication.ringStyle = .open
                complication.fillFraction = 0.5
                let entry = CLKComplicationTimelineEntry(date: Date(), complicationTemplate: complication)
                handler(entry);
            }
            
            else if(complication.family == .modularSmall){
                let provider = CLKSimpleTextProvider(text: "test");
                let complication = CLKComplicationTemplateModularSmallRingText();
                complication.textProvider = provider;
                complication.ringStyle = .open
                complication.fillFraction = 0.5
                let entry = CLKComplicationTimelineEntry(date: Date(), complicationTemplate: complication)
                handler(entry);
            }else if(complication.family == .graphicCircular){
                let complication = CLKComplicationTemplateGraphicCircularStackText();
                complication.line1TextProvider = CLKSimpleTextProvider(text: "IOB");
                complication.line2TextProvider = CLKSimpleTextProvider(text: val.format(f: "0.1"));
                let entry = CLKComplicationTimelineEntry(date: Date(), complicationTemplate: complication)
                handler(entry);
            } else {
                handler(nil)
            }
        }
        
    }
    
    func getTimelineEntries(for complication: CLKComplication, before date: Date, limit: Int, withHandler handler: @escaping ([CLKComplicationTimelineEntry]?) -> Void) {
        // Call the handler with the timeline entries prior to the given date
        handler(nil)
    }
    
    func getTimelineEntries(for complication: CLKComplication, after date: Date, limit: Int, withHandler handler: @escaping ([CLKComplicationTimelineEntry]?) -> Void) {
        // Call the handler with the timeline entries after to the given date
        handler(nil)
    }
    
    // MARK: - Placeholder Templates
    
    func getLocalizableSampleTemplate(for complication: CLKComplication, withHandler handler: @escaping (CLKComplicationTemplate?) -> Void) {
        // This method will be called once per supported complication, and the results will be cached
        if(complication.family == .circularSmall){
            let provider = CLKSimpleTextProvider(text: "test");
            let template = CLKComplicationTemplateCircularSmallSimpleText()
            template.textProvider = provider
            handler(template);
        }
        
        else if(complication.family == .utilitarianSmall){
            let provider = CLKSimpleTextProvider(text: "test");
            let template = CLKComplicationTemplateUtilitarianSmallRingText();
            template.textProvider = provider;
            template.ringStyle = .open
            template.fillFraction = 0.5
            handler(template);
        }
        
        else if(complication.family == .modularSmall){
            let provider = CLKSimpleTextProvider(text: "test");
            let complication = CLKComplicationTemplateModularSmallRingText();
            complication.textProvider = provider;
            complication.ringStyle = .open
            complication.fillFraction = 0.5
            
            handler(complication);
        } else {
            handler(nil)
        }
    }
    
}
