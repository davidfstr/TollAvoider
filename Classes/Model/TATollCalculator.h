//
//  TATollCalculator.h
//  TollAvoider
//
//  Created by David Foster on 11/30/11.
//  Copyright (c) 2011 Seabalt Solutions, LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TATollCalculator : NSObject

/**
 * Given a weekday (0 = Monday, 6 = Sunday) and an hour (14 = 2 PM),
 * returns a descriptor for the toll rates that apply during that hour.
 * 
 * When examining the rate result:
 *   rateDescriptor[1]: passPrice (in USD)
 *   rateDescriptor[2]: noPassPrice (in USD)
 */
+ (CGFloat *)rateForWeekday:(int)weekdayMon0 hour:(int)hour;

/**
 * Returns a descriptor for the toll rates that apply right now.
 * See [rateForWeekday:hour:] for the interpretation of the return value.
 */
+ (CGFloat *)rateForNow;

@end
