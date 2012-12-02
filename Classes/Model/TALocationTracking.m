//
//  TAUserLocationTracking.m
//  TollAvoider
//
//  Created by David Foster on 11/17/11.
//  Copyright (c) 2011 Seabalt Solutions, LLC. All rights reserved.
//

#import "TALocationTracking.h"
#import "TAAnalytics.h"


@interface TALocationTracking()
@property (nonatomic, readwrite) TALocationTrackingStatus status;
@property (nonatomic, readwrite, retain) CLLocation *lastUserLocation;
@end


@implementation TALocationTracking

@synthesize lastUserLocation;

#pragma mark - Init

+ (TALocationTracking *)instance {
    static TALocationTracking *instance = nil;
    if (!instance) {
        instance = [[TALocationTracking alloc] init];
    }
    return instance;
}

- (id)init {
    if (self = [super init]) {
        status = TALocationIdle;
    }
    return self;
}

- (void)initialize {
    self.status = TALocationIsolating;
    
    // Start determining current location.
    locationManager = [[CLLocationManager alloc] init];
    locationManager.delegate = self;
    // (within 10 m == 0.006 mi)
    locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters;
    locationManager.distanceFilter = kCLDistanceFilterNone;
    
    // If simulator, must simulate a location notification manually
#if TARGET_IPHONE_SIMULATOR
    // Seattle, WA: (47.606, -122.332)
    // Redmond, WA: (47.672, -122.119)
    CLLocation *toLocation = [[[CLLocation alloc] initWithLatitude:47.606
                                                         longitude:-122.332] autorelease];
    [self locationManager:locationManager
      didUpdateToLocation:toLocation
             fromLocation:nil];
#else
    [locationManager startUpdatingLocation];
#endif
}

#pragma mark - Properties

- (TALocationTrackingStatus)status {
    return status;
}

- (void)setStatus:(TALocationTrackingStatus)theStatus {
    if (status == theStatus) {
        return;
    }
    
    status = theStatus;
    [[NSNotificationCenter defaultCenter] postNotificationName:@"TALocationTrackingStatusDidChange" object:self];
}

- (CLLocation *)userLocation {
    return lastUserLocation;
}

#pragma mark - Operations

- (void)markLocationAsStale {
    lastUserLocationIsStale = YES;
}

#pragma mark - CLLocationManagerDelegate Methods

- (void)locationManager:(CLLocationManager *)manager
    didUpdateToLocation:(CLLocation *)newLocation
           fromLocation:(CLLocation *)oldLocation
{
    [TAAnalytics reportLocation:newLocation];
    
    if (oldLocation == nil || lastUserLocationIsStale) {
        NSLog(@"Initial location: lat=%lf, lng=%lf", newLocation.coordinate.latitude, newLocation.coordinate.longitude);
        
        [TAAnalytics reportEvent:@"UserLocationFound"
                           value:[TAAnalytics valueForCoordinate:newLocation.coordinate] name:@"UserLocation"];
    } else {
        NSLog(@"Updated location: lat=%lf, lng=%lf", newLocation.coordinate.latitude, newLocation.coordinate.longitude);
    }
    lastUserLocationIsStale = NO;
    
    self.lastUserLocation = newLocation;
    self.status = TALocationFound;
    [[NSNotificationCenter defaultCenter] postNotificationName:@"TAUserLocationDidChange" object:self];
}

- (void)locationManager:(CLLocationManager *)manager
       didFailWithError:(NSError *)error
{
    if (error.code == kCLErrorLocationUnknown) {
        // Unable to immediately determine location, but may still be able to determine after a delay.
        // Keep waiting.
        NSLog(@"Location currently unknown. Still waiting for location fix.");
    } else {
        if (error.code == kCLErrorDenied) {
            // User has denied this application access to location services.
            NSLog(@"*** Location access denied by user.");
            self.status = TALocationErrorDenied;
        } else {
            NSLog(@"*** Location isolation failed for unknown reason: %d", (int) error.code);
            self.status = TALocationErrorOther;
        }
        
        [TAAnalytics reportEvent:@"UserLocationError"
                           value:[NSString stringWithFormat:@"%d", (int) error.code] name:@"ErrorCode"];
    }
}

@end
