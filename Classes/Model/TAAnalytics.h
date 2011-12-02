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
/** Logs the user's presence at the specified location. */
+ (void)reportLocation:(CLLocation *)newLocation;
/** Reports a switch to the specified view controller. */
+ (void)reportSwitchToView:(UIViewController *)viewController;
/**
 * Manually reports a switch to a particular view ID.
 * Callers should use [reportSwitchToView:] in preference to this
 * method whenever possible.
 */
+ (void)reportSwitchToViewWithID:(NSString *)viewId;
/** Reports an individual event with the specified parameters. */
+ (void)reportEvent:(NSString *)eventId params:(NSDictionary *)params;
/** Reports an individual event with the specified parameter. */
+ (void)reportEvent:(NSString *)eventId value:(NSString *)value name:(NSString *)name;
/** Reports an individual event with no parameters. */
+ (void)reportEvent:(NSString *)eventId;

/** Reports the specified CLLocationCoordinate2D in standard analytics format. */
+ (NSString *)valueForCoordinate:(CLLocationCoordinate2D)location;

@end
