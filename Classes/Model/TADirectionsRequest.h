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

@interface TADirectionsRequest : NSObject <PPURLRequestDelegate> {
    CLLocationCoordinate2D source;
    BOOL usesWaypoint;
    CLLocationCoordinate2D waypoint;
    CLLocationCoordinate2D destination;
    
    TADirectionsRequestStatus status;
    NSArray *routes;
}

/**
 * Status of this request.
 * Changes to this property will be announced with a TADirectionsRequestStatusDidChange notification.
 */
@property (nonatomic, readonly) TADirectionsRequestStatus status;
/**
 * List of routes found. Only valid in the TADirectionsOK state.
 */
@property (nonatomic, readonly, retain) NSArray *routes;

- (id)initWithSource:(CLLocationCoordinate2D)theSource
         destination:(CLLocationCoordinate2D)theDestination;

- (id)initWithSource:(CLLocationCoordinate2D)theSource
            waypoint:(CLLocationCoordinate2D)theWaypoint
         destination:(CLLocationCoordinate2D)theDestination;

- (void)startAsynchronous;

@end
