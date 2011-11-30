//
//  TADirectionsRequest.h
//  TollAvoider
//
//  Created by David Foster on 11/28/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PPURLRequestDelegate.h"
#import "TADirectionsRequestStatus.h"

@class TADirectionsRoute;

@interface TADirectionsRequest : NSObject <PPURLRequestDelegate> {
    CLLocationCoordinate2D source;
    BOOL usesWaypoint;
    NSString *waypointName;
    CLLocationCoordinate2D destination;
    BOOL alternatives;
    
    TADirectionsRequestStatus status;
    NSArray *routes;
}

/** Whether to search for multiple routes, instead of just the best one. Default is NO. */
@property (nonatomic, readwrite) BOOL alternatives;

/**
 * Status of this request.
 * Changes to this property will be announced with a TADirectionsRequestStatusDidChange notification.
 */
@property (nonatomic, readonly) TADirectionsRequestStatus status;
/**
 * List of routes found. Only valid in the TADirectionsOK state.
 */
@property (nonatomic, readonly, retain) NSArray *routes;
/**
 * The first non-bridge route result, or nil if no such route.
 */
@property (nonatomic, readonly) TADirectionsRoute *firstNonbridgeRoute;

- (id)initWithSource:(CLLocationCoordinate2D)theSource
         destination:(CLLocationCoordinate2D)theDestination;

- (id)initWithSource:(CLLocationCoordinate2D)theSource
            waypoint:(CLLocationCoordinate2D)theWaypoint
         destination:(CLLocationCoordinate2D)theDestination;

// This is the designated initializer.
- (id)initWithSource:(CLLocationCoordinate2D)theSource
        waypointName:(NSString *)theWaypointName
         destination:(CLLocationCoordinate2D)theDestination;

- (void)startAsynchronous;

@end
