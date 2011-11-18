//
//  TAUserLocationTracking.m
//  TollAvoider
//
//  Created by David Foster on 11/17/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "TALocationTracking.h"


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
    [locationManager startUpdatingLocation];
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

#pragma mark - CLLocationManagerDelegate Methods

- (void)locationManager:(CLLocationManager *)manager
    didUpdateToLocation:(CLLocation *)newLocation
           fromLocation:(CLLocation *)oldLocation
{
    if (oldLocation == nil) {
        NSLog(@"Initial location: lat=%lf, lng=%lf", newLocation.coordinate.latitude, newLocation.coordinate.longitude);
    } else {
        NSLog(@"Updated location: lat=%lf, lng=%lf", newLocation.coordinate.latitude, newLocation.coordinate.longitude);
    }
    
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
    } else if (error.code == kCLErrorDenied) {
        // User has denied this application access to location services.
        NSLog(@"*** Location access denied by user.");
        self.status = TALocationErrorDenied;
    } else {
        NSLog(@"*** Location isolation failed for unknown reason: %d", (int) error.code);
        self.status = TALocationErrorOther;
    }
}

@end
