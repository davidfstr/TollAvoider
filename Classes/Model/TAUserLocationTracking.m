//
//  TAUserLocationTracking.m
//  TollAvoider
//
//  Created by David Foster on 11/17/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "TAUserLocationTracking.h"


@interface TAUserLocationTracking()
@property (nonatomic, readwrite, retain) CLLocation *lastUserLocation;
@end


@implementation TAUserLocationTracking

@synthesize lastUserLocation;

#pragma mark - Init

+ (TAUserLocationTracking *)instance {
    static TAUserLocationTracking *instance = nil;
    if (!instance) {
        instance = [[TAUserLocationTracking alloc] init];
    }
    return instance;
}

- (void)initialize {
    // Start determining current location.
    locationManager = [[CLLocationManager alloc] init];
    locationManager.delegate = self;
    // (within 10 m == 0.006 mi)
    locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters;
    locationManager.distanceFilter = kCLDistanceFilterNone;
    [locationManager startUpdatingLocation];
}

#pragma mark - Properties

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
    } else {
        NSLog(@"*** Location isolation failed for unknown reason: %d", (int) error.code);
    }
}

@end
