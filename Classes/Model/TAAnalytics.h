//
//  TAAnalytics.h
//  TollAvoider
//
//  Created by David Foster on 12/1/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TAAnalytics : NSObject

/** Whether analytics reporting to the backend is enabled. */
+ (BOOL)enabled;

/** Initializes analytics. Should be invoked once at app startup. */
+ (void)initializeAnalytics;
/** Reports an individual event. */
+ (void)reportEvent:(NSString *)eventId params:(NSDictionary *)params;
+ (void)reportEvent:(NSString *)eventId value:(NSString *)value name:(NSString *)name;

@end
