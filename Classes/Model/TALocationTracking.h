//
//  TAUserLocationTracking.h
//  TollAvoider
//
//  Created by David Foster on 11/17/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TALocationTrackingStatus.h"

@interface TALocationTracking : NSObject <CLLocationManagerDelegate> {
    TALocationTrackingStatus status;
    
    CLLocationManager *locationManager;
    CLLocation *lastUserLocation;
    BOOL lastUserLocationIsStale;
}

/** The status of the search for the user's location. */
@property (nonatomic, readonly) TALocationTrackingStatus status;
/**
 * The current location of the user, or nil if unknown.
 * Changes over time.
 * 
 * Changes to this property announced by the @"TAUserLocationDidChange" notification.
 */
@property (nonatomic, readonly, retain) CLLocation *userLocation;

+ (TALocationTracking *)instance;
- (void)initialize;

/** Marks the current user location as stale, such as when the app is foregrounded. */
- (void)markLocationAsStale;

@end
