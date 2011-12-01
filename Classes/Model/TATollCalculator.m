//
//  TATollCalculator.m
//  TollAvoider
//
//  Created by David Foster on 11/30/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "TATollCalculator.h"

@implementation TATollCalculator

/*
 * Rates taken from:
 *   http://www.wsdot.wa.gov/Tolling/TollRates.htm
 * Last Updated:
 *   2011-11-30
 */

// (hourBegins, passPrice, noPassPrice)
CGFloat weekdayRates[] = {
     0,    0,    0,
     5, 1.60, 3.10,
     6, 2.80, 4.30,
     7, 3.50, 5.00,
     9, 2.80, 4.30,
    10, 2.25, 3.75,
    14, 2.80, 4.30,
    15, 3.50, 5.00,
    18, 2.80, 4.30,
    19, 2.25, 3.75,
    21, 1.60, 3.10,
    23,    0,    0,
    -1,   -1,   -1
};

// (hourBegins, passPrice, noPassPrice)
CGFloat weekendRates[] = {
     0,    0,    0,
     5, 1.10, 2.60,
     8, 1.65, 3.15,
    11, 2.20, 3.70,
    18, 1.65, 3.15,
    21, 1.10, 2.60,
    23,    0,    0,
    -1,   -1,   -1
};

+ (CGFloat *)rateForWeekday:(int)weekdayMon0 hour:(int)hour {
    CGFloat *rates;
    if ((0 <= weekdayMon0) && (weekdayMon0 <= 4)) {
        rates = weekdayRates;
    } else {
        rates = weekendRates;
    }
    
    CGFloat *lastRate = NULL;
    for (CGFloat *rate = rates; *rate != -1; rate += 3) {
        CGFloat hourBegins = rate[0];
        if (hourBegins > hour) {
            break;
        }
        lastRate = rate;
    }
    return lastRate;
}

+ (CGFloat *)rateForNow {
    NSDate *now = [NSDate date];
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDateComponents *components = [calendar components:NSHourCalendarUnit | NSWeekdayCalendarUnit
                                               fromDate:now];
    int hour = components.hour;
    int weekdaySun1 = components.weekday;       // 1 = Sunday, 7 = Saturday
    int weekdayMon0 = (weekdaySun1 + 5) % 7;    // 0 = Monday, 6 = Sunday
    
    return [TATollCalculator rateForWeekday:weekdayMon0 hour:hour];
}

@end
