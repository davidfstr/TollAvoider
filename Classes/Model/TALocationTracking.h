//
//  TAUserLocationTracking.h
//  TollAvoider
//
//  Created by David Foster on 11/17/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TALocationTracking : NSObject <CLLocationManagerDelegate> {
    CLLocationManager *locationManager;
    CLLocation *lastUserLocation;
}

/**
 * The current location of the user, or nil if unknown.
 * Changes over time.
 * 
 * Changes to this property announced by the @"TAUserLocationDidChange" notification.
 */
@property (nonatomic, readonly, retain) CLLocation *userLocation;

+ (TALocationTracking *)instance;
- (void)initialize;

@end
