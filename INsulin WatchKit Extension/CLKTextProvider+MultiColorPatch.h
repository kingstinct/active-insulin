//
//  CLKTextProvider+MultiColorPatch.h
//  INsulin
//
//  Created by Robert Herber on 2020-07-27.
//  Copyright © 2020 Robert Herber. All rights reserved.
//

#ifndef CLKTextProvider_MultiColorPatch_h
#define CLKTextProvider_MultiColorPatch_h

#import <ClockKit/ClockKit.h>

@interface CLKTextProvider (MultiColorPatch)

+ (CLKTextProvider *)textProviderByJoiningTextProviders: (NSArray<CLKTextProvider *> *)textProviders separator:(NSString * _Nullable) separator;

@end


#endif /* CLKTextProvider_MultiColorPatch_h */
